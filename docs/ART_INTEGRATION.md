# Illustrated asset integration — 0.8.0+17

The app packages the artwork as independent transparent scene, character and control layers. Buttons, labels, progress, dialogs and collection choices are functional Flutter widgets. The existing Coins economy, daily pool, original puzzle payloads and save IDs are preserved.

## Coverage

- 26 unique character species, IDs and display names; 16 added to the original ten.
- 19 distinct garden scene illustrations: original Moonbloom, six refreshed existing gardens and twelve additional themes. The other 24 legacy looks retain the existing scenery/palette renderer.
- 43 garden routes and 1,480 playable story orders. Each added route has 40 new certified puzzles.
- Transparent illustrated panel, button, navigation, badge, wallet and stone-step assets in `assets/ui/`.
- Full-body character assets in `assets/characters/*.webp`; close portrait crops in collection cards and daily tickets.
- The sloth alpha was checked by compositing on a checkerboard. The diffuse RGB outside the body is transparent in the packaged asset.

Six existing route scenes refreshed: Lily Pond, Sunpetal, Starlit Grove, Frostfern, Amber Orchard and Coral Cove. Their route IDs and level ranges are unchanged.

| Added garden | Story orders | Main courier |
| --- | --- | --- |
| Lanternleaf Conservatory | 1001–1040 | Tula the turtle |
| Copperwind Millgarden | 1041–1080 | Tobin the beaver |
| Cactus Crescent | 1081–1120 | Prism the chameleon |
| Cloudberry Airpost | 1121–1160 | Echo the bat |
| Porcelain Teacourt | 1161–1200 | Koa the koala |
| Emberglow Springs | 1201–1240 | Basil the capybara |
| Honeycomb Haven | 1241–1280 | Bram the badger |
| Rootcellar Retreat | 1281–1320 | Acorn the squirrel |
| Pumpkin Lantern Patch | 1321–1360 | Button the mouse |
| Raindrop Roofgarden | 1361–1400 | Puddle the duck |
| Saffron Spiceyard | 1401–1440 | Fennel the ferret |
| Ribbonwind Festival Garden | 1441–1480 | Fern the deer |

Additional guest couriers include Maple the red panda, Nori the axolotl, Winnie the penguin and Mellow the sloth. Basil has a distinct ID and name, preserving Pebble the existing otter.

## Asset preparation

`scripts/integrate_art.py` extracts the supplied atlas regions, preserves their alpha and packages the approved artwork into WebP. `lib/ui/scene_catalog.dart` and `docs/ART_ASSETS.json` record the resulting paths and source dimensions. The app's bundled assets are sufficient for ordinary Flutter builds; re-running the preparation script requires the original artwork export folder.

The built-in Imagegen tool was used for the sloth background-extraction edit in this integration session. Its final packaged path is `assets/characters/sloth.webp`. The leaf Coin was rendered from the editable native SVG at `assets/icons/coin-leaf.svg`.

Current-session extraction prompt: “Use case: background-extraction. Asset type: transparent game character sprite. Edit target: the supplied sloth courier. Keep the sloth's friendly face, teal cardigan, cream envelope with lilac ribbon, brown satchel and complete body. Extract ONLY the physical character and the objects it is holding. Completely remove the surrounding hazy brown and teal halo, every colored glow behind the silhouette, and the floor shadow. Every pixel outside the fur, clothing, bag, envelope and feet must be genuinely transparent alpha 0. Soft fur-edge antialiasing only within a very narrow edge. Do not retain a haze, vignette, drop shadow, surrounding glow or any background whatsoever. Center the clean isolated full-body sloth with clear transparent margin. No new objects, words or interface.”

New garden art depicts each garden's illustrated layout; delivery stages add light motes and persistent purchased decorations. Individual plant-by-plant growth variants for those scenes are a separate art set.
