#!/usr/bin/env python3
"""Run the Vibe Living lifecycle Hook in an isolated, headless environment."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent
PLUGIN_ROOT = ROOT / "plugins" / "vibe-living"
HOOK = PLUGIN_ROOT / "scripts" / "hook.py"
SYNTHETIC_SESSION_ID = "harness/desk session"
SAFE_SESSION_ID = "harness-desk-session"


class HarnessFailure(RuntimeError):
    """Raised when an observable Harness requirement is not met."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise HarnessFailure(message)


def invoke_hook(action: str, data_directory: Path, verbose: bool) -> None:
    environment = {
        **os.environ,
        "PLUGIN_ROOT": str(PLUGIN_ROOT),
        "PLUGIN_DATA": str(data_directory),
        "VIBE_LIVING_HARNESS": "1",
        "PYTHONDONTWRITEBYTECODE": "1",
    }
    payload = json.dumps({"session_id": SYNTHETIC_SESSION_ID})
    result = subprocess.run(
        [sys.executable, str(HOOK), action],
        input=payload,
        text=True,
        capture_output=True,
        env=environment,
        check=False,
    )
    if verbose:
        print(f"hook {action}: exit={result.returncode}")
    require(result.returncode == 0, f"hook action {action!r} exited with {result.returncode}")
    require(not result.stderr, f"hook action {action!r} wrote to stderr: {result.stderr.strip()}")


def read_state(state_file: Path, expected_action: str, verbose: bool) -> dict:
    require(state_file.is_file(), f"missing session state after {expected_action!r}")
    value = json.loads(state_file.read_text(encoding="utf-8"))
    require(value.get("action") == expected_action, f"expected action {expected_action!r}, got {value.get('action')!r}")
    require(isinstance(value.get("startedAt"), (int, float)), "state is missing startedAt")
    require(isinstance(value.get("updatedAt"), (int, float)), "state is missing updatedAt")
    if verbose:
        print(f"state {expected_action}: {json.dumps(value, sort_keys=True)}")
    return value


def run_scenario(data_directory: Path, verbose: bool) -> None:
    sessions = data_directory / "sessions"
    state_file = sessions / f"{SAFE_SESSION_ID}.json"

    invoke_hook("session", data_directory, verbose)
    require(not state_file.exists(), "session bootstrap unexpectedly created activity state")

    invoke_hook("working", data_directory, verbose)
    working = read_state(state_file, "working", verbose)
    require(not (sessions / "harness" / "desk session.json").exists(), "session ID was not sanitized")

    invoke_hook("waiting", data_directory, verbose)
    waiting = read_state(state_file, "waiting", verbose)
    require(waiting["startedAt"] == working["startedAt"], "waiting reset the session start time")

    invoke_hook("working", data_directory, verbose)
    resumed = read_state(state_file, "working", verbose)
    require(resumed["startedAt"] == working["startedAt"], "resuming reset the session start time")

    invoke_hook("done", data_directory, verbose)
    require(not state_file.exists(), "done did not remove the session state")

    forbidden_artifacts = [
        data_directory / "daemon.pid",
        data_directory / "daemon-start.lock",
        data_directory / "vibe-living",
        data_directory / "source.sha256",
    ]
    created = [path.name for path in forbidden_artifacts if path.exists()]
    require(not created, f"headless Harness created production artifacts: {', '.join(created)}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--keep", action="store_true", help="preserve the isolated data directory")
    parser.add_argument("--verbose", action="store_true", help="print every lifecycle transition")
    return parser.parse_args()


def main() -> int:
    arguments = parse_args()
    data_directory = Path(tempfile.mkdtemp(prefix="vibe-living-harness-"))
    try:
        run_scenario(data_directory, arguments.verbose)
        print("Harness passed: lifecycle state is isolated and daemon-free.")
        if arguments.keep:
            print(f"Harness data preserved at {data_directory}")
        return 0
    except (HarnessFailure, json.JSONDecodeError) as error:
        print(f"Harness failed: {error}", file=sys.stderr)
        if arguments.keep:
            print(f"Harness data preserved at {data_directory}", file=sys.stderr)
        return 1
    finally:
        if not arguments.keep:
            shutil.rmtree(data_directory, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
