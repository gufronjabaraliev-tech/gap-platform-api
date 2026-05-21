import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Kun / tun — bitta tugma.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Tooltip(
      message: theme.isDark ? 'Kunduzgi rejim' : 'Tungi rejim',
      child: IconButton(
        onPressed: theme.toggleDayNight,
        icon: Icon(theme.modeIcon, color: iconColor),
      ),
    );
  }
}
