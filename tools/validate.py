#!/usr/bin/env python3
"""Self-contained repository validation used locally and in CI."""

from __future__ import annotations

import json
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "plugins" / "vibe-living"
SEMVER = re.compile(r"^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$")
MARKDOWN_IMAGE = re.compile(r"!\[[^\]]*\]\((?:<([^>]+)>|([^\s)]+))")
DESIGN_SUFFIXES = {
    ".gif", ".jpeg", ".jpg", ".mp3", ".otf", ".pdf", ".png",
    ".svg", ".ttf", ".wav", ".webp",
}


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def tracked_files(root: Path) -> set[Path]:
    result = subprocess.run(
        ["git", "ls-files", "--cached", "-z"],
        cwd=root,
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        return set()
    return {
        (root / relative.decode("utf-8")).resolve()
        for relative in result.stdout.split(b"\0")
        if relative
    }


def design_asset_errors(
    root: Path,
    plugin: Path,
    codex: dict,
    tracked: set[Path],
) -> list[str]:
    errors: list[str] = []
    assets_directory = plugin / "assets"
    manifest_path = assets_directory / "manifest.json"
    if not manifest_path.is_file():
        return ["Missing design asset manifest: plugins/vibe-living/assets/manifest.json"]
    if manifest_path.resolve() not in tracked:
        errors.append("Design asset manifest is not tracked or staged in Git: plugins/vibe-living/assets/manifest.json")

    try:
        manifest = load(manifest_path)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        errors.append(f"Invalid design asset manifest: {error}")
        return errors

    entries = manifest.get("assets")
    if not isinstance(entries, list):
        errors.append("Design asset manifest must contain an assets list")
        return errors

    declared: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict):
            errors.append("Every design asset manifest entry must be an object")
            continue
        relative = entry.get("path")
        purpose = entry.get("purpose")
        if not isinstance(relative, str) or not relative or Path(relative).is_absolute() or ".." in Path(relative).parts:
            errors.append(f"Invalid design asset path: {relative!r}")
            continue
        if not isinstance(purpose, str) or not purpose.strip():
            errors.append(f"Design asset {relative} must declare its purpose")
        if relative in declared:
            errors.append(f"Duplicate design asset manifest entry: {relative}")
            continue
        declared.add(relative)

        target = (assets_directory / relative).resolve()
        if not target.is_file():
            errors.append(f"Missing declared design asset: plugins/vibe-living/assets/{relative}")
        elif target not in tracked:
            errors.append(f"Design asset is not tracked or staged in Git: plugins/vibe-living/assets/{relative}")

    formal_files = {
        path.resolve()
        for path in plugin.rglob("*")
        if path.is_file() and path.suffix.lower() in DESIGN_SUFFIXES
    }
    declared_files = {(assets_directory / relative).resolve() for relative in declared}
    for path in sorted(formal_files - declared_files):
        try:
            relative = path.relative_to(root.resolve())
        except ValueError:
            relative = path
        errors.append(f"Design asset is outside the asset manifest: {relative}")

    screenshots = codex.get("interface", {}).get("screenshots", [])
    for screenshot in screenshots:
        if not isinstance(screenshot, str) or not screenshot.startswith("./assets/"):
            errors.append(f"Plugin screenshot must be stored under ./assets/: {screenshot!r}")
            continue
        relative = screenshot.removeprefix("./assets/")
        if relative not in declared:
            errors.append(f"Plugin screenshot is missing from the asset manifest: {screenshot}")

    for markdown in root.rglob("*.md"):
        if any(part in {".git", "dist"} for part in markdown.parts):
            continue
        content = markdown.read_text(encoding="utf-8")
        for match in MARKDOWN_IMAGE.finditer(content):
            reference = match.group(1) or match.group(2)
            if reference.startswith(("http://", "https://", "data:")):
                continue
            target = (markdown.parent / reference).resolve()
            try:
                target.relative_to(root.resolve())
            except ValueError:
                errors.append(f"Markdown image must be stored in the repository: {markdown.relative_to(root)} -> {reference}")
                continue
            if not target.is_file():
                errors.append(f"Missing Markdown image: {markdown.relative_to(root)} -> {reference}")
            elif target not in tracked:
                errors.append(f"Markdown image is not tracked or staged in Git: {target.relative_to(root.resolve())}")

    return errors


def main() -> int:
    errors: list[str] = []
    codex = load(PLUGIN / ".codex-plugin" / "plugin.json")
    claude = load(PLUGIN / ".claude-plugin" / "plugin.json")
    hooks = load(PLUGIN / "hooks" / "hooks.json")
    marketplace = load(ROOT / ".agents" / "plugins" / "marketplace.json")
    tracked = tracked_files(ROOT)

    required_project_files = [
        ROOT / "docs" / "specs" / "README.md",
        ROOT / "docs" / "specs" / "design-assets.md",
        ROOT / "docs" / "specs" / "development-workflow.md",
        ROOT / "docs" / "specs" / "harness.md",
        ROOT / "docs" / "specs" / "localization.md",
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

    expected_screenshots = {
        "./assets/preview.png",
        "./assets/preview-en.png",
        "./assets/hydration-preview.png",
        "./assets/hydration-preview-en.png",
    }
    screenshots = set(codex.get("interface", {}).get("screenshots", []))
    if screenshots != expected_screenshots:
        errors.append("Plugin screenshots must include Chinese and English movement and hydration previews")

    errors.extend(design_asset_errors(ROOT, PLUGIN, codex, tracked))

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1
    print("Repository metadata: passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
