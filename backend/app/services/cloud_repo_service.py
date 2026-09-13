"""Cloud runtime: GitHub repositories cloned and executed on the server itself.

In desktop mode the backend runs on the developer's laptop and tasks operate on
repositories that already live on disk (registered by the device agent). In
cloud mode there is no laptop: this service clones GitHub repositories under
WORKSPACES_ROOT and registers the server as a synthetic "Phodex Cloud" device,
so the existing task, approval, and commit-and-push flows work unchanged. The
worker engines and GitService call back into it for three things:

- `prepare_for_task`: fetch/fast-forward (or re-clone a lost workspace) before
  a task runs;
- `resolve_git_env`: the environment (credential helper + commit identity)
  needed to push from a cloud workspace;
- `reset_workspace`: drop uncommitted changes when the user discards them,
  since in the cloud nobody can inspect the tree by hand.
"""

import os
import re
from dataclasses import dataclass
from pathlib import Path
from uuid import UUID

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.models.device import Device
from app.models.synced_repository import SyncedRepository
from app.models.user import User
from app.repositories.device_repo import DeviceRepository
from app.repositories.repo_repo import RepoRepository
from app.services.exceptions import ConflictError, ForbiddenError
from app.services.user_ai_settings_service import UserAiSettingsService
from app.utils.datetime import utcnow
from workers.common.subprocess_io import ManagedSubprocess

logger = structlog.get_logger(__name__)

CLOUD_PLATFORM = "cloud"
GITHUB_SOURCE = "github"
RUNNER_AGENT_VERSION = "cloud-0.1.0"
GIT_TOKEN_ENV = "PHODEX_GIT_TOKEN"

_GITHUB_URL = re.compile(
    r"^(?:https?://)?(?:www\.)?github\.com/(?P<owner>[\w.-]+)/(?P<repo>[\w.-]+?)(?:\.git)?/?$"
)
_SHORT_REF = re.compile(r"^(?P<owner>[\w.-]+)/(?P<repo>[\w.-]+?)(?:\.git)?$")

# Inline git credential helper fed through GIT_CONFIG_* environment variables,
# so the token never appears in a remote URL (which would otherwise leak into
# streamed `git push` stderr and the task event log).
_CREDENTIAL_HELPER = (
    '!f() { echo "username=x-access-token"; echo "password=${' + GIT_TOKEN_ENV + '}"; }; f'
)


@dataclass(frozen=True)
class RepoSource:
    url: str
    owner: str
    name: str


def parse_repo_source(raw: str, *, allow_local: bool = False) -> RepoSource:
    """Normalizes user input into a clone URL.

    Accepts `https://github.com/owner/repo`, `github.com/owner/repo`, a bare
    `owner/repo`, optional `.git` suffix, and (tests/dev only) a local path.
    """
    value = raw.strip()
    if not value:
        raise ValueError("Enter a GitHub repository URL like https://github.com/owner/repo")

    match = _GITHUB_URL.match(value)
    if match is None and "://" not in value and not value.startswith(("/", ".", "~")):
        match = _SHORT_REF.match(value)
    if match is not None:
        owner, name = match.group("owner"), match.group("repo")
        return RepoSource(url=f"https://github.com/{owner}/{name}.git", owner=owner, name=name)

    if allow_local:
        path = Path(value.removeprefix("file://")).expanduser()
        if path.exists():
            resolved = path.resolve()
            return RepoSource(
                url=str(resolved), owner="local", name=resolved.name.removesuffix(".git")
            )

    raise ValueError("Enter a GitHub repository URL like https://github.com/owner/repo")


def scrub_secrets(line: str, secrets: list[str]) -> str:
    for secret in secrets:
        if secret:
            line = line.replace(secret, "***")
    return line


class GitCommandFailedError(Exception):
    pass


