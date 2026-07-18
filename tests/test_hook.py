from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import threading
import unittest


ROOT = Path(__file__).resolve().parent.parent
HOOK_PATH = ROOT / "plugins" / "vibe-living" / "scripts" / "hook.py"
SPEC = importlib.util.spec_from_file_location("vibe_living_hook", HOOK_PATH)
assert SPEC and SPEC.loader
HOOK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HOOK)


class HookTests(unittest.TestCase):
    def test_session_id_is_sanitized(self) -> None:
        self.assertEqual(HOOK.safe_session_id("a/b c"), "a-b-c")
        self.assertEqual(HOOK.safe_session_id(""), "default")

    def test_state_lifecycle_preserves_start_time(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            data = Path(directory)
            HOOK.update_session_state("working", "test", data)
            state_file = data / "sessions" / "test.json"
            first = json.loads(state_file.read_text())
            HOOK.update_session_state("waiting", "test", data)
            second = json.loads(state_file.read_text())
            self.assertEqual(first["startedAt"], second["startedAt"])
            HOOK.update_session_state("done", "test", data)
            self.assertFalse(state_file.exists())

    def test_concurrent_daemon_requests_start_once(self) -> None:
        state = {"running": False, "launches": 0}
        state_lock = threading.Lock()
        original_running = HOOK.daemon_is_running
        original_process = HOOK.subprocess.Popen

        def fake_running(_data: Path) -> bool:
            return bool(state["running"])

        class FakeProcess:
            def __init__(self, *args, **kwargs) -> None:
                with state_lock:
                    state["launches"] += 1
                state["running"] = True

        try:
            HOOK.daemon_is_running = fake_running
            HOOK.subprocess.Popen = FakeProcess
            with tempfile.TemporaryDirectory() as directory:
                data = Path(directory)
                binary = data / "helper"
                binary.write_text("fake")
                workers = [threading.Thread(target=HOOK.ensure_daemon, args=(binary, data)) for _ in range(4)]
                for worker in workers:
                    worker.start()
                for worker in workers:
                    worker.join()
            self.assertEqual(state["launches"], 1)
        finally:
            HOOK.daemon_is_running = original_running
            HOOK.subprocess.Popen = original_process


if __name__ == "__main__":
    unittest.main()
