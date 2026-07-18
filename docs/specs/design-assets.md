# Design asset management specification

## Context and problem

Formal visual resources must be reproducible from a repository checkout. A runtime asset, published screenshot, or documentation image that exists only in a temporary directory can be lost, cannot be reviewed, and may make packaged output differ from the approved design.

Vibe Living currently draws its animated figure procedurally. The Swift source and bundled helper are therefore the authoritative animation resources. Raster previews and any future image, vector, font, audio, or similar design files require explicit repository ownership.

## Scope

- Store every file-based design resource used at runtime under `plugins/vibe-living/assets/`.
- Store every local image published by plugin metadata or official Markdown documentation in the repository.
- Declare every file under `plugins/vibe-living/assets/` in `plugins/vibe-living/assets/manifest.json` with its purpose.
- Keep procedural visual design in tracked source code and rebuild the tracked bundled helper when that source changes.
- Validate design-resource location, declaration, existence, and Git tracking during `make check`.

## Non-goals

- Temporary visual-regression frames may remain outside the repository when they are used only for local inspection and are not referenced by runtime code, plugin metadata, release material, or documentation.
- Generated build intermediates do not become formal design resources unless they are bundled or published.
- This specification does not change the visual style or runtime behavior of the overlay.

## Acceptance criteria

- Every design file under the plugin is located in `plugins/vibe-living/assets/` and declared in the asset manifest.
- Every declared asset exists and is tracked or staged in Git.
- Every local image referenced by official Markdown files exists and is tracked or staged in Git.
- Every screenshot declared in plugin metadata is present in the asset manifest.
- `make check` fails with an actionable error when any of these conditions is violated.
- Procedural animations remain fully represented by tracked Swift source and the bundled helper binary.

## Verification

- Run `make check` with the complete asset manifest staged.
- Confirm `tools/validate.py` reports missing, unlisted, misplaced, or untracked resources.
- Confirm the packaged plugin contains the declared asset directory and bundled helper.
