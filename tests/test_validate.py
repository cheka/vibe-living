from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
VALIDATE_PATH = ROOT / "tools" / "validate.py"
SPEC = importlib.util.spec_from_file_location("vibe_living_validate", VALIDATE_PATH)
assert SPEC and SPEC.loader
VALIDATE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATE)


class DesignAssetValidationTests(unittest.TestCase):
    def create_repository(self, directory: str) -> tuple[Path, Path, dict, set[Path]]:
        root = Path(directory)
        plugin = root / "plugins" / "vibe-living"
        assets = plugin / "assets"
        assets.mkdir(parents=True)
        image = assets / "preview.png"
        image.write_bytes(b"preview")
        manifest = assets / "manifest.json"
        manifest.write_text(
            json.dumps({"version": 1, "assets": [{"path": "preview.png", "purpose": "Published preview"}]}),
            encoding="utf-8",
        )
        codex = {"interface": {"screenshots": ["./assets/preview.png"]}}
        tracked = {manifest.resolve(), image.resolve()}
        return root, plugin, codex, tracked

    def test_accepts_declared_tracked_assets(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, plugin, codex, tracked = self.create_repository(directory)
            self.assertEqual(VALIDATE.design_asset_errors(root, plugin, codex, tracked), [])

    def test_rejects_unlisted_or_untracked_assets(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root, plugin, codex, tracked = self.create_repository(directory)
            orphan = plugin / "orphan.png"
            orphan.write_bytes(b"orphan")
            tracked.remove((plugin / "assets" / "preview.png").resolve())

            errors = VALIDATE.design_asset_errors(root, plugin, codex, tracked)

            self.assertTrue(any("not tracked or staged" in error for error in errors))
            self.assertTrue(any("outside the asset manifest" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
