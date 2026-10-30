# Potion Post 0.10.1 (21) validation

Flutter 3.47.6, Dart 3.13.5, Microsoft JDK 17.0.20.1. The dependency lock and Ads Test signing identity are retained.

- Full suite: 74 tests passed (docs/TEST_RESULTS.txt). Analysis: no issues (docs/ANALYZE.txt).
- New checks: cold launch holds the initial screen until artwork is decoded; navigation retains the outgoing scene until the requested art is ready; older loads cannot replace a newer destination; completion after disposal is harmless; Reduce Motion removes the fade/slide.
- Actual cleared-cache tablet check at 1280x2048, density 2: every visible RawImage was decoded before its destination was revealed across all five tabs. Cache occupancy stayed between 51,956,388 and 55,306,916 bytes under the unchanged 104,857,600-byte cache limit. This is a Flutter host image-cache measurement, not total physical Android RAM. Details: docs/LOADING_CACHE.json.
- Tablet rotation and window resizing during scene loading do not retain an overflowing layout. Existing phone, tablet, landscape, screenshot-dimension and safe-area layout tests pass.
- The test harness exercises production preloading under the normal cache budget. It no longer precaches every illustration in a 600 MiB cache.
- Existing puzzle, animated pour, recipe meter, reward-once, daily bonus, shop purchase/cancel, route locks, garden previews, friend invitations, save recovery and separate-process persistence checks pass.
- Original controller, domain, persistence, orders JSON and dependency-lock bytes match source version 19 (docs/LOADING_COMPATIBILITY.json). The game retains 1,480 orders, 43 routes and 26 courier identities.
- The shared world camera, 19 environment paintings, all 26 world poses, ordinary controls without decorative flower clusters, full-screen gameplay and persistent test-ad shell are retained.
- The release application ID, version 0.10.1+21, existing update certificate, ZIP CRCs, all 45 world/pose asset bytes and 16 KB ZIP/native alignment passed scripts/verify_apk.py. Current package size and SHA-256 are recorded in docs/APK_BUILD.json.
- Current PNGs are actual Flutter host renders. No physical Android or emulator run was performed; frame timing and performance on the user's tablet remain to be tested.

See docs/SMOOTH_LOADING.md for implementation and loading behavior.
