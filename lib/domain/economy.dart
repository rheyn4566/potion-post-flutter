/// One local currency. Legacy `coins` balances already contain the old stamps.
const deliveryCoins = 20;
const dailyRouteCoins = 40;
const deliveryAdCoins = 20;
const shopAdCoins = 20;
const shopAdsPerDay = 3;
const hintPackPrice = 60;
const undoPackPrice = 40;

enum PurchaseResult { bought, owned, insufficientCoins, unavailable }

int companionPrice(int index) => index <= 0 ? 0 : 300 + (index - 1) * 150;

/// Garden growth follows unique story deliveries, independent of pour count.
int gardenGrowthStage(int delivered, int total) {
  if (total <= 0 || delivered <= 0) return 0;
  if (delivered >= total) return 3;
  if (delivered * 10 >= total * 6) return 2;
  if (delivered * 10 >= total * 3) return 1;
  return 0;
}

class GardenDecoration {
  const GardenDecoration(this.id, this.name, this.price, this.description);
  final String id, name, description;
  final int price;
  static const all = [
    GardenDecoration(
      'chimes',
      'Petal chimes',
      500,
      'A rosewood chime beside the path',
    ),
    GardenDecoration(
      'fireflies',
      'Firefly lights',
      1200,
      'Little golden lights around the garden',
    ),
    GardenDecoration(
      'fountain',
      'Moon fountain',
      2000,
      'A moonlit fountain by the flowers',
    ),
  ];
}

class CoinEntry {
  const CoinEntry(this.label, this.amount, this.day);
  final String label, day;
  final int amount;
  Map<String, dynamic> toJson() => {
    'label': label,
    'amount': amount,
    'day': day,
  };
}
