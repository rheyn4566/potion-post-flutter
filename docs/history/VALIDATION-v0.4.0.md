# Prototype validation

Validated on 7 October 2026; version 0.4.0.

## Flutter and native Dart

- Flutter 3.47.6, Dart 3.13.5; shared_preferences 2.5.6 lock retained.
- Static analysis: no issues.
- All 14 tests passed using real Poppins fonts, illustrated icons and sprite assets.
- All thirty puzzle certificates match their shortest routes. The introductory
  puzzles take one and three pours; later gardens add twenty distinct boards.
- 2,400 randomized legal moves preserve inventory; hints recover valid routes.
- Empty, full, out-of-range and self-targeting moves are rejected.
- First-delivery rewards occur once; progress and undo history restore correctly.
- Story/daily sessions remain separate; damaged sessions reset safely.
- The original ten puzzles, customer records and IDs are identical to v0.3.0.
- An original ten-order save retains 200 stamps, stars, theme and the completed
  board, and makes order 11 available in Lily Pond.
- The first lesson exercises wrong-tap feedback, an animated top-layer pour,
  Undo, Hint, delivery, the next order, navigation and settings.
- Phone checks at 390×844, 360×640, 320×568 and 844×390 keep bottles,
  recipes, tools and delivery controls on screen. Delivery dialogs also fit.
- Home and the active game contain no Scrollable widgets. Modal sheets may scroll
  on short displays so their controls remain accessible.
- Garden previews show ten orders at a time; locked gardens show the required
  order. Completing order 10 changes Home to Lily Pond and unlocks order 11.
- Home navigation preserves a partial board across daily and story play.
- Source selection lifts a bottle by 22 pixels. The moving bottle and stream
  appear before the board commits the move; target-mouth alignment is checked
  across rows, columns and vertical moves.
- Native screenshots are rendered from the Flutter widget tree.
- A separate native Dart run verified all 30 certificates, 2,400 random pours
  and three daily routes directly against lib/domain/puzzle.dart.

## Browser preview

- All thirty story orders and three daily orders completed through UI clicks.
- Real animated pouring, tutorial guidance, Undo, Hint and delivery verified.
- The moving bottle's mouth aligns with the selected target and stays 18 pixels
  above its opening while transferring the layer. Cross-row travel is verified.
- The stationary source disappears during flight and returns on landing.
- The included animated demo records the working browser UI.
- Daily replay grants no duplicate stamps; the tested balance stays at 660.
- Home, Play, order selection, restored boards and palette selection verified.
- All three garden previews work. Stored version-one progress opens order 11
  in Lily Pond after ten deliveries, and order 21 in Sunpetal after twenty.
- At 390×844, 360×640, 320×568, 844×390 and 1366×900, Home and gameplay
  have no page scrolling or overflow and keep every bottle/control on screen.
- Garden picker columns fit short phones and landscape displays.
- Modal dialogs make the underlying screen inert and trap keyboard focus.
- No JavaScript page errors occurred in the regression or garden checks.
- Sprites retain transparent alpha. Reusable image URLs avoid inserting large
  base64 strings again on every move; all artwork, code, fonts and data remain
  embedded for offline play.

## Release scope

This revision validates native widgets and Dart rules plus the standalone
browser game. A new Flutter release web build was not part of these checks.
Android/iOS runners are included; no signed APK, Android App Bundle or iOS binary
is included. Device performance, signing, AdMob and store checks remain release
work. The thirty-order pack is prototype content and has not had player testing.
