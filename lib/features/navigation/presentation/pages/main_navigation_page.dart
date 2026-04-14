import 'package:flutter/material.dart';

import '../../../home/presentation/pages/home_page.dart';
import 'tabs/cart_page.dart';
import 'tabs/favourites_page.dart';
import 'tabs/profile_page.dart';
import 'tabs/search_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  static const _pages = [
    HomePage(),
    SearchPage(),
    CartPage(),
    FavouritesPage(),
    ProfilePage(),
  ];

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      activeIcon: Icon(Icons.search_rounded),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart_outlined),
      activeIcon: Icon(Icons.shopping_cart_rounded),
      label: 'Cart',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite_border_rounded),
      activeIcon: Icon(Icons.favorite_rounded),
      label: 'Wishlist',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBarTheme(
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
          selectedIndex: _currentIndex,
          height: 72,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surface,
          destinations: _items
              .map(
                (item) => NavigationDestination(
                  icon: item.icon,
                  selectedIcon: item.activeIcon,
                  label: item.label!,
                ),
              )
              .toList(),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
