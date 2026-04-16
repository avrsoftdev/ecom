import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../wishlist/presentation/cubits/wishlist_cubit.dart';
import '../../../wishlist/presentation/widgets/cart_icon_with_badge.dart';

class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  List<NavigationDestination> _buildNavigationItems(BuildContext context, int cartCount) {
    return [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search_rounded),
        label: 'Search',
      ),
      NavigationDestination(
        icon: CartIconWithBadge(
          itemCount: cartCount,
          icon: Icons.shopping_cart_outlined,
        ),
        selectedIcon: CartIconWithBadge(
          itemCount: cartCount,
          icon: Icons.shopping_cart_rounded,
        ),
        label: 'Cart',
      ),
      NavigationDestination(
        icon: Icon(Icons.favorite_border_rounded),
        selectedIcon: Icon(Icons.favorite_rounded),
        label: 'Wishlist',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          final cartCount = state is WishlistLoaded 
              ? state.wishlistItems.values.fold(0, (sum, quantity) => sum + quantity)
              : 0;

          return NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: colorScheme.secondaryContainer,
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontSize: 12,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              height: 72,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surface,
              destinations: _buildNavigationItems(context, cartCount),
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
