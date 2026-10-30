# AdMob status — Potion Post 0.12.0+23

Reviewed the actual adapter and official Google documentation on 22 October 2026. google_mobile_ads remains pinned at 9.1.0; the dependency lockfile is unchanged.

## What is implemented

One native Google Mobile Ads banner is mounted below the root Navigator. A loaded ad uses its actual adaptive height, with a compact 320×50 fallback on small/short windows. A 12dp non-clickable spacer separates the creative from app content and the bottom system inset is applied once. Loading/no-fill ads occupy no footer space and no custom test-ad/loading advertisement block is painted. Native ad refresh is SDK-controlled; failures retry with bounded foreground backoff. This implementation is not a claim of AdMob placement approval. Check accidental taps and real adaptive sizes on devices before live publishing.

Rewarded ads are optional. A completion bonus adds 20 Coins, a shop ad adds 20 Coins and both share a saved three-earned-rewards-per-local-day cap. Hint/Undo offers add three hints or five undos respectively. Only the SDK earned callback grants these items. Preloading/retry never automatically shows an ad. The domain protects once-only offers and delayed callbacks, and closing/failing without an earned event grants nothing. Restart, normal pouring and next-order navigation stay free. No interstitial/app-open format is implemented. Rewards are in-app-only and have no cash value.

Automated tests cover no-fill geometry, one persistent banner, duplicate taps/callbacks, late earned events, skipped/failed ads, tool replenishment, shared daily caps, purchase/save recovery and compact dialogs. No physical Android or live publisher traffic was used here.

## Current test configuration

The Android manifest uses Google's sample app ID ca-app-pub-3940256099942544~3347511713. The adapter hardcodes official Google demo units:

- Adaptive banner: ca-app-pub-3940256099942544/9214589741
- Fixed fallback: ca-app-pub-3940256099942544/6300978111
- Rewarded: ca-app-pub-3940256099942544/5224354917

Requests are non-personalized and ask for a G maximum content rating. Demo ads generate no publisher revenue. The SDK's own Test Ad label must remain; no custom placeholder is added by the game.

## What remains for live monetization

The current test adapter has no live-ID override and no production UMP consent gate. Before live release, configure the owner's AdMob app and banner/rewarded units, account privacy messages, startup requestConsentInfoUpdate and any required consent form, canRequestAds gating, and the required privacy-options entry point. Non-personalized requests alone do not replace consent. Add accurate privacy/Data safety/audience declarations, production signing, publisher verification and any required app-ads.txt. Test on real devices and the Play internal track. A G rating by itself is not child-directed/Families configuration.

Cash coin packs and Play Billing product/fulfillment code are not implemented or offered. The current shop spends locally earned game Coins for actual saved companions, per-garden ornaments and tools.

## Official documentation

- https://developers.google.com/admob/flutter/test-ads
- https://developers.google.com/admob/flutter/privacy
- https://developers.google.com/admob/flutter/banner
- https://developers.google.com/admob/flutter/rewarded
