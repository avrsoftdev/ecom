import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/theme_cubit.dart';

class FreshVeggieHeader extends StatelessWidget implements PreferredSizeWidget {
  const FreshVeggieHeader({
    super.key,
    this.title = 'FreshVeggie',
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      title: Text(title),
      centerTitle: true,
      actions: [
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDarkMode = themeMode == ThemeMode.dark;

            return IconButton(
              tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              icon: Icon(
                isDarkMode
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
              ),
            );
          },
        ),
      ],
    );
  }
}
