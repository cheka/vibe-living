# Local Harness specification

## Problem

Lifecycle-hook behavior currently depends on launching Codex or Claude Code for end-to-end testing. Contributors need a fast, repeatable environment that exercises the real hook entry point without opening the overlay, touching persistent plugin data, or requiring an installed host application.

## Scope

The repository must provide a local Harness that:

- runs with the macOS system Python and no third-party packages;
- invokes the real `plugins/vibe-living/scripts/hook.py` command-line entry point;
- uses a fresh temporary plugin-data directory for every run;
- disables daemon and GUI startup explicitly while preserving state transitions;
- simulates the lifecycle sequence `session → working → waiting → working → done`;
- verifies session-ID sanitization, state creation, action transitions, start-time preservation, and cleanup;
- produces a concise pass/fail summary and a non-zero exit code on failure;
- removes temporary state by default, with an option to preserve it for debugging.

## Interface

Required commands:

```bash
make harness
python3 harness/run.py
python3 harness/run.py --keep --verbose
```

`make check` and CI must run the headless Harness. The existing `make preview` command remains the visual Harness for generated overlay assets and must not be required on non-interactive test runs.

## Isolation and safety

- The Harness must never read or write the user's installed Vibe Living data directory.
- The Harness must never launch a persistent daemon or floating window.
- Harness-only behavior is enabled through an explicit environment variable set by the Harness process.
- Production behavior must remain unchanged when that variable is absent.
- Test input contains only synthetic session metadata and no repository or prompt content.

## Acceptance criteria

1. `make harness` completes without Codex, Claude Code, or network access.
2. A synthetic session ID containing spaces and path separators is stored under a sanitized filename.
3. `working → waiting → working` preserves the first `startedAt` value.
4. `done` removes the session-state file.
5. No `daemon.pid`, daemon-start lock, or installed helper is created in the Harness data directory.
6. `make check` invokes the Harness and succeeds when all assertions pass.
7. The development guide documents the Harness commands and failure-inspection workflow.

## Non-goals

- Automating Codex or Claude Code UI installation.
- Pixel-perfect screenshot comparison.
- Medical or movement-quality validation.
- Launching the production overlay in CI.
