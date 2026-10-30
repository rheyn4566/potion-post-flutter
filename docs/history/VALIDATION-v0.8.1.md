# Potion Post 0.8.1 (18) validation

Flutter 3.47.6, Dart 3.13.5. The existing dependency lock and test-edition signing identity are retained.

- Code analysis: no issues.
- Full suite: 60 automated tests passed.
- Covered: puzzle solutions and pours, earned-once rewards, daily bonuses, confirmed/cancelled purchases, locked story routes, original-save compatibility, recovery and separate-process disk persistence.
- UI coverage: all five tabs on 320x568, 360x640, 390x844, 844x390 and 758x1216; banner/navigation bounds; no scrolling hub; garden/route state; paged friend choices; invitation/equip; motion/accessibility; dialog resume without changing the puzzle.
- Expansion checks: 43 contiguous routes, 26 unique character IDs/names/species with bundled art, 18 distinct additional scene assets, locked garden previews, short-screen collection dialogs and a new companion invitation/equip flow.
- Alignment regression: valid nine-slice source bounds and opaque painted faces at display density 2.75; all five tabs, order 7, Pause/resume and Delivery at the uploaded 1280x2048 image dimensions with density 2 and system insets. The actual device density was not supplied. Navigation labels remain within touch areas of at least 48x48 logical pixels.
- All 1,480 solution certificates replay legally and match the shortest solution lengths. The recovered archive's original 1,000 order payloads were compared directly and are unchanged.
- Captured actual Flutter widget renders in docs/ALIGNED_*.png, docs/WOODLAND_*.png, docs/INTEGRATED_*.png, docs/GARDEN_GAMEPLAY.png and docs/ADS_DELIVERY_LAYOUT.png.
- Android release package verification is recorded in docs/APK_BUILD.json after the native build.
- No physical Android device or emulator was available. These checks do not establish device performance or ad-network availability.
