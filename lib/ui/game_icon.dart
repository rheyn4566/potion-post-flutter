import 'package:flutter/material.dart';

import 'art_cache.dart';

/// Shared illustrated icons, rendered from the included editable SVG sources.
class GameIcon extends StatelessWidget {
  const GameIcon(this.name, {super.key, this.size = 26});
  final String name;
  final double size;

  static final materialNames = <IconData, String>{
    Icons.settings_rounded: 'settings',
    Icons.settings_outlined: 'settings',
    Icons.stars_rounded: 'stamp',
    Icons.favorite_rounded: 'album',
    Icons.play_arrow_rounded: 'play',
    Icons.today_rounded: 'daily',
    Icons.grid_view_rounded: 'orders',
    Icons.mail_outline_rounded: 'orders',
    Icons.palette_rounded: 'palette',
    Icons.palette_outlined: 'palette',
    Icons.help_outline_rounded: 'help',
    Icons.lightbulb_outline_rounded: 'hint',
    Icons.undo_rounded: 'undo',
    Icons.restart_alt_rounded: 'reset',
    Icons.arrow_back_rounded: 'home',
    Icons.home_rounded: 'home',
    Icons.pause_rounded: 'pause',
    Icons.mail_rounded: 'mail',
    Icons.star_rounded: 'star',
    Icons.star_outline_rounded: 'star',
    Icons.lock_outline_rounded: 'lock',
    Icons.arrow_forward_rounded: 'arrow',
    Icons.chevron_right_rounded: 'arrow',
    Icons.check_circle_rounded: 'check',
  };

  static Widget fromMaterial(IconData icon, {double size = 26}) {
    final name = materialNames[icon];
    return name == null ? Icon(icon, size: size) : GameIcon(name, size: size);
  }

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icons/${name == 'stamp' ? 'coin-leaf' : name}.png',
    frameBuilder: revealArtFrame,
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.high,
  );
}
