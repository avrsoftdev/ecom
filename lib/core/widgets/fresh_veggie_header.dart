import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme_cubit.dart';

class FreshVeggieHeader extends StatelessWidget implements PreferredSizeWidget {
  const FreshVeggieHeader({
    super.key,
    this.title = 'Bajariyo',
  });

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF006400),
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          textStyle: (Theme.of(context).appBarTheme.titleTextStyle ??
                  Theme.of(context).textTheme.titleLarge)
              ?.copyWith(color: Colors.white),
        ),
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDarkMode = themeMode == ThemeMode.dark;

            return IconButton(
              tooltip:
                  isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
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
