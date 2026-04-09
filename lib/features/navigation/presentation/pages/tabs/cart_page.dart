import 'package:flutter/material.dart';

import '../../widgets/navigation_tab_scaffold.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavigationTabScaffold(
      title: 'My Cart',
      icon: Icons.shopping_cart_outlined,
      description: 'Add fresh vegetables to your cart and review them here.',
    );
  }
}
