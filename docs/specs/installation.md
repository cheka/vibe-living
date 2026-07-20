# Installation documentation specification

## Context and user problem

People arriving from the public GitHub repository need copy-and-paste instructions that install Vibe Living without requiring knowledge of the repository owner, plugin layout, or lifecycle hooks. The previous README used placeholder repository names and did not explain how to confirm that the plugin was working.

## Scope

- State the supported operating system, host applications, and architecture-specific prerequisites before the installation commands.
- Provide exact public-repository commands for a persistent Codex installation.
- Provide an exact, clearly labeled one-session Claude Code trial command.
- Explain the expected first-run behavior and how to update or remove the Codex installation.
- Provide local-development commands and concise troubleshooting for common first-run issues.
- Keep the English and Simplified Chinese READMEs equivalent.

## Non-goals

- This documentation change does not add support for another operating system or host application.
- It does not turn the repository into a persistent Claude Code marketplace.
- It does not change lifecycle behavior, privacy boundaries, movement content, or plugin packaging.

## Acceptance criteria

- A user can copy the public Codex commands without editing placeholders.
- A user can distinguish persistent Codex installation from temporary Claude Code loading.
- The verification steps mention the six-second delay and that the overlay hides when user input is required.
- Update, uninstall, local-development, and first-run troubleshooting instructions use commands supported by the current project layout.
- `README.md` and `README.zh-CN.md` contain the same installation guidance in their respective languages.

## Verification

- Check the documented Codex commands against `codex plugin ... --help`.
- Check every path and plugin selector against `.agents/plugins/marketplace.json` and the plugin manifests.
- Confirm that no repository-owner placeholders remain in either README.
- Run `make check`.