class CloudRepoService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        settings: Settings,
        repo_repo: RepoRepository,
        device_repo: DeviceRepository,
        user_ai_settings_service: UserAiSettingsService,
    ) -> None:
        self._session_factory = session_factory
        self._settings = settings
        self._repo_repo = repo_repo
        self._device_repo = device_repo
        self._user_ai_settings_service = user_ai_settings_service

    # ------------------------------------------------------------------ runner

    async def ensure_runner_device(self, user_id: UUID) -> Device:
        """The synthetic device representing this server for the given user."""
        async with self._session_factory() as session:
            device = await session.scalar(
                select(Device).where(Device.user_id == user_id, Device.platform == CLOUD_PLATFORM)
            )
            if device is None:
                device = Device(
                    user_id=user_id,
                    name=self._settings.cloud_runner_name,
                    platform=CLOUD_PLATFORM,
                    status="online",
                    agent_version=RUNNER_AGENT_VERSION,
                    last_seen_at=utcnow(),
                )
                session.add(device)
            else:
                device.status = "online"
                device.last_seen_at = utcnow()
            await session.commit()
            await session.refresh(device)
            return device

    async def get_runner_device(self, user_id: UUID) -> Device | None:
        async with self._session_factory() as session:
            device: Device | None = await session.scalar(
                select(Device).where(Device.user_id == user_id, Device.platform == CLOUD_PLATFORM)
            )
            return device

    async def heartbeat_runners(self) -> int:
        """Marks every cloud runner device online. Called periodically by the
        app lifespan in cloud mode, replacing the laptop agent's heartbeat."""
        async with self._session_factory() as session:
            result = await session.execute(select(Device).where(Device.platform == CLOUD_PLATFORM))
            devices = list(result.scalars().all())
            now = utcnow()
            for device in devices:
                device.status = "online"
                device.last_seen_at = now
            await session.commit()
            return len(devices)

    # ----------------------------------------------------------------- connect

    async def connect_repository(
        self, user: User, raw_url: str, branch: str | None, token: str | None
    ) -> SyncedRepository:
        try:
            source = parse_repo_source(raw_url, allow_local=self._settings.allow_local_git_urls)
        except ValueError as exc:
            raise ConflictError(str(exc)) from exc
        self._enforce_demo_allowlist(user, source)

        if token and token.strip():
            await self._user_ai_settings_service.set_github_token(user.id, token)
        resolved_token = await self._resolve_token(user.id)
        env = self._git_env(resolved_token, user.name, user.email)

        device = await self.ensure_runner_device(user.id)
        workdir = self.workspace_path(user.id, source)
        await self._clone_or_update(workdir, source, branch, env)

        current_branch = await self._git_output(workdir, ["rev-parse", "--abbrev-ref", "HEAD"], env)
        default_branch = await self._detect_default_branch(workdir, env) or current_branch

        async with self._session_factory() as session:
            repo = await session.scalar(
                select(SyncedRepository).where(
                    SyncedRepository.user_id == user.id,
                    SyncedRepository.device_id == device.id,
                    SyncedRepository.git_root == str(workdir),
                )
            )
            metadata = {
                "source": GITHUB_SOURCE,
                "url": source.url,
                "owner": source.owner,
                "repo": source.name,
            }
            now = utcnow()
            if repo is None:
                repo = SyncedRepository(
                    user_id=user.id,
                    device_id=device.id,
                    name=source.name,
                    local_path=str(workdir),
                    git_root=str(workdir),
                    current_branch=current_branch,
                    default_branch=default_branch,
                    last_scanned_at=now,
                    metadata_json=metadata,
                    is_active=True,
                )
                session.add(repo)
            else:
                repo.name = source.name
                repo.current_branch = current_branch
                repo.default_branch = default_branch
                repo.last_scanned_at = now
                repo.metadata_json = metadata
                repo.is_active = True
            await session.commit()
            await session.refresh(repo)
            repo.device = device
            return repo

    def workspace_path(self, user_id: UUID, source: RepoSource) -> Path:
        return (
            Path(self._settings.workspaces_root) / str(user_id) / f"{source.owner}__{source.name}"
        )

    def _enforce_demo_allowlist(self, user: User, source: RepoSource) -> None:
        demo_email = self._settings.demo_account_email
        allowlist = self._settings.demo_repo_allowlist_urls
        if not demo_email or user.email != demo_email or not allowlist:
            return
        allowed = {self._normalize_for_allowlist(item) for item in allowlist}
        if self._normalize_for_allowlist(source.url) not in allowed:
            raise ForbiddenError(
                "The demo account can only connect the demo repositories. "
                "Sign in with your own account to use other repositories."
            )

    @staticmethod
    def _normalize_for_allowlist(url: str) -> str:
        value = url.strip().rstrip("/")
        value = value.removesuffix(".git")
        return value.removeprefix("https://").removeprefix("http://").removeprefix("www.").lower()

    async def _resolve_token(self, user_id: UUID) -> str | None:
        stored = await self._user_ai_settings_service.get_github_token(user_id)
        return stored or self._settings.github_default_token

    async def _clone_or_update(
        self, workdir: Path, source: RepoSource, branch: str | None, env: dict[str, str]
    ) -> None:
        if (workdir / ".git").is_dir():
            await self._git(workdir, ["fetch", "--prune", "origin"], env)
            if branch:
                await self._checkout_branch(workdir, branch, env)
            if await self._is_clean(workdir, env):
                try:
                    await self._git(workdir, ["pull", "--ff-only"], env)
                except GitCommandFailedError as exc:
                    logger.warning(
                        "cloud_repo.ff_pull_failed", workdir=str(workdir), error=str(exc)
                    )
            return

        workdir.parent.mkdir(parents=True, exist_ok=True)
        args = ["clone"]
        if branch:
            args += ["--branch", branch]
        args += [source.url, str(workdir)]
        await self._git(workdir.parent, args, env, timeout_seconds=600)

    async def _checkout_branch(self, workdir: Path, branch: str, env: dict[str, str]) -> None:
        try:
            await self._git(workdir, ["checkout", branch], env)
        except GitCommandFailedError:
            await self._git(workdir, ["checkout", "-B", branch, f"origin/{branch}"], env)

    # ------------------------------------------------------------------- hooks

    async def prepare_for_task(self, user_id: UUID, workdir: str) -> None:
        """Runs right before a worker starts in `workdir`. Only acts on cloud
        workspaces: re-clones one that vanished (ephemeral disk) and otherwise
        fetches and fast-forwards when the tree is clean, so uncommitted work
        from a previous task is never thrown away silently."""
        repo = await self._find_repo(user_id, workdir)
        if repo is None:
            return
        source = self._source_from_repo(repo)
        if source is None:
            return
        user = await self._load_user(user_id)
        env = self._git_env(
            await self._resolve_token(user_id),
            user.name if user else None,
            user.email if user else None,
        )
        path = Path(workdir)
        try:
            if not (path / ".git").is_dir():
                logger.info("cloud_repo.recloning_missing_workspace", workdir=workdir)
                await self._clone_or_update(path, source, repo.current_branch, env)
                return
            await self._git(path, ["fetch", "--prune", "origin"], env)
            if await self._is_clean(path, env):
                await self._git(path, ["pull", "--ff-only"], env)
        except GitCommandFailedError as exc:
            logger.warning("cloud_repo.prepare_failed", workdir=workdir, error=str(exc))

    async def resolve_git_env(self, user_id: UUID, repo_path: str) -> dict[str, str] | None:
        """Environment for git commands run by GitService in `repo_path`, or None
        when the path is not a cloud workspace (desktop mode: inherit as before)."""
        repo = await self._find_repo(user_id, repo_path)
        if repo is None or self._source_from_repo(repo) is None:
            return None
        user = await self._load_user(user_id)
        return self._git_env(
            await self._resolve_token(user_id),
            user.name if user else None,
            user.email if user else None,
        )

    async def reset_workspace(self, user_id: UUID, repo_path: str) -> bool:
        """Discards uncommitted changes in a cloud workspace. Returns False (and
        does nothing) for desktop repositories, whose trees the user owns."""
        repo = await self._find_repo(user_id, repo_path)
        if repo is None or self._source_from_repo(repo) is None:
            return False
        env = self._git_env(None, None, None)
        path = Path(repo_path)
        if not (path / ".git").is_dir():
            return False
        await self._git(path, ["checkout", "--", "."], env)
        await self._git(path, ["clean", "-fd"], env)
        return True

    # ----------------------------------------------------------------- helpers

    async def _find_repo(self, user_id: UUID, path: str) -> SyncedRepository | None:
        async with self._session_factory() as session:
            repo: SyncedRepository | None = await session.scalar(
                select(SyncedRepository).where(
                    SyncedRepository.user_id == user_id,
                    SyncedRepository.git_root == path,
                )
            )
            return repo

    async def _load_user(self, user_id: UUID) -> User | None:
        async with self._session_factory() as session:
            return await session.get(User, user_id)

    @staticmethod
    def _source_from_repo(repo: SyncedRepository) -> RepoSource | None:
        metadata = repo.metadata_json or {}
        if metadata.get("source") != GITHUB_SOURCE:
            return None
        url = metadata.get("url")
        if not isinstance(url, str) or not url:
            return None
        return RepoSource(
            url=url, owner=str(metadata.get("owner", "")), name=str(metadata.get("repo", repo.name))
        )

    def _git_env(
        self, token: str | None, author_name: str | None, author_email: str | None
    ) -> dict[str, str]:
        name = author_name or self._settings.git_author_name
        email = author_email or self._settings.git_author_email
        env = {
            **os.environ,
            "GIT_TERMINAL_PROMPT": "0",
            "GIT_AUTHOR_NAME": name,
            "GIT_AUTHOR_EMAIL": email,
            "GIT_COMMITTER_NAME": name,
            "GIT_COMMITTER_EMAIL": email,
        }
        if token:
            env[GIT_TOKEN_ENV] = token
            env["GIT_CONFIG_COUNT"] = "1"
            env["GIT_CONFIG_KEY_0"] = "credential.helper"
            env["GIT_CONFIG_VALUE_0"] = _CREDENTIAL_HELPER
        return env

    async def _is_clean(self, workdir: Path, env: dict[str, str]) -> bool:
        status = await self._git_output(workdir, ["status", "--porcelain"], env)
        return status == ""

    async def _detect_default_branch(self, workdir: Path, env: dict[str, str]) -> str | None:
        try:
            ref = await self._git_output(workdir, ["symbolic-ref", "refs/remotes/origin/HEAD"], env)
        except GitCommandFailedError:
            return None
        return ref.rsplit("/", 1)[-1] if ref else None

    async def _git_output(self, cwd: Path, args: list[str], env: dict[str, str]) -> str:
        stdout, _ = await self._run(cwd, args, env, timeout_seconds=60)
        return stdout.strip()

    async def _git(
        self, cwd: Path, args: list[str], env: dict[str, str], timeout_seconds: float = 120
    ) -> None:
        await self._run(cwd, args, env, timeout_seconds=timeout_seconds)

    async def _run(
        self, cwd: Path, args: list[str], env: dict[str, str], timeout_seconds: float
    ) -> tuple[str, str]:
        managed = await ManagedSubprocess.spawn(
            ["git", *args], cwd=str(cwd), use_stdin=False, env=env
        )
        stdout: list[str] = []
        stderr: list[str] = []

        async def _collect(line: str, source: str) -> None:
            (stdout if source == "stdout" else stderr).append(line)

        managed.start_streaming(_collect)
        exit_code, timed_out = await managed.wait(timeout_seconds=timeout_seconds)
        secrets = [env.get(GIT_TOKEN_ENV, "")]
        if timed_out:
            raise GitCommandFailedError(f"git {' '.join(args)} timed out")
        if exit_code != 0:
            detail = scrub_secrets("\n".join(stderr[-10:]), secrets) or f"exit code {exit_code}"
            raise GitCommandFailedError(f"git {' '.join(args)} failed: {detail}")
        return "\n".join(stdout), "\n".join(stderr)
