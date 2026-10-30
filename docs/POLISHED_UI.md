# Proportional artwork and full-screen scenes — 0.9.0 (19)

The uploaded screenshots identified tall floral borders stretching, a flattened navigation strip and Friends platform, a basic Orders map, an inset Daily scene with a hard edge, and constrained gameplay scenery.

StoryFrame now paints its cream paper and mint button surfaces at the real widget size: gradients, rounded strokes, highlights, shadows and subtle grain are Flutter drawing operations. The generated floral clusters are separate fixed-size square images using BoxFit.contain. Tall shop panels cannot stretch the flowers. Navigation uses five independently laid-out native slots with live labels, selection, focus, press states and accessible touch targets.

Daily now uses a single continuous full-screen office painting, with the otter already naturally positioned behind the counter. Portraits, saved order states, progress, Play/Replay actions and bonus Coins remain live controls. Short screens use three compact, fully tappable tickets. Landscape uses a lower camera crop of the same painting.

The Friends stage uses the regenerated low stone platform at its natural 1024:392 aspect ratio inside a full-size scene container. The entire platform remains visible under loose Stack constraints. A soft elliptical contact shadow grounds the independent animated character without a rectangular gray capsule.

Orders uses a new woodland meadow/cottage/waterfall plate, with individually painted native stepping stones and real accessible route markers. Level IDs, locks, completion and selected garden state remain controlled by game data.

Gameplay places its cover-fit workbench image outside SafeArea and the 620-pixel control column, so the art fills the width and status-bar area on phones, tablets and landscape screens. Controls remain safe and the persistent test-ad banner remains below the Navigator. Cover fitting crops proportionally; images are never resized with independent horizontal/vertical factors.

## Selected image-generation briefs

Five assets were generated separately with the built-in image-generation tool. These are project illustration assets, not baked screenshots or clickable controls. No existing garden or character IDs were recreated.

| Asset | Selected generation brief | App asset |
| --- | --- | --- |
| Daily office | Portrait cozy woodland potion-post office; warm amber lanterns, mint/lilac foliage, expressive familiar otter holding a letter naturally behind the wooden counter; nearby purple potion; continuous composition and quiet lower area for live controls; no UI or lettering. | assets/scenes/daily-office-v3.webp |
| Workbench | Portrait cozy potion office with full-height environment, central window and open wooden tabletop for live bottles; detailed edges, warm lanterns, matching dimensional woodland style; no character, text or UI. | assets/scenes/potion-workbench-v3.webp |
| Orders map | Portrait woodland meadow route setting with cottage near the top, waterfall at right and open central path for live route markers; matching mint/lilac and golden lighting; no labels, UI or numbered nodes. | assets/scenes/woodland-route-v3.webp |
| Flower accent | Compact lilac and ivory flowers with dimensional green leaves, clean isolated silhouette and transparent background; suitable as one small corner ornament; no frame, panel, lettering or UI. | assets/ui/bloom-ornament-v3.webp |
| Friends platform | Low broad round stone platform in natural perspective, thick rounded stones and soft moss/lilac flowers; clean transparent silhouette, open top for a separate character, no upright monument or character. | assets/ui/companion-plinth-v3.webp |

The selected original output names, dimensions and app paths are recorded in POLISHED_ART_ASSETS.json. scripts/package_polished_art.py performs normal alpha-margin trimming and aspect-preserving WebP export from those originals. It does not repaint the generated art. Panels, navigation and route markers are code-native surfaces.

The full 64-test suite and clean analyzer output accompany the source. Actual app renders appear in ALIGNED_HOME, ALIGNED_DAILY, ALIGNED_GARDENS, ALIGNED_ORDERS, ALIGNED_FRIENDS, ALIGNED_GAMEPLAY, ALIGNED_PAUSE, ALIGNED_DELIVERY, POLISHED_SHOP and POLISHED_DAILY_SMALL PNGs.
