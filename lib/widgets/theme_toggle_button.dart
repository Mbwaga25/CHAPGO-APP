import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A sun/moon icon button that flips the app between light and dark mode.
class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return IconButton(
      tooltip: theme.isDark ? 'Light mode' : 'Dark mode',
      icon: Icon(theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: color),
      onPressed: () => context.read<ThemeProvider>().toggle(),
    );
  }
}
