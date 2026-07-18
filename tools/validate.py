#!/usr/bin/env python3
"""Self-contained repository validation used locally and in CI."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "plugins" / "vibe-living"
SEMVER = re.compile(r"^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$")


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def main() -> int:
    errors: list[str] = []
    codex = load(PLUGIN / ".codex-plugin" / "plugin.json")
    claude = load(PLUGIN / ".claude-plugin" / "plugin.json")
    hooks = load(PLUGIN / "hooks" / "hooks.json")
    marketplace = load(ROOT / ".agents" / "plugins" / "marketplace.json")

    required_project_files = [
        ROOT / "docs" / "specs" / "README.md",
        ROOT / "docs" / "specs" / "development-workflow.md",
        ROOT / "docs" / "specs" / "harness.md",
        ROOT / "harness" / "run.py",
    ]
    for path in required_project_files:
        if not path.is_file():
            errors.append(f"Missing required project file: {path.relative_to(ROOT)}")

    for label, manifest in (("Codex", codex), ("Claude", claude)):
        if manifest.get("name") != "vibe-living":
            errors.append(f"{label} manifest name must be vibe-living")
        if not SEMVER.fullmatch(str(manifest.get("version", ""))):
            errors.append(f"{label} manifest version must be semantic")
    if codex.get("version") != claude.get("version"):
        errors.append("Codex and Claude manifest versions must match")

    entries = marketplace.get("plugins", [])
    if len(entries) != 1 or entries[0].get("name") != "vibe-living":
        errors.append("Marketplace must contain exactly the vibe-living plugin")
    elif entries[0].get("source", {}).get("path") != "./plugins/vibe-living":
        errors.append("Marketplace source path is incorrect")

    required_events = {
        "SessionStart", "UserPromptSubmit", "PreToolUse",
        "PermissionRequest", "PostToolUse", "Stop",
    }
    configured_events = set(hooks.get("hooks", {}))
    if configured_events != required_events:
        errors.append(f"Hook events differ: {sorted(configured_events ^ required_events)}")

    for relative in codex.get("interface", {}).get("screenshots", []):
        target = PLUGIN / relative.removeprefix("./")
        if not target.is_file():
            errors.append(f"Missing screenshot: {relative}")

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1
    print("Repository metadata: passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
