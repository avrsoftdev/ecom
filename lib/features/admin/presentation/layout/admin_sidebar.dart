import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.onNavigate});

  final VoidCallback onNavigate;

  static const _items = <_NavItem>[
    _NavItem('/admin/dashboard', Icons.dashboard_rounded, 'Dashboard'),
    _NavItem('/admin/products', Icons.inventory_2_rounded, 'Products'),
    _NavItem('/admin/categories', Icons.category_rounded, 'Categories'),
    _NavItem('/admin/orders', Icons.receipt_long_rounded, 'Orders'),
    _NavItem('/admin/banners', Icons.view_carousel_rounded, 'Banners'),
    _NavItem('/admin/customers', Icons.people_rounded, 'Customers'),
    _NavItem('/admin/settings', Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Row(
            children: [
              Icon(Icons.eco_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'Admin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ..._items.map(
          (e) {
            final selected = loc == e.path || loc.startsWith('${e.path}/');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                selected: selected,
                selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(e.icon),
                title: Text(e.label),
                onTap: () {
                  context.go(e.path);
                  onNavigate();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String label;
}
