# Validation — Potion Post 0.6.1

Verified 18 October 2026 (Asia/Manila). Android version 0.6.1, code 8.

## Native UI and gameplay checks

- Flutter analysis: **No issues found**.
- **All 19 native Flutter tests passed** against the final source, with real
  bundled Poppins fonts and artwork. This includes all 1,000 shortest solution
  certificates, **80,000 randomized pours**, recovery hints and **4,122
  controller assertions** across the entire campaign.
- The updated bento grid fits 320×568, 360×640 and 390×844 phones and 844×390
  landscape. Home and active puzzles do not scroll. Home action bounds, tutorial,
  bottle selection/lift/flight/stream, Undo, Hint, delivery and navigation pass.
- Four-layer recipes, five-bottle puzzles, the garden atlas, route pages, friend
  album, final order 1,000 and transition into daily orders pass their existing
  widget checks. Locked level buttons remain disabled.
- Real native captures of Home at small/large sizes, landscape, puzzle controls,
  level selection and friend rewards were visually inspected. One status-plate
  height mismatch found during review was corrected and the full suite rerun.
- The button component supports keyboard focus and uses both the system and
  in-game reduced-motion setting for press animation. Disabled controls have
  no activation callback.
- Puzzle rules, pour motion, save controller, storage key, reward catalog, all
  1,000 puzzle records and the test keystore are byte-for-byte unchanged from
  the recovered 0.6.0 source. Existing save migration checks remain green.

## Android build and artifact checks

- Optimized universal release-mode APK compiled with Flutter 3.47.6 /
  Dart 3.13.5, JDK 17, Android SDK 36, Gradle 8.14.3, AGP 8.11.1 and Kotlin
  2.2.20, with build dependency checks enabled.
- App ID **com.castilla.potion_post**, version **0.6.1**, code **8**,
  minimum API **24**, target **36**. ABIs: arm64-v8a, armeabi-v7a and x86_64.
- APK Signature Scheme **v2** verifies with the same test certificate as the
  previous test APKs. Install as an update to retain local app progress.
- ZIP CRC integrity and **16 KB ZIP/native-library alignment** passed.
- Packaged assets match the source: all 1,000 orders are unchanged, all ten
  couriers, 31 gardens with 124 PNG decoration stages and the Poppins fonts
  are present. No keystore is packaged inside the APK.

## Deliverables

- APK: potion-post-test.apk
- Bytes: 83148206
- SHA-256: 6b02efe06b8574f0d16638517dc5202b7607000ed298d56f2cffffc8d002caa1
- Signer SHA-256: 22ab2010b764e18662d6f06f60b209ad7475310cba81230cfb4d6ab931f3743e
- Native home preview: docs/BENTO_HOME.png and the separately supplied
  potion-post-bento-preview.png. These are captures of the real Flutter widget
  tree, not generated design mockups.
- Build details: docs/APK_BUILD.json. UI changes: docs/UI_BENTO.md.

## Practical limits

This build has not been installed on a physical Android phone/emulator here.
The tests use Flutter's native test runner and memory save storage; device
plugin behavior still needs the user's phone check. AdMob and production
Play Store signing remain unconfigured. No production AAB or iOS binary is
included. The archived HTML preview remains the old 80-order version.

Repeat: flutter pub get, flutter analyze, flutter test, then
flutter build apk --release. Historical validations describe earlier builds.
