# Overlay localization specification

## Problem

The repository documentation is bilingual, but the native overlay currently embeds Simplified Chinese copy. Users whose macOS environment is not Chinese need the movement name, guidance, and controls in English without manually configuring the plugin.

## Scope

Vibe Living must provide two complete overlay languages:

- Simplified Chinese (`zh`);
- English (`en`), which is also the fallback language.

At native-helper startup, the overlay reads the first value from `Locale.preferredLanguages`:

- a language identifier beginning with `zh` selects Simplified Chinese;
- every other value, an empty list, or an unrecognized identifier selects English.

The overlay displays one language at a time. It must not place Chinese and English copy side by side because the compact panel should remain readable.

## Localized copy

Language selection applies to every user-facing overlay string:

- header action label after the `VIBE LIVING` brand;
- all movement names;
- all movement guidance;
- hydration reminder;
- pause control.

The `VIBE LIVING` brand name remains unchanged in both languages.

## Preview behavior

The preview command must accept an explicit `zh` or `en` override so committed screenshots are deterministic and do not depend on the developer machine's language. Production startup must continue to use the macOS preferred language when no override is supplied.

The repository must include Chinese and English previews for both a movement prompt and the hydration reminder.

## Accessibility and layout

- English and Chinese text must fit inside the existing 280 × 244 point panel without overlapping the figure, border, or pause control.
- Existing Reduce Motion behavior is unchanged.
- Language selection must not require network access, telemetry, or access to agent content.
- Changing the macOS preferred language takes effect the next time the native helper starts.

## Acceptance criteria

1. A `zh` language selection renders Chinese header, movement, guidance, hydration, and pause copy.
2. An `en` language selection renders English equivalents for the same strings.
3. A non-Chinese or unknown locale falls back to English.
4. Production language selection uses `Locale.preferredLanguages.first`.
5. Preview generation produces four assets: Chinese movement, English movement, Chinese hydration, and English hydration.
6. Swift type-checking, the lifecycle Harness, repository validation, and plugin validation pass.
7. Both plugin manifests use the same updated semantic version.

## Non-goals

- Showing two languages simultaneously.
- Providing an in-overlay language picker.
- Supporting Traditional Chinese or additional languages in this release.
- Changing movement timing, lifecycle Hooks, or office-friendly movement policy.
