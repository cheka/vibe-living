#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
plugin_root="$repo_root/plugins/vibe-living"
binary="$plugin_root/bin/vibe-living-$(uname -m)"
preview_data="${TMPDIR:-/tmp}/vibe-living-preview-$UID"

/bin/mkdir -p "$preview_data"
"$binary" --render-preview "$plugin_root/assets/preview.png" "$preview_data"
"$binary" --render-preview "$plugin_root/assets/hydration-preview.png" "$preview_data" 106
echo "Rendered movement and hydration previews under $plugin_root/assets"
