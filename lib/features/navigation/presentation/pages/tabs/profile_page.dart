import 'package:flutter/material.dart';

import '../../widgets/navigation_tab_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavigationTabScaffold(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      description: 'Manage your account details, preferences, and orders here.',
    );
  }
}
