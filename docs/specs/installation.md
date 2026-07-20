# Installation documentation specification

## Context and user problem

People arriving from the public GitHub repository need copy-and-paste instructions that install Vibe Living without requiring knowledge of the repository owner, plugin layout, or lifecycle hooks. Claude Desktop users also need a graphical installation path that clearly identifies which Desktop surface can run Vibe Living's local lifecycle hooks.

## Scope

- State the supported operating system, host applications, and architecture-specific prerequisites before the installation commands.
- Provide exact public-repository commands for a persistent Codex installation.
- Publish a Claude plugin marketplace catalog at `.claude-plugin/marketplace.json` with the same plugin identity, source directory, and version as the shipped Claude manifest.
- Document graphical installation for macOS Claude Desktop Code sessions using the Local environment.
- Provide terminal commands for persistent Claude Code installation and an exact, clearly labeled one-session development command.
- Explain the expected first-run behavior and how to update or remove each persistent installation.
- Provide local-development commands and concise troubleshooting for common first-run issues.
- Keep the English and Simplified Chinese READMEs equivalent.

## Non-goals

- This change does not add support for another operating system or host application.
- It does not claim support for Claude Desktop Chat, Cowork, Remote, cloud, or WSL sessions; Vibe Living requires lifecycle hooks executing on the user's Mac.
- It does not submit Vibe Living to an Anthropic-managed marketplace.
- It does not change lifecycle behavior, privacy boundaries, movement content, or plugin packaging.

## Acceptance criteria

- A user can copy the public Codex commands without editing placeholders.
- Claude recognizes the public repository as a marketplace and can persistently install `vibe-living@vibe-living`.
- A Claude Desktop user can identify the Code tab, Local environment, and plugin-manager controls needed for installation without installing the standalone CLI.
- A user can distinguish persistent Codex and Claude installation from temporary local plugin loading.
- The verification steps mention the six-second delay and that the overlay hides when user input is required.
- Update, uninstall, local-development, and first-run troubleshooting instructions use commands supported by each host and the current project layout.
- `README.md` and `README.zh-CN.md` contain the same installation guidance in their respective languages.

## Verification

- Check the documented Codex commands against `codex plugin ... --help`.
- Validate `.claude-plugin/marketplace.json` against the Claude plugin manifest and require that its plugin source resolves to the shipped plugin directory.
- Check every path and plugin selector against both marketplace catalogs and the plugin manifests.
- Confirm that no repository-owner placeholders remain in either README.
- Run `make check`.
