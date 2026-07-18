# Architecture

Vibe Living is deliberately small: lifecycle hooks update local session state, and one native macOS process renders the overlay. No server or account is involved.

## Event flow

| Event | State | User experience |
| --- | --- | --- |
| `SessionStart` | Prepare | Install and start the hidden native helper |
| `UserPromptSubmit` | Working | Start the six-second appearance timer |
| `PreToolUse` | Working | Refresh the active-session heartbeat |
| `PermissionRequest` | Waiting | Hide while user attention is required |
| `PostToolUse` | Working | Resume after the tool completes |
| `Stop` | Done | Remove the session and hide if no others are active |

## Components

- `hooks/hooks.json` registers the shared Codex and Claude Code lifecycle events.
- `scripts/hook.py` sanitizes session IDs, writes atomic JSON state, installs the helper, and enforces single-instance startup.
- `scripts/VibeLiving.swift` renders a borderless AppKit panel and polls local session state.
- `bin/vibe-living-<arch>` is the release helper for a supported architecture.
- `scripts/vibe-living` provides the source-build fallback.
- `harness/run.py` drives the real Hook entry point with synthetic lifecycle events in an isolated, daemon-free environment.

The native view selects Simplified Chinese when the first macOS preferred-language identifier begins with `zh`; all other and unknown identifiers fall back to English. Preview rendering can inject `zh` or `en` so committed assets remain deterministic.

## Runtime state

The host supplies a writable plugin data directory. Vibe Living stores:

- `sessions/<session-id>.json`: action, start time, and last heartbeat.
- `daemon.pid`: the current native helper process.
- `paused-until`: local pause expiry.
- `source.sha256`: helper/source compatibility marker.

Working sessions expire after 30 minutes without a heartbeat. Atomic file replacement prevents partial reads. A short exclusive startup lock prevents concurrent events from creating duplicate overlays.

## Privacy boundary

The hook adapter intentionally ignores prompt text, tool arguments, tool results, transcripts, working-directory contents, and repository files. Only `session_id` and the hook-selected state are retained locally. The implementation contains no networking code.

## Office-friendly movement boundary

The built-in catalog is limited to quiet, low-amplitude prompts that fit within one person's desk space and require no equipment. It excludes jumping, marching, deep squats, fast arm swings, and shared-walkway activities. Hydration prompts appear only as an optional suggestion when water is already within reach.

## Failure behavior

Every hook exits successfully even when the optional overlay cannot start. A wellbeing companion must never block, deny, alter, or prolong an agent action.
