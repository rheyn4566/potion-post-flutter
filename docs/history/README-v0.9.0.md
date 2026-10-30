# Potion Post

A local-first cozy bottle-pouring puzzle built with Flutter. Version **0.9.0+19** replaces the stretched illustrated frames with native paper/mint surfaces and fixed-size flower accents. Five individually generated assets refresh the continuous Daily office, full-screen potion workbench, Orders map, floral ornament and Friends stone platform.

The project contains **1,480 story orders, 43 garden routes and 26 animal characters**. The original 1,000 orders retain their IDs and complete puzzle payloads. Earned Coins, decorations, partial puzzles and daily routes retain the existing local save format. The persistent test-ad banner sits below the app Navigator.

See INSTALL_APK.md for installation and building; VALIDATION.md for current evidence; docs/POLISHED_UI.md and docs/POLISHED_ART_ASSETS.json for the new artwork and layout changes; docs/ART_INTEGRATION.md and docs/ART_ASSETS.json for garden/character coverage; docs/WOODLAND_UI.md for the UI; docs/ECONOMY.md for Coins; docs/ADMOB.md for demo ads.

## Build

Use Flutter 3.47.6 (Dart 3.13.5), Android SDK 36 and a full JDK 17 with javac. Android build tools 35.0.0 and 36.0.0, NDK 28.2.13676358 and CMake 3.22.1 support the current Android dependencies. Keep pubspec.lock and test-signing/potion-post-ads-test.jks to produce compatible test-edition updates. Set CI=true in automated environments to disable automatic cloud-host probing.

    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --release --flavor adtest

The test key is not a production Play upload key. Standard releases require the original standard-app key; the build will not substitute the Ads Test identity.
