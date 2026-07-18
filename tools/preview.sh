#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
plugin_root="$repo_root/plugins/vibe-living"
binary="$plugin_root/bin/vibe-living-$(uname -m)"
preview_data="${TMPDIR:-/tmp}/vibe-living-preview-$UID"

/bin/mkdir -p "$preview_data"
"$binary" --render-preview "$plugin_root/assets/preview.png" "$preview_data" 10 zh
"$binary" --render-preview "$plugin_root/assets/preview-en.png" "$preview_data" 10 en
"$binary" --render-preview "$plugin_root/assets/hydration-preview.png" "$preview_data" 106 zh
"$binary" --render-preview "$plugin_root/assets/hydration-preview-en.png" "$preview_data" 106 en
echo "Rendered Chinese and English movement and hydration previews under $plugin_root/assets"
