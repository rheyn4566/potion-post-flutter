# Validation — Potion Post Ads Test 0.6.6

Version 0.6.6, code 13. Verified 19 October 2026.

## Automated game, storage and UI checks

- Flutter analysis: **No issues found**. **All 51 tests pass**: eight game,
  eight rewarded-coordinator, nine storage/recovery, three tool-budget,
  seven economy and sixteen native-widget tests. Logs are retained in
  docs/TEST_RESULTS.txt and docs/ANALYZE.txt.
- All 1,000 shortest puzzle certificates and 80,000 randomized pour trials pass.
  The new recipe meter also reaches 100% exactly at solved states throughout
  all 1,000 certified routes. Rating boundaries and first-delivery/replay
  payouts retain their existing rules.
- Coin purchases are checked for confirmation/cancellation, affordability,
  duplicate ownership, route locks, friendship separation and tool credits.
  Failed writes expose retry without a second purchase/deduction. Earned shop
  ads grant once, including duplicate and late callbacks, with persisted daily
  limits. Skips, unavailable ads and preloading do not grant coins.
- A real Dart process writes the checkpoint and exits; another reads it. A new
  controller restores actual file bytes for the story/daily route, partial
  board, moves, coins, purchased garden/companion, tools, ad limits and receipts.
  Checksum recovery, pending rename recovery, native-channel legacy migration,
  blocked zero-state writes and ordered retry protection continue to pass.
- After ten deliveries the home route advances to Lily Pond at 0/10 before
  Next; replaying an old order cannot pull it back. Selected looks remain
  independent, and buying a look never unlocks its story levels. Legacy
  balances and sessions migrate without a reset.
- Phone/tablet/landscape checks cover 320×568, 360×640, 390×844, 844×390,
  758×1216 and 800×1280. Shop tabs, compact four/five-bottle layouts, system
  insets, result/refill dialogs and the popup menu are exercised. Native
  Flutter captures were visually inspected. Their banner frames are controlled
  blanks, not server-served ads.
- The game menu remains a Dialog over the same bottle board. Automatic delivery
  retains bottle geometry. Wallet/scoring navigation is guarded during pours.
  The shared bottom banner stays mounted through navigation and popups, with
  one bottom inset, a reserved creative area and a non-clickable buffer.

## Android package checks

- Release universal APK: **com.castilla.potion_post.adtest**, label
  **Potion Post Ads Test**, version **0.6.6 (13)**, minimum API 24, target 36.
- arm64-v8a, armeabi-v7a and x86_64 only. Signature v2, APK ZIP CRC, 16 KB
  ZIP alignment, every native ELF header/section/program bound and every
  native load-segment alignment pass.
- The signer matches Ads Test 0.6.3–0.6.5. Install as an update without
  uninstalling to retain Android app data. This does not update the separate
  original com.castilla.potion_post installation.
- Manifest contains the official Google sample AdMob application ID/provider
  and network permissions. Compiled Dart libraries contain exactly the three
  expected demo unit IDs and the native save-channel names. DEX contains the
  native storage/migration bridge. No signing keystore is inside the APK.
- All 1,000 orders are byte-for-byte unchanged; 10 companion PNGs and 124
  garden PNG stages are bundled. Existing artwork, native save bridge, file
  storage layer, board motion and banner adapter match the preceding source.
- Flutter 3.47.6 / Dart 3.13.5, JDK 17, SDK 36, Gradle 8.14.3, AGP 8.13.1,
  Kotlin 2.2.20, google_mobile_ads 9.1.0 / Android GMA 25.4.0. Build dependency
  checks remain enabled. Dedicated test signing key is retained in the source.

- APK bytes: 87005470
- APK SHA-256: 48b6185f6dc52cc226140c1c2bc530524ddac1bb63ee4dfdeeb3bb0812beb5e7
- Signer SHA-256: acb414b0ac86b42b614fc63e7dc50bc6c74a518eadd4068bad95bc333ac08a35

## Practical limits

No Android device/emulator was available here. The host tests, disk-process
checks, native compilation and package checks do not prove an on-phone
upgrade/relaunch, served ad creative or actual device frame rate. Install over
Ads Test and check these on the phone. Test ads generate no revenue.

Real-money coin purchases are not integrated: the shop says they are unavailable
in this test edition. Existing earned coin purchases work locally. A live
release still needs real Play products, Billing and verified fulfillment,
production signing, publisher ad units/consent and store review. No AAB or
production release is claimed. See docs/ECONOMY.md and docs/ADMOB.md.
