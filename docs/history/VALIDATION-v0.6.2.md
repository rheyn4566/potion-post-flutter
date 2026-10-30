# Validation — Potion Post 0.6.2

Android version 0.6.2, code 9.

## Native UI and gameplay checks

- Flutter analysis: **No issues found**.
- **All 19 native Flutter tests passed** against the final source, with real
  bundled Poppins fonts and artwork. The suite includes 1,000 shortest solution
  certificates, **80,000 randomized pours**, recovery hints and **4,122
  controller assertions** across the campaign.
- The active puzzle fits 320×568, 360×640, 390×844, 390×1000, 758×1216 and
  800×1280 portrait viewports, plus 844×390 landscape. New regression assertions
  keep recipes close to the prompt, bound the row gap and keep bottles clear
  of the tool buttons. No scrolling or render exceptions occurred.
- Four-layer and five-bottle puzzles also pass at 758×1216. Existing tutorial,
  selection/lift/flight/stream, Undo, Hint, delivery, navigation, garden atlas,
  friend album, order 1,000 and daily transition checks pass.
- Native captures of the reported large portrait viewport, three-recipient
  puzzles, standard phones, a small phone and landscape were visually reviewed.
  The header is compact; the star target uses words rather than a math symbol.
- Puzzle rules, save controller, bottle flight calculations, all 1,000 order
  records and the test keystore are unchanged from 0.6.1. Existing progress
  compatibility and storage ordering checks remain green.

## Android build and artifact checks

- Optimized universal release-mode APK built with Flutter 3.47.6 / Dart 3.13.5,
  JDK 17, Android SDK 36, Gradle 8.14.3, AGP 8.11.1 and Kotlin 2.2.20.
  Build dependency checks remained enabled.
- App ID **com.castilla.potion_post**, version **0.6.2**, code **9**,
  minimum API **24**, target **36**. ABIs: arm64-v8a, armeabi-v7a and x86_64.
- APK Signature Scheme **v2** verifies with the same test certificate as the
  previous APKs. Install as an update to retain local progress.
- ZIP CRC integrity, **16 KB ZIP alignment** and all native load-segment
  alignments passed.
- Packaged assets match the source: all 1,000 orders are unchanged, all ten
  couriers, 31 gardens with 124 PNG decoration stages and Poppins fonts are
  present. No keystore is packaged inside the APK.

## Deliverables

- APK: potion-post-test.apk
- Bytes: 83148206
- SHA-256: 1f7a80e4399be188277e5fd16229d16111c86b553653a7b86c3c6c1cfa307f76
- Signer SHA-256: 22ab2010b764e18662d6f06f60b209ad7475310cba81230cfb4d6ab931f3743e
- Native gameplay preview: docs/COMPACT_GAMEPLAY.png and the separately supplied
  potion-post-gameplay-preview.png. This is a capture from the real Flutter
  widget tree. The prior home capture remains in docs/BENTO_HOME.png.
- Build details: docs/APK_BUILD.json. Layout changes: docs/UI_COMPACT.md.

## Practical limits

This APK has not been installed on a physical Android phone or emulator here.
The checks use Flutter's native test runner and memory save storage; device
plugin behavior still needs a phone check. AdMob and production Play Store
signing remain unconfigured. No production AAB or iOS binary is included.
The archived HTML preview remains the old 80-order version.

Repeat: flutter pub get, flutter analyze, flutter test, then
flutter build apk --release. Historical validations describe earlier builds.
