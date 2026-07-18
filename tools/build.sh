#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
plugin_root="$repo_root/plugins/vibe-living"
architecture="$(uname -m)"
output="$plugin_root/bin/vibe-living-$architecture"

/usr/bin/xcrun swiftc -O -framework AppKit "$plugin_root/scripts/VibeLiving.swift" -o "$output"
/bin/chmod 755 "$output"
echo "Built $output"
