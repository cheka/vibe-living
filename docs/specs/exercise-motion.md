# Exercise motion specification

## Context and problem

The seated-twist animation currently translates the head, neck, and both hands from side to side. This reads as lateral swaying instead of rotation around a stable spine. The wrist-relaxation animation moves both hand endpoints vertically but does not show a stable wrist joint or finger relaxation.

Both corrections must remain visually indistinguishable from the rest of the movement catalog: the same pixel figure, overlay environment, dimensions, line treatment, and colors must be reused.

## Scope

- Refine only the `seatedTwist` and `wristStretch` drawing branches.
- Keep the seated figure's pelvis, feet, head center, and torso center fixed during a seated twist.
- Convey seated rotation with a low-amplitude change in shoulder perspective, naturally bent arms held in front, and face direction around the fixed body axis.
- Keep the seated-twist upper arms and forearms visually distinct; limb segments must not converge into a dense star-shaped intersection over the chest.
- Keep the arms and wrist locations stable during wrist relaxation.
- Convey wrist and finger relaxation with small, asynchronous rotations at the wrist and finger joints.
- Reuse the existing pixel-line helper, figure proportions, mint movement color, dark overlay, border, typography, and timing.

## Non-goals and safety boundaries

- Do not redesign the figure, overlay, scene, palette, copy, or exercise order.
- Do not change the other three exercise animations.
- Do not add fast shaking, large arm swings, equipment, or movement outside one person's desk space.
- Do not make medical or health-outcome claims.

## Acceptance criteria

- The seated-twist head and pelvis centers do not translate horizontally or vertically.
- The seated-twist feet remain fixed while the shoulders, bent arms, and face visibly alternate between left and right rotation.
- The seated-twist elbows remain outside the torso and both hands remain near the center without the two arm paths crossing into a solid block.
- The wrist-relaxation forearms and wrist anchors remain fixed.
- Hand and finger motion is small, smooth, and slightly asynchronous rather than a synchronized vertical bounce.
- Both animations retain the same figure geometry, pixelated line style, environment, and colors used by the existing catalog.
- With macOS Reduce Motion enabled, the deterministic static phase remains valid and recognizable.
- Existing lifecycle, localization, and timing behavior remains unchanged.

## Verification

- Run `make check` and the local Harness.
- Rebuild the bundled helper after changing `VibeLiving.swift`.
- Render deterministic previews for multiple phases of `seatedTwist` and `wristStretch` in both Simplified Chinese and English.
- Visually compare the previews with the unchanged shoulder-roll, posture-reset, and hydration frames for consistent figure proportions, pixel style, environment, and color.
