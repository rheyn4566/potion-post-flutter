# Install Potion Post v0.9.0 (Build 19)

Install potion-post-v0.9.0-build19.apk as an update to Potion Post Ads Test. The application ID is com.castilla.potion_post.adtest and the existing test signing key is retained. Android should offer Update. Keeping the installed app preserves its private local save.

The app uses Google demonstration ad IDs. Coin packs for real money are not enabled. Earned Coins, purchases, partial puzzles and garden progress use the existing local save format.

Check Settings for v0.9.0 (19). This update replaces stretched panel and navigation art, refreshes five visual assets, integrates the Daily courier into one continuous office scene, keeps the Friends platform proportional, and extends the gameplay background across the screen behind the safe-area controls. The persistent ad banner remains beneath the game. It retains 18 additional garden illustrations, 43 garden routes, 26 companions and 1,480 story orders.

For source builds use Flutter 3.47.6 (Dart 3.13.5), a full JDK 17, Android SDK 36 and the included test-edition key. Run flutter pub get, flutter test, flutter analyze, then flutter build apk --release --flavor adtest.
