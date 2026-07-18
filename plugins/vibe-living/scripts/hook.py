#!/usr/bin/env python3
"""Translate agent lifecycle events into local Vibe Living state."""

from __future__ import annotations

import json
import hashlib
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import time


VALID_ACTIONS = {"session", "working", "waiting", "done"}
HARNESS_ENVIRONMENT = "VIBE_LIVING_HARNESS"


def safe_session_id(value: object) -> str:
    text = str(value or "default")
    cleaned = re.sub(r"[^A-Za-z0-9_.-]", "-", text)
    return cleaned[:120] or "default"


def plugin_data_directory() -> Path:
    configured = os.environ.get("CLAUDE_PLUGIN_DATA") or os.environ.get("PLUGIN_DATA")
    if configured:
        return Path(configured)
    return Path(os.environ.get("TMPDIR", "/tmp")) / f"vibe-living-{os.getuid()}"


def source_digest(root: Path) -> str:
    source = root / "scripts" / "VibeLiving.swift"
    return hashlib.sha256(source.read_bytes()).hexdigest()


def ensure_native_helper(root: Path, data: Path) -> Path | None:
    binary = data / "vibe-living"
    hash_file = data / "source.sha256"
    digest = source_digest(root)
    try:
        installed_digest = hash_file.read_text(encoding="utf-8")
    except OSError:
        installed_digest = ""

    if binary.is_file() and os.access(binary, os.X_OK) and installed_digest == digest:
        return binary

    packaged = root / "bin" / f"vibe-living-{platform.machine()}"
    if packaged.is_file() and os.access(packaged, os.X_OK):
        temporary = data / f"vibe-living.install.{os.getpid()}"
        shutil.copyfile(packaged, temporary)
        temporary.chmod(0o755)
        os.replace(temporary, binary)
        hash_file.write_text(digest, encoding="utf-8")
        return binary

    # Unsupported Mac architectures use the slower source-build fallback.
    runner = root / "scripts" / "vibe-living"
    subprocess.Popen(
        [str(runner), "session", "bootstrap"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env={**os.environ, "CLAUDE_PLUGIN_ROOT": str(root)},
        start_new_session=True,
        close_fds=True,
    )
    return None


def daemon_is_running(data: Path) -> bool:
    try:
        pid = int((data / "daemon.pid").read_text(encoding="utf-8").strip())
        os.kill(pid, 0)
        return True
    except (OSError, ValueError):
        return False


def ensure_daemon(binary: Path | None, data: Path) -> None:
    if binary is None or daemon_is_running(data):
        return
    lock = data / "daemon-start.lock"
    try:
        descriptor = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        os.close(descriptor)
    except FileExistsError:
        return

    try:
        if daemon_is_running(data):
            return
        subprocess.Popen(
            [str(binary), "--daemon", str(data)],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )
        # Keep the lock until the daemon has published its pid.
        for _ in range(20):
            if daemon_is_running(data):
                break
            time.sleep(0.05)
    finally:
        lock.unlink(missing_ok=True)


def update_session_state(action: str, session_id: str, data: Path) -> None:
    if action == "session":
        return
    sessions = data / "sessions"
    sessions.mkdir(parents=True, exist_ok=True)
    state_file = sessions / f"{session_id}.json"
    if action == "done":
        state_file.unlink(missing_ok=True)
        return

    now = time.time()
    started_at = now
    try:
        previous = json.loads(state_file.read_text(encoding="utf-8"))
        if previous.get("action") in {"working", "waiting"}:
            started_at = float(previous.get("startedAt", now))
    except (OSError, ValueError, TypeError, json.JSONDecodeError):
        pass

    payload = {"action": action, "startedAt": started_at, "updatedAt": now}
    temporary = sessions / f".{session_id}.{os.getpid()}.tmp"
    temporary.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")
    os.replace(temporary, state_file)


def main() -> int:
    action = sys.argv[1] if len(sys.argv) > 1 else "working"
    if action not in VALID_ACTIONS:
        return 0

    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        payload = {}

    root_value = os.environ.get("CLAUDE_PLUGIN_ROOT") or os.environ.get("PLUGIN_ROOT")
    if root_value:
        root = Path(root_value)
    else:
        root = Path(__file__).resolve().parent.parent

    session_id = safe_session_id(payload.get("session_id"))
    data = plugin_data_directory()
    harness_mode = os.environ.get(HARNESS_ENVIRONMENT) == "1"
    try:
        data.mkdir(parents=True, exist_ok=True)
        update_session_state(action, session_id, data)
        if action != "done" and not harness_mode:
            binary = ensure_native_helper(root, data)
            ensure_daemon(binary, data)
    except (OSError, subprocess.SubprocessError):
        # A wellbeing helper must never interrupt the user's agent turn.
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
