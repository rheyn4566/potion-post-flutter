# Potion Post

A local-first cozy bottle-pouring puzzle built with Flutter. **Version 0.11.0+22** enlarges the home Level button, gameplay level title and map stops; introduces branded functional settings and a native delivery celebration; and refreshes the launcher artwork around Pip. Banner space appears only after a real SDK placement loads. Compact windows use a standard 320×50 SDK banner; larger portrait windows use adaptive sizing. Scene preloading, bounded decoding, full-screen scenery and motion preferences remain in place. The five destinations adapt to phones, tablets and landscape windows.

The game contains **1,480 story orders, 43 garden routes and 26 animal identities**. Nineteen full environments support those routes, with documented themed variants for the remaining route IDs. All existing portraits, original garden thumbnails and gameplay data remain bundled. Three couriers have newly generated standing world poses; the other world poses reuse their existing artwork with transparent margins trimmed.

The save format, Coins, rewards, purchases, route locks, partial puzzles and single persistent ad placement remain compatible. The controller, domain, persistence code, orders, lockfile, native legacy-save bridge and signing key are byte-identical to source version 20 (app 0.10.1+21); see docs/RELEASE_COMPATIBILITY.json. The visible Android app name is now Potion Post. Its package ID stays com.castilla.potion_post.adtest to update the existing installation without losing its private save.

Ads use the Google Mobile Ads SDK with Google's official demo units until publisher IDs are provided. No custom advertisement placeholder or empty loading footer is shown. Banner load failures retry with a bounded backoff while the app is in the foreground. Optional rewards are granted by the earned callback only. Unimplemented cash-pack advertising has been removed from the coin shop.

See INSTALL_APK.md for installation, VALIDATION.md for current checks, docs/RELEASE_POLISH.md for this visual pass and remaining publishing inputs, docs/SMOOTH_LOADING.md for scene loading, and docs/WORLD_SCENES.md for the shared world camera. The new store icon is store/potion-post-play-icon-512.png. scripts/package_brand.py exports its Android/iOS sizes from assets/potion-post-icon.png.

## Build

Use Flutter 3.47.6 (Dart 3.13.5), Android SDK 36, Microsoft JDK 17.0.20.1 with javac, build tools 35.0.0/36.0.0, NDK 28.2.13676358 and CMake 3.22.1. Keep pubspec.lock and test-signing/potion-post-ads-test.jks for compatible test-edition updates. Set CI=true in automated environments.

    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --release --flavor adtest

The Ads Test key is not a production Play upload key. A standard-app release still requires the original standard-app signing key.
