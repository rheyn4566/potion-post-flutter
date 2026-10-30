# Validation — Potion Post Ads Test 0.6.4

Version 0.6.4, code 11. Built and verified 18 October 2026 UTC.

## Native source and UI

- Flutter analysis: **No issues found**. **All 23 tests passed**: eight game
  checks, seven native widget checks and eight rewarded-ad coordinator checks.
- All 1,000 shortest solution certificates and 80,000 randomized pour trials
  pass. All 310 asset and puzzle/motion files compared with 0.6.3 are unchanged.
- Garden-owned colors persist without spending stamps, changing the current
  board or bypassing locked gardens. Legacy color-shop saves retain stamps,
  stars, settings, partial pours, undo history, friendship and reward claims.
- Daily hub, banner spacing, pause/resume and garden selection are exercised
  on small phones, landscape and tablets. Home/board checks cover 320×568,
  360×640, 390×844, 844×390, 758×1216 and 800×1280.
- Native Home, Gardens, Daily, gameplay and pause captures were visually
  inspected. Their banner slots are blank because controlled ad sessions are
  used, rather than server-served creatives.
- Active pouring has compact stars plus an icon/count in the header, with no
  large status strip. Tutorial/hint/error guidance remains. Real bottle lift,
  stream, tilt and return still pass. Four/five-bottle rows retain bounded gaps.
- Static Home, Daily, Gardens, Orders, Friends and game pause pages reserve
  bottom banner space. Covered routes hide/release their own banner. Repeated
  bottle/tool tapping takes place without a neighboring banner.
- Optional rewarded ads remain explicit, once per delivered order, and grant
  only from the earned event. Skip, failure, retry, repeated taps/callbacks and
  late rewards are checked. Free Next order stays visible even in landscape.

## APK

- Release-mode universal adtest APK: **com.castilla.potion_post.adtest**,
  **Potion Post Ads Test**, min API 24, target 36, version code 11.
- arm64-v8a, armeabi-v7a and x86_64 are present. ZIP CRC, APK signature v2,
  16 KB ZIP alignment and every native ELF load-segment alignment pass.
- Manifest contains the Google sample AdMob app ID, initialization provider
  and network permissions. Compiled Dart for each ABI contains only the three
  expected Google demo ad-unit IDs. There are no live publisher ad IDs.
- All 1,000 orders, 10 couriers and 124 garden PNG stages are included.
  No keystore is inside the APK.
- Flutter 3.47.6 / Dart 3.13.5, JDK 17, Android SDK 36, Gradle 8.14.3,
  AGP 8.13.1, Kotlin 2.2.20. Build dependency checks stay enabled.
- Google Flutter ads plugin 9.1.0 / Android GMA SDK 25.4.0, non-personalized
  requests and G requested ad-content rating. See docs/ADMOB.md.

This update uses the same app ID and dedicated test signing key as Ads Test
0.6.3, so it updates that edition in place. The original Potion Post app
remains separate. The Ads Test keystore is retained in the complete source ZIP.

- APK bytes: 87258406
- APK SHA-256: 5394ae13a745378913aec2a10c17f345d8c46c6b532b9f5c193be5b646f3fbca
- Signer SHA-256: acb414b0ac86b42b614fc63e7dc50bc6c74a518eadd4068bad95bc333ac08a35

## Practical limits

No physical Android/emulator installation or real ad-serving roundtrip was
verified here. Actual Google test-ad loading/completion needs checking on a
connected Android device. Controlled tests verify app behavior and layouts;
they do not prove AdMob account or store approval. This is a demo-ads APK.
Live publisher IDs, publisher-configured consent/privacy options, production
signing and public release declarations remain separate publishing work.
