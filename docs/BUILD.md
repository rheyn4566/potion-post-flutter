# Rebuild the Android test update

Validated toolchain for 0.12.0+23:

- Flutter 3.47.6 / Dart 3.13.5 (keep pubspec.lock).
- A full JDK 17, including javac and jlink. A Java runtime alone is insufficient.
- Android SDK platforms android-35 and android-36. The JNI plugins compile against 35; the game and ads plugin compile/target 36.
- Android Build Tools 35.0.0 and 36.0.0 (AGP defaults to 35; the verification script uses 36).
- Android NDK 28.2.13676358 and CMake 3.22.1 with its Ninja binary.
- Gradle 8.14.3, Android Gradle Plugin 8.13.1, Kotlin 2.2.20 (current pinned project versions).

Configure Flutter's Android SDK and full-JDK locations for the local machine, then run:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=2 --reporter expanded
flutter build apk --flavor adtest --release --no-pub
```

In hosted CI, set CI=true, BOT=true and FLUTTER_SUPPRESS_ANALYTICS=true before invoking Flutter. This uses Flutter's built-in CI path without an optional cloud-instance detection probe. Use the environment's authorized network proxy and trusted CA store for Java dependency downloads where required; retain TLS certificate verification.

The adtest flavor deliberately keeps com.castilla.potion_post.adtest and the retained test update keystore. Its launcher name is Potion Post. Version/build fields must match pubspec.yaml and lib/build_info.dart. A standard production build has separate signing requirements; do not substitute a new key for an existing installation.

For refreshed host preview captures, set POTION_POST_CAPTURE=1 and run test/selection_route_test.dart. Native package checks use scripts/verify_apk.py with the actual APK and --build-tools pointing to Build Tools 36. Capture analyzer/test output in docs/ANALYZE.txt and docs/TEST_RESULTS.txt before that verification. scripts/package_install.py creates a byte-identical-APK ZIP only after verification, and scripts/package_source.py packages the portable source without machine SDK/cache/build directories.

No publisher credentials or live AdMob IDs are included. See ADMOB.md for the actual demo integration and remaining live release work.
