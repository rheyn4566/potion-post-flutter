# Potion Post 0.9.0 (19) validation

Flutter 3.47.6, Dart 3.13.5, Microsoft JDK 17.0.20.1. The dependency lock and test-edition signing identity are retained.

- Code analysis: no issues (docs/ANALYZE.txt).
- Full suite: 64 automated tests passed (docs/TEST_RESULTS.txt).
- Puzzle and persistence coverage: legal pours/solutions, earned-once rewards, daily bonuses, confirmed/cancelled purchases, locked story routes, original-save compatibility, recovery and separate-process disk persistence.
- Responsive UI: five tabs at 320x568, 360x640, 390x844, 844x390 and 758x1216, persistent banner/navigation bounds, no scrolling hub, garden/route state, paged friends, invitation/equip, motion/accessibility and puzzle-preserving resume.
- Artwork regressions: tall 72/220/480 logical-pixel cards retain square fixed-size ornaments; the Friends platform preserves its aspect ratio and fits fully within a loosely constrained scene at three sizes; Daily has exactly one continuous office image and tappable tickets at phone/tablet/landscape sizes; gameplay covers the complete viewport above the ad, including the status-bar area and wide-screen side areas.
- Android screenshot dimensions: actual Flutter captures at 1280x2048, density 2 and system insets, with all five tabs, Decor shop, order 7, Pause/resume and Delivery. The uploaded device's exact density was not supplied. Touch targets remain at least 48x48 logical pixels.
- Content: all 1,480 solution certificates replay legally and match shortest solution lengths; the restored source's original 1,000 order payloads and complete orders asset are unchanged. There are 43 contiguous garden routes and 26 unique character IDs/names/species. Eighteen additional distinct garden scene assets supplement Moonbloom; 43 routes do not imply 43 unique painted scenes.
- New actual widget captures: docs/ALIGNED_*.png, docs/POLISHED_SHOP.png and docs/POLISHED_DAILY_SMALL.png. Older captures are retained as project history.
- Release identity, signature, ZIP integrity, all five new bundled assets and 16 KB ZIP/native alignment are checked by scripts/verify_apk.py and recorded in docs/APK_BUILD.json after packaging.
- No physical Android device or emulator run was available. Host tests and package checks do not establish device performance or ad-network availability.
