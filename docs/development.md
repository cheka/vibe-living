# Development

## Prerequisites

- macOS 13+
- Xcode Command Line Tools (`xcode-select --install`)
- Python 3.9+
- GNU Make (the macOS-provided Make is sufficient)
- Codex or Claude Code for integration testing

No third-party runtime dependencies are required.

## Repository layout

```text
.agents/plugins/marketplace.json   Codex marketplace catalog
plugins/vibe-living/               Installable plugin
  .codex-plugin/plugin.json        Codex manifest
  .claude-plugin/plugin.json       Claude Code manifest
  hooks/hooks.json                 Lifecycle hook registration
  scripts/hook.py                  State adapter
  scripts/VibeLiving.swift         Native overlay
  bin/                             Release binaries
tests/                             Unit tests
harness/                           Isolated lifecycle Hook Harness
docs/specs/                        Product and development specifications
tools/                             Build and validation scripts
```

## Common commands

```bash
make check
make harness
make build
make preview
make package
```

`make check` is the same entry point used by CI. It includes unit tests, the headless Harness, manifest validation, shell checks, and Swift type-checking. Run it before opening a pull request.

`make preview` deterministically renders Chinese and English movement and hydration screenshots. The preview language override is for development assets only; production reads the macOS preferred language when the native helper starts.

## Spec-first workflow

Before editing implementation code for any new requirement:

1. Find or create the relevant file under [`docs/specs/`](specs/README.md).
2. Record scope, non-goals, acceptance criteria, and verification.
3. Implement only after that spec delta is complete.
4. Run `make harness` and `make check`.

If implementation discoveries alter expected behavior, update the specification before continuing.

## Local Harness

The Harness invokes the real lifecycle Hook with synthetic metadata while disabling daemon and UI startup. Each run uses a new temporary plugin-data directory.

```bash
make harness
python3 harness/run.py --verbose
python3 harness/run.py --keep --verbose
```

Use `--verbose` to inspect every lifecycle transition. Add `--keep` to preserve the isolated state directory after a failure; the Harness prints its path so it can be inspected and removed after debugging. See the [Harness specification](specs/harness.md) for its behavioral contract.

## Local Codex test

```bash
codex plugin marketplace add "$(pwd)"
codex plugin add vibe-living@vibe-living
```

Restart the desktop app, review the hook definitions, and test in a new task. After changing an installed plugin, bump its semantic version or Codex cachebuster and reinstall it.

## Local Claude Code test

```bash
claude --plugin-dir "$(pwd)/plugins/vibe-living"
```

Use `/hooks` to inspect the plugin hooks.

## Release checklist

1. Update both plugin manifests to the same semantic version.
2. Update `CHANGELOG.md`.
3. Run `make clean check build package`.
4. Test the generated archive on a clean macOS user account.
5. Create a signed Git tag such as `v0.1.0`.
6. Attach the archive and checksums to the GitHub release.

The bundled binary is currently unsigned. Public distribution may require Apple code signing and notarization depending on how the release is packaged and downloaded.
