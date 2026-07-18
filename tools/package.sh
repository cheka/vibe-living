#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$repo_root/plugins/vibe-living/.codex-plugin/plugin.json"
version="$(/usr/bin/python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$manifest")"
dist="$repo_root/dist"

/bin/mkdir -p "$dist"
(
  cd "$repo_root"
  /usr/bin/tar -czf "$dist/vibe-living-$version.tar.gz" \
    .agents plugins README.md README.zh-CN.md LICENSE CHANGELOG.md SECURITY.md
)
(
  cd "$dist"
  /usr/bin/shasum -a 256 "vibe-living-$version.tar.gz" > "vibe-living-$version.tar.gz.sha256"
)
echo "Packaged $dist/vibe-living-$version.tar.gz"
