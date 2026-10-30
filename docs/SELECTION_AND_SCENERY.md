# Selection, route and scenery audit — 22 October 2026

- The controller spends actual earned Coins, records ownership and coin activity, and queues local save writes. Companion purchases select that exact kind; selecting owned companions is free. Existing failure/retry behavior retains an in-memory purchase without charging twice.
- Garden selection is independent of story progression. Locked gardens cannot be equipped; browsing previews does not change the saved choice. Selecting a garden disables automatic route-following; turning Follow my route back on resumes it.
- Home, Garden previews and the Orders companion now read the saved courier. The puzzle's potion recipient remains the order's customer, which is a separate role from the player's companion.
- Shop garden previews now use GardenWorld, including the exact saved decoration set, selected animal and the same WorldArt environment/palette. Garden collection thumbnails resolve to that same painting rather than a different isometric island illustration.
- Original world pictures are 1024×1536. The old camera could increase its zoom just to meet a UI stage position, then crop an already downsampled decode. The new camera uses the minimum cover scale and constrains panning; native detail is preserved with a larger full-screen decode budget and high-quality filtering. Soft painted depth in the source art remains.
- Forty-three story gardens use nineteen environment paintings with consistent palette variants. No new unique painting is claimed for every route.
- Orders now use shaded irregular stone platforms, carved numbers, moss, lock/completion plaques and a winding laid-stone trail. The complete 48px-or-larger hit target, locked-order guard and saved resume level are retained.
- All 26 shop portrait / grounded pose pairs were visually compared for matching animal identity. No placeholder purchase or cash billing flow is presented.
- Real SDK callbacks are implemented, but demo ad units cannot prove live publisher delivery or revenue. Live deployment requires the publisher configuration and consent flow described below.

## Live ads remain a separate release step

The current adapter hardcodes Google's official sample app and ad-unit IDs. Leave these demo units in testing builds. Before live release, use the owner's AdMob application/banner/rewarded IDs; configure account privacy messages, refresh consent information on each launch, present any required form, check canRequestAds before requests and expose required privacy options. Non-personalized requests alone do not establish consent. Recheck on a physical device and the Play internal track. Cash packs require Play Billing products and verified fulfillment before being offered.

Reviewed official sources on 22 October 2026:
- https://developers.google.com/admob/flutter/test-ads
- https://developers.google.com/admob/flutter/privacy
- https://developers.google.com/admob/flutter/rewarded
