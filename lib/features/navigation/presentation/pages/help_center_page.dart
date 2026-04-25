import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/fresh_veggie_header.dart';
import '../../../admin/domain/repositories/admin_settings_repository.dart';
import '../../../common/domain/entities/store_settings_entity.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = getIt<AdminSettingsRepository>();

    return Scaffold(
      appBar: const FreshVeggieHeader(
        title: 'Help Center',
        showBackButton: true,
      ),
      body: FutureBuilder<Either<Failure, StoreSettingsEntity>>(
        future: repository.getStoreSettings(),
        builder: (context, snapshot) {
          final settings = snapshot.data?.fold<StoreSettingsEntity?>(
            (_) => null,
            (value) => value,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              _HeroCard(settings: settings),
              const SizedBox(height: 20),
              const _SectionTitle('Contact support'),
              const SizedBox(height: 10),
              _ContactTile(
                icon: Icons.email_outlined,
                title: 'Email us',
                value: settings?.supportEmail ?? 'support@bajariyo.com',
                caption: 'Best for account help, feedback, and order issues.',
              ),
              _ContactTile(
                icon: Icons.call_outlined,
                title: 'Call support',
                value: settings?.supportPhone ?? '+91 98765 43210',
                caption: 'Reach us faster for urgent delivery concerns.',
              ),
              _ContactTile(
                icon: Icons.location_on_outlined,
                title: 'Store address',
                value:
                    settings?.supportAddress ?? 'Fresh groceries, delivered to your door.',
                caption: 'Use this when you need store or pickup details.',
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Popular questions'),
              const SizedBox(height: 10),
              const _FaqCard(
                icon: Icons.local_shipping_outlined,
                title: 'Where is my order?',
                body:
                    'Open Order History from your profile to track recent orders and review their latest status.',
              ),
              const _FaqCard(
                icon: Icons.payments_outlined,
                title: 'How do refunds work?',
                body:
                    'If an item is missing, damaged, or unavailable, contact support with your order details so the team can review the issue.',
              ),
              const _FaqCard(
                icon: Icons.manage_accounts_outlined,
                title: 'How do I update my account details?',
                body:
                    'Your profile reflects the account you used to sign in. Reach out to support if you need help correcting contact information tied to an order.',
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Before you contact us'),
              const SizedBox(height: 10),
              const _ChecklistCard(
                items: [
                  'Keep your order number ready if the issue is about a delivery.',
                  'Mention the item name and quantity for missing or incorrect products.',
                  'Share the phone number or email used during checkout for faster verification.',
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.settings});

  final StoreSettingsEntity? settings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCustomSupportDetails = [
      settings?.supportEmail,
      settings?.supportPhone,
      settings?.supportAddress,
    ].any((value) => value != null && value.trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'We are here to help',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hasCustomSupportDetails
                ? 'Reach the Bajariyo support team using the contact options below.'
                : 'Support details have not been customized yet, so fallback contact information is shown below.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
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
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            )
            .toList(),
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
