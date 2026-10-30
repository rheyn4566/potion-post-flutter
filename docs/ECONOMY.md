# Coins and progression — 0.6.8

Coins are the only spendable currency. There is no three-star rating system.
The Home and game wallets share one balance; the latest 25 changes appear in
Coin activity. Existing balances are retained exactly.

## Earning and spending

| Action | Coins | Rule |
| --- | ---: | --- |
| Story or daily delivery | +20 | First completion of the unique order only |
| Complete all three daily orders | +40 | Automatic once per local day; 100 total with the three deliveries |
| Friendship milestones | +15, +25, +40, +60, +100, +150 | Existing one-time rewards at 1/3/6/25/75/150 unique deliveries |
| Optional coin-reward ad | +20 | Three earned coin rewards per local day across shop and delivery |
| Three extra hints | −60 | Banked uses carry across days |
| Five extra undos | −40 | Banked uses carry across days |
| Starter companion | Free | First catalog companion, available on first launch |
| Additional companions | −300 to −3,900 | Twenty-five prices in catalog order, increasing by 150; the original ten companions retain their prices |
| Petal chimes | −500 | Per unlocked garden |
| Firefly lights | −1,200 | Per unlocked garden |
| Moon fountain | −2,000 | Per unlocked garden |

Five first-completion story wins earn 100 coins. A 60-coin hint pack leaves
40. Ten wins earn 200 coins; the first additional companion takes 15 wins
without bonuses. Petal chimes take 25 wins. These starting values are design
choices and should be tuned after real playtesting.

Every coin purchase shows the item, price and balance before confirmation.
Cancellation is free. Insufficient funds, duplicate ownership, invalid or
locked items, and failed save loading cannot deduct coins. Cash purchases are
not enabled in this test APK; a paid edition needs real Play Billing products,
verified and idempotent fulfillment, and license-test purchases.

## Gardens

Unique completed story orders drive growth, independent of pour count:

| Garden length | Flowers | Lanterns | Full bloom |
| --- | ---: | ---: | ---: |
| 10 orders | 3 delivered | 6 delivered | 10 delivered |
| 40 orders | 12 delivered | 24 delivered | 40 delivered |

Daily orders do not advance story gardens. Replays count once and earn no
second completion payment. Gardens unlock sequentially through story play.
The first unfinished order is always the Home Play destination. Finishing
order 10 advances the route card to Lily Pond at 0/10 immediately. The
completed Moonbloom garden remains fully grown in the collection.

Home follows new route gardens by default. Selecting a garden pins it;
Follow my route resumes automatic changes. Selected Home colors and current
story-route colors are labeled separately. Optional decorations are purchased
for a specific unlocked garden, appear in that garden's artwork, and can be
shown or hidden without another charge. Purchasing them never unlocks levels
or adds completed deliveries.

## Recipe progress and results

The game bar measures bottom-up matching layers in customer bottles. It may
decrease when a matching layer is moved. Conservation of contents means
100% requires all recipes to match and spare bottles to be empty. Finish in
any number of pours; there is no score-star gate or penalty. Tap the bar for
recipe help. Results show earned coins, balance, daily bonus when applicable,
and garden delivery progress. Existing dialogs remain popups over the board.

## Migration and saves

The outer progress JSON stays version one. Its historical `stars` map is
retained as a completion record to preserve old saves and Copy/Restore.
Old 1–3 values stay intact; new completions store 1 as a marker. No star values
are shown, spent or used to grow gardens. The 30%/60%/100% thresholds cannot
reduce any garden growth earned under the old rating thresholds.

Nested economy schema two stores decorations and their visibility. Every
companion previously met under the free-unlock rule is grandfathered into
owned companions once on migration. Existing paid garden looks remain owned,
even before their story route is reached; decoration purchases still require
the story garden to be unlocked. Currency, settings, partial boards, undo
history, tool banks, friendship, claims and receipts remain intact. Migration
does not reset progress or award duplicate coins.

The old `shopAds` saved counters now count all earned coin ads. A duplicate
or late SDK callback can grant only once. The three-reward limit survives
restart and restores at local midnight. Tool-refill ads remain independently
opt-in and do not grant coins. A skipped, failed or merely loaded ad grants
nothing. Normal play and Restart remain free.

Progress continues through two flushed and checksummed app-private files with
backup/pending-write recovery and native Android legacy migration. An
unreadable save blocks writes until recovery instead of overwriting progress
with a new empty state.
