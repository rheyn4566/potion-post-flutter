# Validation: Potion Post 0.11.0+22

The Flutter analyzer reports no issues. All 79 host tests passed, including every existing save, economy, route, puzzle, loading-cache and visual-layout regression, plus new level sizing, functional settings, banner visibility and short-screen celebration checks. See docs/ANALYZE.txt and docs/TEST_RESULTS.txt.

The new tests exercise 150px tablet banners, 50px compact-phone banners, and a conservative 78px landscape fixture across all five destinations; unloaded/no-fill banners occupy no space; toggling banner visibility retains the game route and mounts exactly one placement. Tablet level controls and map stops have meaningful minimum sizes. Settings switches update saved controller preferences and remain closable at 320×568 and 844×390. Next/Home stay reachable on the delivery popup at both sizes and with reduced motion. Optional rewarded actions never start automatically.

Actual game renders were inspected at 640×1024 logical tablet size for Home, level map, Settings and delivery. Existing tests also cover the uploaded screenshot densities and phone/landscape layouts. Captures in docs/RELEASE_TABLET_*.png are host-rendered implementation screens with a simulated banner frame; they are not Android screenshots or proof of live ad delivery.

The game controller, all domain and persistence files, all 1,480 orders, pubspec.lock, native save bridge and update keystore are byte-identical to source version 20, recorded in docs/RELEASE_COMPATIBILITY.json. No save migration or economy alteration is required.

The signed APK is verified after building with scripts/verify_apk.py. docs/APK_BUILD.json records identity, version, real launcher label, SDK target, signature certificate, ZIP CRCs, 16KiB ZIP/native alignment, packaged artwork and SHA-256. The outer installer ZIP is checked to contain the byte-identical APK.

No physical Android device, emulator or live publisher ad unit was used in this environment. Real on-device performance/ad callbacks and Play internal-track testing remain necessary before publication.
