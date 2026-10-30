# Garden and game UI — 0.6.7

Home has a large garden scene with a smaller companion at the lower right.
A Change label identifies the selected home look. The separate route card
shows the current story garden, delivered count and matching delivery bar.
The route advances after its last order is delivered, before Next is pressed.
Replay selection cannot change the route frontier.

The game backdrop is centered above the tools, rather than cropped below
them. The board geometry and pour motion are retained. A recipe layer progress
bar replaces the tiny live star row. Tap it for scoring; results retain earned
stars. A coin wallet is visible during play. The menu uses the existing popup
pattern and compact bento controls, with free Keep playing always visible.

The garden atlas and route picker remain. They label star growth independently
from delivery progress. Visiting a garden still earns its look free. Purchased
home looks can be selected early without unlocking their story orders. The
Coin shop also offers companions and tools. Automatic route scenery can be
restored with Follow my route in its Gardens tab.

Current Flutter captures: GARDEN_HOME.png, GARDEN_GAMEPLAY.png,
GARDEN_PAUSE.png, GARDEN_PICKER.png, COIN_SHOP.png and SHOP_GARDENS.png.
Controlled test banner slots are blank; they are not served ad creatives.
See ECONOMY.md and ../VALIDATION.md for rules and verification limits.
