# AdMob test integration — 0.6.7

Reviewed official Google documentation on 19 October 2026. Plugin:
`google_mobile_ads 9.1.0`, standard Google Mobile Ads backend, no mediation.

## Placement and reward behavior

A single banner is mounted below the app's root Navigator. It remains mounted
on Home, active play, Daily, Gardens, Orders, Friends, pause and Flutter dialogs.
Navigating does not dispose or reload it. Fullscreen rewarded video naturally
covers the app. The SDK controls refresh while visible; there is no app refresh
timer. Width/orientation, initialization or an explicit retry can change the
request configuration.

The creative area is always 50 dp tall. The current large anchored API is used
only if its result fits that height; otherwise the official 320×50 test banner
is used. A 24 dp non-clickable buffer, divider and 11 dp Advertisement label sit
above the creative. The game's tools also end 12 dp above the reserved frame.
The system bottom inset is applied once. Loading and result popups do not move
controls into the banner's reserved area.

Google warns against banners immediately beside repeatedly tapped game content
and navigation, and prohibits floating/overlapping content. This build keeps
the banner outside the game/tools and below a fixed buffer, with no banner
between bottles and tools. This is a mitigation based on the separation guidance,
not a claim of AdMob approval or a revenue guarantee. Monitor the real placement
and accidental-click behavior before a live release.

Delivery offers **Watch ad · +20 coins**, with exact action/reward text and free
Next order/Home actions. Normal rewards are saved before the result popup.
Exhausted Hint/Undo opens a separate offer: one ad adds **3 hints** or **5 undos**.
Daily free uses are 3 hints/5 undos; Restart stays unlimited and free. Banked
ad-earned tools survive local midnight. Declining or skipping does not block
normal pouring, Restart, the next order or normal delivery rewards.

Preloading and Retry never automatically show an ad. Only the SDK earned event
grants a reward. Shop offers disclose one optional ad for 30 coins, capped at three earned rewards per local day. The cap and grants persist through app restart. Delivery rewards are once per completed order; tool rewards
are once per issued offer ID. Duplicate taps/callbacks, skip/failure and late
callbacks are covered by tests. Captured callbacks remain assigned to the offer
that was actually watched, including after its popup closes.

All rewards are non-transferable, in-app-only items. Coins and tools cannot be
redeemed for cash, crypto, gift cards or anything outside Potion Post. No
interstitial/app-open ads are included. Offline puzzles/Restart stay usable.

## Demo configuration

| Setting | Android value |
| --- | --- |
| Google sample app | `ca-app-pub-3940256099942544~3347511713` |
| Adaptive banner | `ca-app-pub-3940256099942544/9214589741` |
| Fixed banner fallback | `ca-app-pub-3940256099942544/6300978111` |
| Rewarded | `ca-app-pub-3940256099942544/5224354917` |
| Request | `nonPersonalizedAds: true` |
| Maximum requested ad-content rating | G |

The adapter accepts no live IDs or live-mode overrides. Demo ads generate no
revenue. This is not a claim of Google approval or a production consent setup.

## Before live publishing

Create the publisher app/units and configure Google UMP messages under that
publisher account. Update consent information every launch, show required forms,
use `canRequestAds()` before live requests and expose required privacy options.
Non-personalized requests do not replace required consent. No configured UMP
form is claimed for Google's shared sample app ID in this test-only edition.
Publish an accurate privacy policy and Play Data safety/ad declarations, and
choose the actual target audience/age treatment. A G ad-content rating alone
does not establish compliance with child-directed/Families requirements.
Production signing and publisher/account/store review remain separate work.

## Official sources

- https://developers.google.com/admob/flutter/quick-start
- https://developers.google.com/admob/flutter/test-ads
- https://developers.google.com/admob/flutter/banner
- https://support.google.com/admob/answer/6128877?hl=en
- https://support.google.com/admob/answer/6275335?hl=en
- https://support.google.com/admob/answer/6275345?hl=en
- https://developers.google.com/admob/flutter/rewarded
- https://support.google.com/admob/answer/7313578?hl=en
- https://developers.google.com/admob/flutter/privacy
- https://pub.dev/packages/google_mobile_ads

- https://developers.google.com/admob/flutter/banner/fixed-size
- https://developers.google.com/admob/android/test-ads
