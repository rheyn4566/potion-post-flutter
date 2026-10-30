# Potion Post 0.10.0 (20)

The approved woodland concept is implemented as native Flutter widgets and separate scene/character assets. Text, bottles, buttons, tabs, rewards and purchase confirmations remain interactive widgets.

- Fixed Home, Daily, Gardens, Orders and Friends tabs share the persistent bottom test-ad shell.
- Animals have gentle idle movement in scenes; Reduce motion, TickerMode and app lifecycle stop idle animation.
- Cream panels, mint buttons, navigation and route markers are native painted surfaces without decorative flower clusters. Live Poppins labels, touch targets, focus and press states remain interactive.
- Daily orders show actual customer portraits, saved completion and the existing daily coin bonus over one continuous generated office scene. The courier is part of the scene behind the counter; short screens use compact tappable tickets.
- Gardens map 18 additional distinct illustrations to their actual route IDs. The paged collection supports previewing all 43 routes, with story locks and saved selected looks preserved. Moonbloom retains its sparse-to-bloom artwork; the new scenes support milestone light effects and purchased decorations.
- Orders use ten accessible route stops per page, preserving locked levels and the first unfinished story order.
- Friends support 26 characters, six portrait cards per page, full-body previews, previous/next companion controls, confirmed coin invitation and companion selection. The original otter stays Pebble; the new capybara is Basil.
- Gameplay retains the bottle-pouring engine, recipe meter, hint/undo quotas and motion, with a visible customer above the board. The new workbench backdrop fills the complete viewport above the persistent banner, outside control-width and SafeArea constraints.
- Delivery and Pause remain dialogs over the same puzzle, with the ad outside the Navigator.
- The economy and checksummed two-copy save format remain compatible with 0.6.8.

All source character names, IDs, coin prices, rewards, purchases and order locks come from the existing game controller. Monetary coin packs remain unavailable in this test build.

The current full-environment and tablet changes are documented in WORLD_SCENES.md. POLISHED_UI.md records the earlier proportional-art pass. ALIGNMENT_FIX.md records the previous 0.8.1 correction. The current panels and dock no longer use the older nine-sliced bitmap frames.

## Artwork

The earlier built-in image generation produced four project assets from the approved concept board: `woodland.webp`, `post-office.webp`, `garden-island.webp`, `garden-start.webp`. The PNG generation originals were encoded to WebP for the app. These are scene layers; the UI was not flattened into screenshots.

Scene prompt: enchanted woodland at blue hour, rounded potion cottage, amber lanterns, mint/lilac foliage, empty curved path for independent character sprites; no lettering, UI or animals.
Office prompt: cozy woodland postal service interior, broad wooden counter, potion parcels and envelopes, open central character placement, matching blue-hour and amber-light palette; no UI, letters or animals.
Island prompt: transparent miniature garden island, cottage, curved path, pond, flowers and lanterns, same dimensional painterly style; no characters or UI.
Starting-stage edit: preserve island camera/geometry and alpha; replace blooms with green seedlings and turn off window/lantern glow.

The app bundles all 26 optimized character cutouts. The leaf Coin icon extends the editable SVG icon system. See ART_INTEGRATION.md for the expanded scene/character mappings and ART_ASSETS.json for the packaged paths. There are no network image dependencies.

Five newer illustration assets and their generation briefs are listed in POLISHED_UI.md and POLISHED_ART_ASSETS.json.

The 0.10.0 world renderer, 19 full environments, grounded poses and selected generation prompts are documented in WORLD_SCENES.md and WORLD_ART_ASSETS.json.
