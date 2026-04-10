import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'admin_sidebar.dart';
import '../../../../core/theme/theme_cubit.dart';

/// Shell layout: responsive sidebar / drawer + main content.
class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;
    final useDrawer = !useRail;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('FreshVeggie Admin'),
        leading: useDrawer
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDark = themeMode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                icon: Icon(isDark ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: useDrawer
          ? Drawer(
              child: AdminSidebar(
                onNavigate: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (useRail)
            SizedBox(
              width: 240.w,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
                child: AdminSidebar(onNavigate: () {}),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
