#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
plugin_root="$repo_root/plugins/vibe-living"

/usr/bin/python3 "$repo_root/tools/validate.py"
/usr/bin/python3 -m py_compile "$plugin_root/scripts/hook.py" "$repo_root/harness/run.py" "$repo_root/tests/test_hook.py"
/bin/bash -n "$plugin_root/scripts/vibe-living" "$repo_root/tools/build.sh" "$repo_root/tools/package.sh" "$repo_root/tools/preview.sh"
/usr/bin/python3 -m unittest discover -s "$repo_root/tests" -p 'test_*.py' -v
/usr/bin/python3 "$repo_root/harness/run.py"
/usr/bin/xcrun swiftc -typecheck -framework AppKit "$plugin_root/scripts/VibeLiving.swift"

echo "All checks passed."
