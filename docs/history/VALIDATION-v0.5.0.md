# Validation — Potion Post 0.5.0

Checked on 8 October 2026. This is the continued original Flutter project.

## Checks completed for this revision

- Original first thirty puzzles and customer records match the recovered 0.4.0
  archive exactly. Its native save key, runners, artwork and font assets remain.
- Standalone **actual Dart puzzle source** solved all 80 certified recipes with
  shortest routes matching their par. **6,400 randomized legal pours** conserved
  inventory; the solver recovered a valid solution after every random walk.
- Three daily recipes solved correctly. The original 30-order daily pool is
  retained, including its recoloring and local-date IDs.
- **387 controller assertions** passed against the actual controller source:
  all eighty unlocks; first-delivery and replay protection; friend rewards and
  persisted claims; selectable couriers; palette unlocks; daily bonuses and
  streaks; date rollover; order-30 save migration; portable saves and undo;
  rejection of malformed imports; and catch-up route bonuses.
- The controller run used explicit offline adapters for ChangeNotifier and
  shared_preferences, and actual Dart isolates for compute. It used
  MemoryProgressStore. This verifies controller behavior, not Flutter
  notifications, widget rendering, clipboard, or device preference plugins.
- All Dart source parsed and formatted with the cached Dart 3.13.5 formatter.
- Thirty-two garden scenes (eight base scenes plus three decoration stages per
  garden) were rendered from local editable SVGs. The fully grown scenes were
  visually inspected. Original courier sprites remain unchanged.
- ZIP integrity, all required artwork/fonts, puzzle color bounds and native
  runner files were checked before packaging.

## Pending for this revision

Flutter package resolution, Flutter analysis, native widget tests, Android/iOS
builds and device rendering remain pending. The earlier package cache is
missing. An attempted Flutter runtime check was rejected by automatic approval
review because it targeted a cloud metadata endpoint that could expose
credentials. No cloud metadata access is needed by the game or offline checks.

The included Flutter tests retain the original navigation, animated pouring,
layout and save regressions, and add the expanded progression checks and
four-layer viewport checks. They have **not** been executed for this version.
The historical 0.4.0 validation record is under docs/history/ and does not apply
to the new eighty-order revision.

## Repeat the offline checks

From the project root, with the Dart SDK installed:

```sh
dart --disable-dart-dev tools/validate_orders.dart
dart --disable-dart-dev --packages=tools/offline_adapters/package_config.json tools/validate_progress.dart
```

The offline package config is for the validation harness only. Do not use it
for the application or for Flutter widget tests. Use `flutter pub get`,
`flutter analyze` and `flutter test` for the complete native checks.
