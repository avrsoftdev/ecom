import 'package:flutter/material.dart';

import '../../widgets/navigation_tab_scaffold.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavigationTabScaffold(
      title: 'Favourites',
      icon: Icons.favorite_border_rounded,
      description: 'Keep your most-loved produce close so you can shop faster.',
    );
  }
}
