# Validation — Potion Post Ads Test 0.6.5

Version 0.6.5, code 12. Verified 19 October 2026 Philippine time.

## Game and persistence

- Flutter analysis: **No issues found**. **All 39 tests pass**: eight game,
  eleven native widget, eight rewarded coordinator, nine storage/recovery and
  three tool-budget tests. See docs/TEST_RESULTS.txt and docs/ANALYZE.txt.
- All 1,000 shortest solution certificates and 80,000 randomized pour trials
  pass. Puzzle records, character/garden artwork, fonts and pour motion remain.
- A real Dart process writes the saved game and exits; a second process reads
  it. A new controller restores level/unlocked progress, daily route/slot,
  partial pours, moves, stamps and selected garden from those actual files.
- Preferences-only saves migrate into two private, checksummed file copies.
  Writes flush before rename. A damaged valid-JSON copy recovers its intact
  partner; a complete pending write recovers an interrupted rename.
- An unreadable save blocks zero-state writes and exposes recovery. Failed
  writes retain current state for retry. Repeated Retry taps keep recovery
  protected during a slow read. Imported progress also restores route/mode.
- Android MainActivity supplies private storage and reads old DataStore or XML
  preferences directly for migration. The Kotlin bridge compiles; Flutter
  tests mock its channel contract. This avoids using the old Dart/JNI preference
  transport for new game saves. New native storage needs no external permission.

## UI and ads

- One banner remains mounted below the root Navigator across Home, active play,
  Daily, Gardens, Orders, Friends, pause and Flutter dialogs. Tests assert one
  mount and no disposal during navigation, modal/reward interactions and pours.
- The creative area reserves 50 dp, with a 24 dp non-clickable buffer, divider
  and label above it. Game tools end a further 12 dp above the reserved frame.
  The bottom system inset applies once. Active play banners follow this fixed
  separated layout; this is not a claim of AdMob approval or higher revenue.
- Solving saves automatically and opens a result popup. No bottom Deliver bar
  is inserted. A real animated pour test compares bottle geometry before and
  after completion and confirms it stays identical. Next/Home remain free.
- Daily free tools: three hints/five undos. Restart and first-order tutorial
  guidance stay free. Successful actions charge once; failed actions and
  re-reading the current hint do not. Counts survive restart/app relaunch.
- Optional explicit refills grant three hints/five undos only from the earned
  callback. Duplicate events grant once; unavailable/retry/skip remain optional.
  Banked earned tools survive midnight alongside the new day's free allowance.
- Home/board checks cover 320×568, 360×640, 390×844, 844×390, 758×1216 and
  800×1280, including system insets, short result/refill dialogs and compact
  four/five-bottle layouts. Current native captures were visually inspected.
- Captures use blank controlled banner frames, not server-served creatives.

## Verified APK

- Release universal adtest APK: **com.castilla.potion_post.adtest**, label
  **Potion Post Ads Test**, minimum API 24, target 36, version code 12.
- arm64-v8a, armeabi-v7a and x86_64 only. APK signature v2, ZIP CRC, 16 KB ZIP
  alignment and all native ELF segment/header bounds and alignments pass.
- Google sample app ID/network permissions/provider are present. Each compiled
  Dart ABI contains only the three expected demo ad IDs and both native save
  channel method names. Native DEX contains the migration bridge identifiers.
- All 1,000 orders, 10 characters and 124 garden PNG stages are bundled.
  No signing keystore is inside the APK.
- Flutter 3.47.6/Dart 3.13.5, JDK 17, SDK 36, Gradle 8.14.3, AGP 8.13.1,
  Kotlin 2.2.20. Build dependency checks remain enabled. Ads plugin 9.1.0,
  Android GMA SDK 25.4.0; path_provider 2.1.6 for non-Android private paths.
- Same Ads Test application ID and signer as 0.6.3/0.6.4: install as an update
  to retain Android app data. The separate original Potion Post app is retained.

- APK bytes: 86874038
- APK SHA-256: 200f81b5b841fbb30b46384dc6522f91abcb3459d77e6bf179d855cb97f29838
- Signer SHA-256: acb414b0ac86b42b614fc63e7dc50bc6c74a518eadd4068bad95bc333ac08a35

## Limits

No physical Android/emulator installation, native Android storage roundtrip or
real ad-serving roundtrip was executed here. Actual close/reopen and Google
test-ad delivery/completion still need the user's connected Android device.
Disk durability was tested on real host files in separate Dart processes;
Android channel tests use mocks, and the Kotlin bridge is build-verified.
Already-erased data cannot be reconstructed without a surviving save/backup.
Only demo ads are configured; publisher IDs, consent/privacy setup, production
signing and store/account review remain separate live-publishing work.
