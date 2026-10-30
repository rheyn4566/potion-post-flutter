# Garden worlds and tablet composition — 0.10.0 (20)

The tablet screenshots showed an isolated garden miniature over another garden, oversized animals, and repeated flower decorations across the interface. This pass replaces that composition in the actual Flutter app.

## Scene integration

Home and Gardens now render GardenWorld below the safe-area interface. WorldCamera uses one 1000x1500 design space and projects the environment, scenery props, contact shadows and foreground through one camera. The measured clear scene region supplies the camera focus; the painting covers the viewport without nonuniform scaling. Character sizes are capped for that clear region so short and wide windows retain usable controls.

Each active garden supplies its environment. Previewing another garden updates the preview world while the saved selected look remains unchanged until Use look is pressed. The 19 distinct environment IDs and remaining themed aliases are in lib/ui/world_art.dart. All 43 original garden IDs and their order ranges remain unchanged.

Foreground scenery reuses the same projected environment painting through a registered clip, avoiding a second background or a misaligned image seam. Native contact and cast shadows sit on the ground independently from the animal's subtle breathing transform. Foreground ground detail softens the contact edge. Purchased chimes, fountain and fireflies use defined positions in the same world space; later growth stages retain soft bloom lights.

The new Pip, Clover and Moss poses preserve their existing identities in standing three-quarter views. All 26 world-pose exports have transparent margins trimmed so feet have a consistent baseline. The remaining 23 poses reuse their original illustrations. Portraits and names are unchanged. Idle motion scales the upper body gently around the planted feet; it does not slide or bounce a still cutout as a walking cycle. Reduce motion, lifecycle and TickerMode are respected.

The stable environment image uses gapless playback when the selected scene changes. Static scenery is separated from the small animated character layers with repaint boundaries.

## Interface and tablet layout

Ordinary paper/mint controls, wallet, progress cards, navigation and route nodes have no decorative flower clusters. Flowers remain in the scenery and in icons that mean Garden. Native gradients, strokes, pressed states, focus and disabled states remain interactive.

The scene fills the tablet window, while action panels and the five-tab dock have their own maximum widths. Short windows use compact garden progress and thumbnails; wide windows place controls beside the scene. Home has a visible How to play action beside Play. The garden collection remains reachable through All gardens and preserves locked previews.

Friends is an explicit collection showcase with a subdued, blurred version of the selected environment, the existing natural-aspect stone dais and live companion selection. Gameplay keeps the full-screen workbench but uses a clear courier portrait card in place of a floating full-body cutout. Daily keeps its continuous office scene and live tickets, with the same quieter surfaces.

## Artwork and provenance

The built-in image_gen tool generated 19 full environment paintings and three standing animal poses for this pass. Amber Orchard, Cloudberry Airpost and Emberglow Springs were refined against their individual original references to preserve their themes. Only the selected variants are bundled.

WORLD_ART_ASSETS.json records the exact selected prompts, tool mode, source output paths, app paths, dimensions and export metadata. scripts/package_world_art.py performs alpha-margin trimming and aspect-preserving WebP encoding; it does not repaint illustration assets. The original generated PNGs are not required to build the app because all selected WebP exports are bundled under assets/worlds/.

Previous garden miniatures remain intentional collection/shop thumbnails. The old flower accent file remains available as a legacy asset but has no ordinary control call site.

## Research references

- [Tactile's Lily's Garden production pipeline](https://tactilegames.com/behind-the-curtains-what-it-takes-to-make-a-new-story-chapter-in-lilys-garden/): area art, object layering, character placement, lighting and animation integration.
- [Dream Games' Royal Match art direction](https://www.dreamgames.com/games/royal-match): consistent character/world/item shape language.
- [Flutter adaptive design guidance](https://docs.flutter.dev/ui/adaptive-responsive/best-practices): available-window layout, controlled widths and different form factors.

The implementation adapts those principles within the existing Flutter project. It adds no game-engine dependency or gameplay migration.
