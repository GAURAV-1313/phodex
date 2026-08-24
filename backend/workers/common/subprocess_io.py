"""Generic async subprocess runner shared by worker engines.

Handles spawning, line-by-line stdout/stderr streaming to a callback, a
run-wide timeout with kill-on-timeout, and writing follow-up lines to a
still-open stdin. Carries no knowledge of tasks, events, or any particular
runtime's output format — engines interpret lines themselves via `on_line`.
"""

import asyncio
from collections.abc import Awaitable, Callable

OnLine = Callable[[str, str], Awaitable[None]]


class ManagedSubprocess:
    def __init__(self, process: asyncio.subprocess.Process) -> None:
        self.process = process
        self._stdout_task: asyncio.Task[None] | None = None
        self._stderr_task: asyncio.Task[None] | None = None

    @classmethod
    async def spawn(
        cls,
        command: list[str],
        *,
        cwd: str | None,
        use_stdin: bool,
        env: dict[str, str] | None = None,
    ) -> "ManagedSubprocess":
        process = await asyncio.create_subprocess_exec(
            *command,
            cwd=cwd,
            stdin=asyncio.subprocess.PIPE if use_stdin else None,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )
        return cls(process)

    async def send_and_close_stdin(self, payload: str) -> None:
        stdin = self.process.stdin
        if stdin is None:
            return
        stdin.write((payload + "\n").encode("utf-8"))
        await stdin.drain()
        stdin.close()

    async def write_line(self, content: str) -> bool:
        """Writes a follow-up line to stdin. Returns False if stdin is unavailable or closing."""
        stdin = self.process.stdin
        if stdin is None or stdin.is_closing():
            return False
        stdin.write((content.strip() + "\n").encode("utf-8"))
        await stdin.drain()
        return True

    def start_streaming(self, on_line: OnLine) -> None:
        self._stdout_task = asyncio.create_task(
            self._consume(self.process.stdout, "stdout", on_line)
        )
        self._stderr_task = asyncio.create_task(
            self._consume(self.process.stderr, "stderr", on_line)
        )

    @staticmethod
    async def _consume(
        stream: asyncio.StreamReader | None, source: str, on_line: OnLine
    ) -> None:
        if stream is None:
            return
        while True:
            raw = await stream.readline()
            if not raw:
                return
            line = raw.decode("utf-8", errors="replace").strip()
            if not line:
                continue
            await on_line(line, source)

    async def wait(self, timeout_seconds: float) -> tuple[int, bool]:
        """Waits for exit with a timeout, killing the process if it fires.

        Always drains the stream-consumer tasks before returning, so no
        output is lost even when the wait itself times out.
        """
        timed_out = False
        try:
            exit_code = await asyncio.wait_for(self.process.wait(), timeout=timeout_seconds)
        except TimeoutError:
            timed_out = True
            self.process.kill()
            exit_code = await self.process.wait()
        finally:
            tasks = [t for t in (self._stdout_task, self._stderr_task) if t is not None]
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)
        return exit_code, timed_out

    def terminate(self) -> None:
        if self.process.returncode is None:
            self.process.terminate()

    def kill(self) -> None:
        if self.process.returncode is None:
            self.process.kill()
