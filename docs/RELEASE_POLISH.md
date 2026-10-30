# Potion Post 0.11.0+22

Home now has a 76px Level/Play control on phones and an 88px control on tablets (72px in landscape side layouts). The gameplay level title is 23px. Map stops are circular, grow to 82px on tablets, preserve at least 48px hit targets and show their level number even when locked. Progress, route locks and the puzzle economy are unchanged.

The settings modal uses the real Potion Post brand and icon, grouped sound/haptics/motion controls, progress backup and restore, help and a factual ads/privacy explanation. These controls call the existing persisted settings and native feedback APIs. Content scrolls on short screens while the close button and build version remain reachable. No fake rate/support/purchase links were added.

Deliveries use a native emerald-and-cream celebration with the actual customer, a prominent earned-coin amount, garden progress, route bonuses and garden-unlock messaging. A finite 1.4-second confetti burst stops under Reduce Motion. Rewards are committed before presentation and are never granted by the animation. Details and optional rewarded ads scroll independently of the fixed Next/Home footer. Replays still grant no repeat completion coins.

The permanent “Advertisement · Test” label and unloaded banner strip were removed. A single SDK banner remains mounted below the Navigator, but occupies space only once loaded. Small/short windows (width below 360px or height below 620px) use a standard 320×50 SDK banner to preserve play space. Larger windows use the SDK’s anchored adaptive size; the creative is displayed at that exact size without stretching. Google controls any test-ad marking inside its own creative. No-fill/offline requests retry at 30/60/120-second intervals while foregrounded. Rotation discards stale callbacks and sizes safely. A stable MediaQuery wrapper prevents the game route from being replaced when banner visibility changes.

Google's demo app/banner/rewarded IDs remain in this test build because publisher IDs have not been supplied. It is not a live-monetization or Play Store submission build. Removing our placeholder does not convert demo units into live units.

## New branding assets

The final generated artwork shows the existing mint dragon courier Pip with his golden horns, glowing amber potion, cream envelope, golden wax seal and coral courier strap against deep teal. The generated master is assets/potion-post-icon.png. The source mascot reference is assets/worlds/pose-dragon.webp. No garden or character artwork was replaced.

Generation direction: one opaque square premium tactile storybook app icon, dominant recognizable mascot face, warm honey light, deep teal background, clear potion/envelope silhouette, no text, no flowers, no border and no baked outer corner mask. The final generation retains the first icon composition with more breathing room around the subject.

Exports: all Android launcher densities; Android adaptive foreground/background and a separate monochrome potion-post symbol; the existing iOS AppIcon sizes; 256px in-app brand WebP; and a full-square 512px RGBA Play Store PNG below 1MiB. The raster export script only resizes the generated artwork. Android applies the adaptive icon mask at runtime.

## Before a publishing build

Provide the publisher's Android AdMob app ID, anchored banner unit ID and rewarded unit ID. Wire the corresponding UMP consent/messages and required privacy-options entry point before requesting production ads. The current privacy explanation is an in-app explanation, not a hosted privacy-policy URL.

Choose the production package identity and configure the actual Play upload signing key. The existing adtest key is retained solely so this APK updates the installed test app. The standard flavor deliberately refuses to substitute a new key for a missing original key. A different package cannot read another app's private save; use Copy/Restore progress when transferring packages.

The publisher must supply the public privacy-policy URL and complete the actual Play listing, ads declaration, audience/content rating and Data Safety answers for the selected services. Then build and verify a signed Android App Bundle and test through Play's internal track. This APK targets SDK 36; the package verifier checks that value, its signature and native 16KiB alignment. Device testing is still needed for physical performance and real ad callbacks.

## References used

- https://developers.google.com/admob/flutter/banner
- https://developers.google.com/admob/flutter/test-ads
- https://developers.google.com/admob/flutter/privacy
- https://developer.android.com/distribute/google-play/resources/icon-design-specifications
