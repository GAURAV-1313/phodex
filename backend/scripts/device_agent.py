#!/usr/bin/env python3
"""Phodex device agent.

Fills the gap this project didn't have any tooling for: something that
actually runs on the user's own machine, registers it as a Device, finds git
repositories under configured watch directories, and keeps Phodex's view of
"what's synced" and "is this machine online" current — via `/repos/sync` and
periodic `/devices/heartbeat` calls. Every repo/device registration used
during this project's development happened by hand with `curl`; this script
is what that hand-run sequence turns into as a real, runnable tool.

Usage:
    PHODEX_BASE_URL=http://127.0.0.1:8000 \\
    PHODEX_GOOGLE_ID_TOKEN='test-token|local-user|you@example.com|Your Name' \\
    PHODEX_WATCH_DIRS=~/code:~/projects \\
    python3 scripts/device_agent.py

Auth: pass either PHODEX_AUTH_TOKEN (a bearer JWT you already have — e.g.
from a real signed-in mobile session) or PHODEX_GOOGLE_ID_TOKEN (exchanged
for one automatically via POST /auth/google, the same call the mobile app
makes — including this project's pipe-delimited dev test-token format while
real Google OAuth isn't configured).

State: the device's own id is cached in ~/.phodex/device.json so repeated
runs update the same Device row instead of registering a new one every time.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

STATE_DIR = Path.home() / ".phodex"
STATE_FILE = STATE_DIR / "device.json"
DEFAULT_SYNC_INTERVAL_SECONDS = 60
DEFAULT_HEARTBEAT_INTERVAL_SECONDS = 45


@dataclass
class Config:
    base_url: str
    auth_token: str | None
    google_id_token: str | None
    watch_dirs: list[Path]
    device_name: str
    sync_interval_seconds: int
    heartbeat_interval_seconds: int
    once: bool


def load_config() -> Config:
    parser = argparse.ArgumentParser(description="Phodex device agent")
    parser.add_argument(
        "--once",
        action="store_true",
        help="Register, sync once, send one heartbeat, then exit (no loop).",
    )
    args = parser.parse_args()

    base_url = os.environ.get("PHODEX_BASE_URL", "http://127.0.0.1:8000").rstrip("/")
    watch_dirs_raw = os.environ.get("PHODEX_WATCH_DIRS", "")
    watch_dirs = [
        Path(p).expanduser().resolve()
        for p in watch_dirs_raw.split(":")
        if p.strip()
    ]
    if not watch_dirs:
        print(
            "PHODEX_WATCH_DIRS is not set (colon-separated directories to scan "
            "for git repos, e.g. PHODEX_WATCH_DIRS=~/code:~/projects). Nothing "
            "to sync without it.",
            file=sys.stderr,
        )
        sys.exit(2)

    auth_token = os.environ.get("PHODEX_AUTH_TOKEN")
    google_id_token = os.environ.get("PHODEX_GOOGLE_ID_TOKEN")
    if not auth_token and not google_id_token:
        print(
            "Set either PHODEX_AUTH_TOKEN (an existing bearer JWT) or "
            "PHODEX_GOOGLE_ID_TOKEN (exchanged for one automatically).",
            file=sys.stderr,
        )
        sys.exit(2)

    return Config(
        base_url=base_url,
        auth_token=auth_token,
        google_id_token=google_id_token,
        watch_dirs=watch_dirs,
        device_name=os.environ.get("PHODEX_DEVICE_NAME", _default_device_name()),
        sync_interval_seconds=int(
            os.environ.get("PHODEX_SYNC_INTERVAL_SECONDS", DEFAULT_SYNC_INTERVAL_SECONDS)
        ),
        heartbeat_interval_seconds=int(
            os.environ.get(
                "PHODEX_HEARTBEAT_INTERVAL_SECONDS", DEFAULT_HEARTBEAT_INTERVAL_SECONDS
            )
        ),
        once=args.once,
    )


def _default_device_name() -> str:
    try:
        return subprocess.run(
            ["scutil", "--get", "ComputerName"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip() or os.uname().nodename
    except (FileNotFoundError, subprocess.CalledProcessError):
        return os.uname().nodename


class ApiClient:
    def __init__(self, base_url: str, token: str) -> None:
        self._base_url = base_url
        self._token = token

    def _request(self, method: str, path: str, body: dict | None = None) -> dict:
        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = Request(
            f"{self._base_url}{path}",
            data=data,
            method=method,
            headers={
                "Authorization": f"Bearer {self._token}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urlopen(req, timeout=15) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else {}
        except HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"{method} {path} -> HTTP {exc.code}: {detail}") from exc
        except URLError as exc:
            raise RuntimeError(f"{method} {path} -> connection error: {exc.reason}") from exc

    def register_device(self, name: str, device_id: str | None) -> dict:
        body = {"name": name, "platform": "macos", "agent_version": "0.1.0"}
        if device_id:
            body["device_id"] = device_id
        return self._request("POST", "/devices/register", body)

    def heartbeat(self, device_id: str) -> dict:
        return self._request(
            "POST", "/devices/heartbeat", {"device_id": device_id, "status": "online"}
        )

    def sync_repos(self, device_id: str, repositories: list[dict]) -> dict:
        return self._request(
            "POST", "/repos/sync", {"device_id": device_id, "repositories": repositories}
        )


def exchange_google_id_token(base_url: str, id_token: str) -> str:
    req = Request(
        f"{base_url}/auth/google",
        data=json.dumps({"id_token": id_token}).encode("utf-8"),
        method="POST",
        headers={"Content-Type": "application/json"},
    )
    with urlopen(req, timeout=15) as resp:
        payload: dict = json.loads(resp.read())
    return str(payload["access_token"])


def load_device_id() -> str | None:
    if not STATE_FILE.exists():
        return None
    try:
        payload: dict = json.loads(STATE_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        return None
    device_id = payload.get("device_id")
    return str(device_id) if device_id else None


def save_device_id(device_id: str) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps({"device_id": device_id}))


def _git(*args: str, cwd: Path) -> str | None:
    try:
        result = subprocess.run(
            ["git", *args], cwd=cwd, capture_output=True, text=True, timeout=5
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def discover_repos(watch_dirs: list[Path]) -> list[dict]:
    """One level deep under each watch dir, plus the watch dir itself if it's
    a repo — matches how people actually organize a `~/code`-style folder of
    projects, without recursing into node_modules-sized subtrees."""
    candidates: list[Path] = []
    for root in watch_dirs:
        if not root.is_dir():
            print(f"  (skipping {root} — not a directory)", file=sys.stderr)
            continue
        if (root / ".git").is_dir():
            candidates.append(root)
        for child in sorted(root.iterdir()):
            if child.is_dir() and (child / ".git").is_dir():
                candidates.append(child)

    repos: list[dict] = []
    for path in candidates:
        branch = _git("rev-parse", "--abbrev-ref", "HEAD", cwd=path) or "main"
        default_branch = _git(
            "symbolic-ref", "refs/remotes/origin/HEAD", cwd=path
        )
        if default_branch:
            default_branch = default_branch.rsplit("/", 1)[-1]
        repos.append(
            {
                "name": path.name,
                "local_path": str(path),
                "git_root": str(path),
                "current_branch": branch,
                "default_branch": default_branch or branch,
                "metadata_json": {},
            }
        )
    return repos


def run() -> None:
    config = load_config()

    token = config.auth_token
    if not token:
        print("Exchanging Google ID token for a Phodex session...")
        token = exchange_google_id_token(config.base_url, config.google_id_token)  # type: ignore[arg-type]

    client = ApiClient(config.base_url, token)

    device_id = load_device_id()
    device = client.register_device(config.device_name, device_id)
    device_id = device["id"]
    save_device_id(device_id)
    print(f"Device registered: {config.device_name} ({device_id})")

    def sync_once() -> None:
        repos = discover_repos(config.watch_dirs)
        if not repos:
            print("  No git repositories found under the watch directories.")
            return
        client.sync_repos(device_id, repos)
        names = ", ".join(r["name"] for r in repos)
        print(f"  Synced {len(repos)} repo(s): {names}")

    print("Scanning watch directories:", ", ".join(str(d) for d in config.watch_dirs))
    sync_once()
    client.heartbeat(device_id)
    print("Heartbeat sent.")

    if config.once:
        return

    print(
        f"Watching. Re-syncing every {config.sync_interval_seconds}s, "
        f"heartbeat every {config.heartbeat_interval_seconds}s. Ctrl+C to stop."
    )
    last_sync = time.monotonic()
    try:
        while True:
            time.sleep(config.heartbeat_interval_seconds)
            try:
                client.heartbeat(device_id)
            except RuntimeError as exc:
                print(f"  heartbeat failed: {exc}", file=sys.stderr)

            if time.monotonic() - last_sync >= config.sync_interval_seconds:
                try:
                    sync_once()
                except RuntimeError as exc:
                    print(f"  sync failed: {exc}", file=sys.stderr)
                last_sync = time.monotonic()
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    try:
        run()
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
