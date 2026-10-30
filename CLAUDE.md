# Claude Code development instructions — Potion Post

## Scope
Flutter/Dart puzzle game, version 0.12.0+23. Preserve established player progression, owned companions, selected garden, coin balances, ad rewards, and saved-state compatibility. Prefer targeted, tested changes rather than broad rewrites.

## Important locations
- `lib/game_controller.dart`: app/game controller
- `lib/domain/`: catalog, puzzles, economy
- `lib/data/`: progress storage
- `lib/ads/`: banner and rewarded ad flows (demo IDs only)
- `lib/ui/`: scenes, screens, layout, routes, and effects
- `test/`: unit/widget/regression tests

## Standard workflow
1. Read `README.md`, `VALIDATION.md`, and relevant source/tests.
2. State assumptions and the testable acceptance criteria before edits.
3. Prefer adding a failing regression test for each bug fix.
4. Implement small changes; verify using `flutter analyze` and `flutter test` when the toolchain is available.
5. Review changed files with `git diff`; note any unverified claims or missing tools.
6. Do not claim physical-device testing or live AdMob testing unless actually performed.

## Security / shipping
- Never add signing keys, credential files, `.env` files, or local SDK paths to Git.
- Google Mobile Ads uses test units, not live publisher accounts. Production deployment requires consent, policy review, real IDs, release signing, and Play Store testing.
- Do not change package identity or signing unless explicitly requested.
- Protect the local save format and migration compatibility.

## Suggested next tasks
- Improve automated coverage for progress-store recovery and failure scenarios.
- Audit purchase and reward double-grant protection.
- Test screen layout and image asset memory on real Android devices.
- Prepare live-ad privacy/consent integration separately from the demo build.
