# Validation — Potion Post 0.5.1

Verified on 15 October 2026. Android APK version 0.5.1, build 6.

## Completed

- Flutter analysis: **no issues found**.
- **All 16 native Flutter tests passed**, including real Poppins fonts and art,
  animated pouring and target-mouth alignment, tutorial and navigation,
  home/game phone and landscape layouts, four-layer recipes, and legacy saves.
- All 80 authored puzzles have legal shortest solutions at the listed par.
  Randomized pours conserve inventory and hints recover valid routes.
- The expanded controller harness passed **387 assertions**, including eighty
  unlocks, replay protection, friend claims, daily bonuses, streaks and imports.
  The native run uses the real Flutter foundation library and memory storage;
  the earlier offline adapter results are retained in history.
- **Android release-mode APK compiled successfully** with the included test
  signature, using Flutter 3.47.6 / Dart 3.13.5, JDK 17, Gradle 8.14.3,
  Android Gradle Plugin 8.11.1, Kotlin 2.2.20 and Android SDK 36.
- APK signature verified with Android apksigner. APK Signature Scheme v2 is
  valid for the minimum supported Android API 24.
- APK ZIP integrity and 16 KB native-library page alignment checks passed.
- Packaged content was inspected: 80 orders; Poppins fonts; all eight gardens
  and their 24 earned decoration stages; native app/engine libraries for
  arm64-v8a, armeabi-v7a and x86_64. The private test key is not in the APK.
- Android manifest reports Potion Post, com.castilla.potion_post, version
  0.5.1 / code 6, minimum API 24 and target API 36.

## Build repair

The older Gradle 8.12 / AGP 8.9.1 / Kotlin 2.1.0 Android setup could not build
with this Flutter SDK. The project now uses the supported versions listed
above. The original application ID, version-one save key, story IDs and first
thirty recipes are retained. Version 0.5.1 updates build configuration; the
eighty-order Flutter game code is the version tested above.

## Artifact

- Filename: potion-post-test.apk
- Bytes: 63276520
- SHA-256: b50bc85243efc4b52c62b4693ece72e481613f2676f16721943dbff5ac4276e3
- Test signer SHA-256: 22ab2010b764e18662d6f06f60b209ad7475310cba81230cfb4d6ab931f3743e

Detailed machine-readable results are in docs/APK_BUILD.json.

## Remaining release work

Physical Android phone/emulator testing has not been performed here. The APK
is supplied for phone testing. AdMob, production upload signing and Play Store
submission remain unfinished. iOS and web release compilation were not part
of this build. Historical validation files describe their own earlier versions.

## Repeat

With the recommended Flutter 3.47.6 / JDK 17 development toolchain:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The included test-only keystore preserves the identity of subsequent local
test builds. Its standard debug password is documented under test-signing/.
Production uploads require your own upload key and release signing config.
