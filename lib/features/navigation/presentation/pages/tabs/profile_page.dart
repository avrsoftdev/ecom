import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../admin/domain/repositories/admin_customer_repository.dart';
import '../../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../common/domain/entities/customer_profile_entity.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repository = getIt<AdminCustomerRepository>();

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/login');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: const FreshVeggieHeader(),
        body: user == null
            ? const _LoggedOutState()
            : FutureBuilder(
                future: repository.getById(user.uid),
                builder: (context, snapshot) {
                  final profile = snapshot.data?.fold(
                    (_) => null,
                    (value) => value,
                  );
                  final isLoadingProfile =
                      snapshot.connectionState == ConnectionState.waiting;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileHero(
                            user: user,
                            profile: profile,
                            isLoadingProfile: isLoadingProfile,
                          ),
                          const SizedBox(height: 16),
                          const _SectionTitle('Quick actions'),
                          const SizedBox(height: 10),
                          _ActionCard(
                            icon: Icons.receipt_long_rounded,
                            title: 'Order history',
                            subtitle: 'Track all your placed orders',
                            onTap: () => context.go('/orders'),
                          ),
                          _ActionCard(
                            icon: Icons.favorite_rounded,
                            title: 'Saved items',
                            subtitle: 'Review products in your wishlist',
                            onTap: () => context.go('/wishlist'),
                          ),
                          _ActionCard(
                            icon: Icons.shopping_cart_rounded,
                            title: 'Cart',
                            subtitle: 'Continue checkout from your cart',
                            onTap: () => context.go('/cart'),
                          ),
                          const SizedBox(height: 14),
                          const _SectionTitle('Support & preferences'),
                          const SizedBox(height: 10),
                          _ActionCard(
                            icon: Icons.help_center_rounded,
                            title: 'Help center',
                            subtitle: 'Get support for orders and account',
                            onTap: () => _showInfo(
                              context,
                              'Help center will be available soon.',
                            ),
                          ),
                          _ActionCard(
                            icon: Icons.policy_rounded,
                            title: 'Privacy & terms',
                            subtitle: 'Review app policies and guidelines',
                            onTap: () => _showInfo(
                              context,
                              'Policy pages will be available soon.',
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _SectionTitle('Security'),
                          const SizedBox(height: 10),
                          _LogoutButton(userEmail: user.email),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.profile,
    required this.isLoadingProfile,
  });

  final User user;
  final CustomerProfileEntity? profile;
  final bool isLoadingProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _displayName(
      firebaseName: user.displayName,
      profileName: profile?.displayName,
      email: user.email,
    );
    final email =
        profile?.email.isNotEmpty == true ? profile!.email : user.email;
    final phone = _firstNonEmpty(profile?.phone, user.phoneNumber);
    final address = profile?.address?.trim();
    final photo = _firstNonEmpty(profile?.photoUrl, user.photoURL);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onPrimaryContainer,
                              ),
                    ),
                    const SizedBox(height: 6),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                      ),
                    if (phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              CircleAvatar(
                radius: 34,
                backgroundColor: colorScheme.surface,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Icon(
                        Icons.person_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                icon: user.emailVerified
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                label: user.emailVerified
                    ? 'Email verified'
                    : 'Email not verified',
              ),
              if (isLoadingProfile)
                const _Pill(icon: Icons.sync_rounded, label: 'Loading account')
              else
                const _Pill(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Member',
                ),
            ],
          ),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              address,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.userEmail});

  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: isLoading
                ? null
                : () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Sign out?'),
                          content: Text(
                            userEmail == null
                                ? 'You will need to sign in again to access your account.'
                                : 'You are signing out from $userEmail.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Sign out'),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldLogout == true && context.mounted) {
                      context.read<AuthCubit>().signOut();
                    }
                  },
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onErrorContainer,
                      ),
                    ),
                  )
                : Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                  ),
            label: Text(isLoading ? 'Signing out...' : 'Sign out'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _LoggedOutState extends StatelessWidget {
  const _LoggedOutState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'You are not signed in',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please login to access your profile and account details.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _displayName({
  required String? firebaseName,
  required String? profileName,
  required String? email,
}) {
  final name = _firstNonEmpty(profileName, firebaseName);
  if (name != null) {
    return name;
  }
  if (email == null || email.trim().isEmpty) {
    return 'My Profile';
  }
  return email.split('@').first;
}

String? _firstNonEmpty(String? first, String? second) {
  if (first != null && first.trim().isNotEmpty) {
    return first.trim();
  }
  if (second != null && second.trim().isNotEmpty) {
    return second.trim();
  }
  return null;
}

