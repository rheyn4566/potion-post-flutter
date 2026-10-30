import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/game_ads.dart';
import '../build_info.dart';
import '../game_controller.dart';
import 'woodland.dart';

class GameSettingsDialog extends StatelessWidget {
  const GameSettingsDialog({
    super.key,
    required this.game,
    required this.ads,
    required this.onCopy,
    required this.onRestore,
    required this.onHelp,
  });
  final GameController game;
  final GameAds ads;
  final VoidCallback onCopy, onRestore, onHelp;

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('game-settings'),
    backgroundColor: Woodland.cream,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 500,
        maxHeight: MediaQuery.sizeOf(context).height - 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFF1F5149),
            padding: const EdgeInsets.fromLTRB(22, 12, 10, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Woodland.cream,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Woodland.cream),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ListenableBuilder(
                listenable: Listenable.merge([game, ads]),
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            'assets/icons/app-brand.webp',
                            width: 64,
                            height: 64,
                            cacheWidth: 192,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Potion Post',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Deliver a little magic.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Woodland.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _group('PLAY YOUR WAY', [
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFFFF7DF),
                        activeTrackColor: const Color(0xFF347866),
                        inactiveThumbColor: const Color(0xFF819B8B),
                        inactiveTrackColor: const Color(0xFFE0E4D5),
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Color(0xFF9BB2A2),
                        ),
                        key: const ValueKey('settings-sound'),
                        secondary: const Icon(
                          Icons.volume_up_rounded,
                          color: Color(0xFF367360),
                        ),
                        title: const Text(
                          'Sound',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Potion and button sounds',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: game.sound,
                        onChanged: (v) {
                          game.setSettings(soundValue: v);
                          if (v) SystemSound.play(SystemSoundType.click);
                        },
                      ),
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFFFF7DF),
                        activeTrackColor: const Color(0xFF347866),
                        inactiveThumbColor: const Color(0xFF819B8B),
                        inactiveTrackColor: const Color(0xFFE0E4D5),
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Color(0xFF9BB2A2),
                        ),
                        key: const ValueKey('settings-haptics'),
                        secondary: const Icon(
                          Icons.vibration_rounded,
                          color: Color(0xFF367360),
                        ),
                        title: const Text(
                          'Haptics',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Gentle touch feedback',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: game.haptics,
                        onChanged: (v) {
                          game.setSettings(hapticsValue: v);
                          if (v) HapticFeedback.selectionClick();
                        },
                      ),
                      SwitchListTile(
                        activeThumbColor: const Color(0xFFFFF7DF),
                        activeTrackColor: const Color(0xFF347866),
                        inactiveThumbColor: const Color(0xFF819B8B),
                        inactiveTrackColor: const Color(0xFFE0E4D5),
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Color(0xFF9BB2A2),
                        ),
                        key: const ValueKey('settings-motion'),
                        secondary: const Icon(
                          Icons.motion_photos_off_rounded,
                          color: Color(0xFF367360),
                        ),
                        title: const Text(
                          'Reduce motion',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Calmer scenes and celebrations',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: game.reduceMotion,
                        onChanged: (v) => game.setSettings(motionValue: v),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    _group('YOUR JOURNEY', [
                      _row(
                        Icons.copy_rounded,
                        'Copy progress',
                        'Keep a backup of your journey',
                        onCopy,
                      ),
                      _row(
                        Icons.restore_rounded,
                        'Restore progress',
                        'Bring back a saved backup',
                        onRestore,
                      ),
                    ]),
                    const SizedBox(height: 18),
                    _group('HELP & INFORMATION', [
                      _row(
                        Icons.help_outline_rounded,
                        'How to play',
                        'Recipes, coins and deliveries',
                        onHelp,
                      ),
                      if (ads.enabled)
                        _row(
                          Icons.privacy_tip_outlined,
                          'Ads & privacy',
                          'How ads and optional rewards work',
                          () => _privacy(context),
                        ),
                    ]),
                    if (game.saveFailed)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: TextButton.icon(
                          onPressed: game.flush,
                          icon: const Icon(Icons.cloud_off_rounded),
                          label: const Text(
                            'Progress could not be saved · Retry',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Text(
              'Potion Post · $appBuildLabel',
              key: ValueKey('settings-build-version'),
              style: TextStyle(fontSize: 11, color: Woodland.muted),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _group(String title, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF557263),
          ),
        ),
      ),
      Material(
        color: Colors.white.withValues(alpha: .55),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE5DDC7)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    ],
  );

  Widget _row(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: const Color(0xFF367360)),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    onTap: onTap,
  );

  void _privacy(BuildContext context) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Ads & privacy'),
      content: SingleChildScrollView(
        child: Text(
          'Potion Post uses Google Mobile Ads. Ads need an internet connection and appear only when available. The SDK processes device and network information to deliver ads. Requests ask for non-personalized ads and general-audience content.\n\nWatching a rewarded ad is optional. A completed reward can grant in-game coins or the tool refill shown before the ad. Closing or skipping without earning a reward adds nothing. Coins have no cash value.\n\nProgress and game settings are saved on this device. Copy progress to keep your own backup.'
          '${ads.usesDemoAds ? '\n\nThis build uses Google demo ad units while publisher IDs are being prepared.' : ''}',
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
