# Validation — Potion Post Ads Test 0.6.3

Verified 18 October 2026. Version 0.6.3, code 10.

## Source and test checks

- Flutter analysis: **No issues found**.
- **All 19 tests passed** against the final Dart source. Eight checks exercise
  ad loading, explicit display, repeated taps/callbacks, failure/skip/retry,
  late rewards and disposal. Five native widget tests exercise the real game
  with controlled ad sessions; six game tests exercise puzzles and saves.
- All **1,000 shortest solution certificates** and **80,000 randomized pour
  trials** pass. Bonus claims require a completed order, grant twenty stamps
  once and persist through restart/export/restore. Late rewards remain assigned
  to the captured completed order. Legacy saves retain settings and partial
  pours, and final-order/daily rewards still work.
- Native layouts with bundled artwork/Poppins fit 320×568, 360×640, 390×844,
  844×390, 758×1216 and 800×1280. Home does not scroll, banners have their own
  reserved area, and active boards contain no banner. Modal routes hide the
  banner. Four/five-bottle and four-layer layouts retain their compact spacing.
- Next order stays visible outside the scrollable result area on short phones
  and landscape, and works while an ad is unavailable/loading. Regular stamps
  are awarded before the optional ad. The reward confirmation remains visible
  after the SDK earned event.
- Native Home/result captures were visually inspected. Their banner slot is
  empty because widget tests use controlled ad sessions, not served creatives.
- All 310 recovered original asset and puzzle/motion/catalog files checked are
  byte-identical. The retrieved prior source ZIP was truncated; recovery and
  recreated build/test files are documented in docs/RECOVERY.md.

## Android package checks

- Optimized universal release-mode **adtest** APK built with Flutter 3.47.6,
  Dart 3.13.5, JDK 17, Android SDK 36, Gradle 8.14.3, AGP 8.13.1 and Kotlin
  2.2.20. Build dependency checks were enabled.
- App **Potion Post Ads Test**, ID **com.castilla.potion_post.adtest**,
  min API **24**, target **36**, version code **10**. ABIs: arm64-v8a,
  armeabi-v7a and x86_64.
- Manifest contains Google's demo AdMob application ID, MobileAdsInitProvider
  and required network permissions. All three Google demo ad-unit IDs are
  present in the compiled Dart code for each ABI.
- Google Flutter ads plugin **9.1.0** / Android ads SDK **25.4.0**. Requests ask
  for non-personalized ads and a G content rating. Live IDs and revenue are not
  enabled. Placement and rewarded-policy research is in docs/ADMOB.md.
- Signature scheme **v2**, ZIP integrity, 16 KB ZIP alignment and ELF/native
  load-segment alignment checks pass. All 1,000 orders, ten couriers and 124
  PNG garden stages are present. No keystore is bundled inside the APK.

## Installation identity

The original private key was in the missing archive tail. This build uses a
new dedicated test key and a separate app ID, so it installs beside the old
game. Keep the old app. Copy/Restore progress can copy the version-one save to
the new edition. The dedicated new test keystore is retained in this source
archive for future updates. Standard updates require the original key.

## Artifact details and limits

- APK: potion-post-ads-test.apk
- Bytes: 87143478
- SHA-256: 2d3ca8c5e6ad0b9799be5a5c388d408596060361de0ff900c73eeadc7f169f15
- Test signer SHA-256: acb414b0ac86b42b614fc63e7dc50bc6c74a518eadd4068bad95bc333ac08a35
- Native layout captures: docs/ADS_HOME_LAYOUT.png and ADS_DELIVERY_LAYOUT.png.

No physical Android/emulator installation or real ad-serving roundtrip was
verified here. The user must check actual Google test-ad loading/completion on
their connected device. These tests verify app behavior under controlled SDK
outcomes and native widget rendering; they do not prove account/store approval.
Live publisher IDs, account-configured UMP messages/privacy options, a public
privacy policy, audience/data declarations and production signing remain work
before live publishing. This is a demo-ads APK, not a production Play AAB.
