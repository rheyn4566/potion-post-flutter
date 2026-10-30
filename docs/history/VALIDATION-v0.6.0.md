# Validation — Potion Post 0.6.0

Verified on 15 October 2026. Android version 0.6.0, version code 7.

## Native checks completed

- Flutter analysis: **No issues found**.
- **All 19 native Flutter tests passed** with real bundled fonts and artwork.
- All 1,000 orders have legal solution certificates at the shortest listed par.
  Inventory and immutability checks passed after **80,000 randomized pours**;
  A* hints then recovered a solution for every resulting board.
- The authoring generator rejects structural duplicates even under color
  renaming, swapping recipient bottles together with their target recipes,
  and swapping spare bottles. The original 80 records are preserved exactly;
  all 920 additional structures are unique against that set and one another.
- **4,122 controller assertions** cover playing the entire 1,000-order journey,
  sequential unlocks, replay protection, all ten friends' six reward tiers,
  daily bonuses, streaks and progress export/import.
- Save regression coverage includes the original ten-, thirty- and eighty-order
  saves, partial boards and undo history. The prior eighty-order installation
  opens Clover Meadow at order 81, preserving currency and friend claims.
- A delayed-storage test verifies that in-flight writes remain ordered and
  pending writes coalesce into the latest state, including an undo and settings.
- Home and puzzle layouts fit 320×568, 360×640, 390×844 and 844×390 viewports
  without scrolling. Four-layer and five-bottle/three-recipient puzzles fit
  their phone and landscape cases. Tutorial, lift/pour/stream, Undo, Hint,
  delivery, garden paging, atlas navigation, friend album, level 1,000 delivery
  and transition into daily orders passed their exercised widget flows.
- Native widget captures of home, active puzzles, pouring, new gardens, the
  final route picker and new friend cards were visually inspected. Courier
  assets preserve genuine transparent alpha. Palette symbols use dark ink
  for legibility on light liquids.

## Android artifact checks completed

- Optimized universal release-mode APK compiled successfully.
- Application ID: **com.castilla.potion_post**; minimum API **24**, target **36**.
- Version **0.6.0**, code **7**. Native ABIs: arm64-v8a, armeabi-v7a, x86_64.
- APK Signature Scheme **v2** verifies. The signer is the same test certificate
  as version 0.5.1, allowing an in-place test APK update without uninstalling.
- ZIP CRC integrity and **16 KB ZIP alignment** passed. Every native library's
  PT_LOAD segment alignment is at least 16 KB.
- Packaged orders match the current source: **1,000 orders**, original 80
  unchanged, **10 couriers**, **31 gardens / 124 PNG decoration stages**, and
  all Poppins font weights. The signing keystore is absent from the APK.

## Build and artifact

Flutter 3.47.6 / Dart 3.13.5, JDK 17.0.20.1, Android SDK 36,
Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20. Dependency checks were enabled.
Flutter emits advance support-drop warnings for these currently accepted
Android tool versions; a future Flutter upgrade will need corresponding tools.

- Filename: potion-post-test.apk
- Bytes: 83131758
- SHA-256: cee7380adcfa64d5e1d5968274068a67877b8dc5674ccc048facad41df9a2e10
- Signer SHA-256: 22ab2010b764e18662d6f06f60b209ad7475310cba81230cfb4d6ab931f3743e

The complete build report is docs/APK_BUILD.json. Reproduce the source checks
with flutter analyze and flutter test, then run flutter build apk --release.

## Practical limits

This version has not been installed on a physical Android phone or emulator
in this environment. The user tested the prior version successfully. Widget
checks exercise the real Flutter implementation; in-memory save checks do not
exercise Android's shared_preferences plugin on a device. Install this APK to
check the updated experience on your phone.

AdMob, production Play Store signing and store submission remain unconfigured.
No AAB or iOS binary was generated. The archived HTML preview remains the
80-order prototype; this validation applies to the updated native source/APK.
