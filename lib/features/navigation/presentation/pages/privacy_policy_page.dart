import 'package:flutter/material.dart';

import '../../../../core/widgets/fresh_veggie_header.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FreshVeggieHeader(
        title: 'Privacy Policy',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: const [
          _PolicyHeroCard(),
          SizedBox(height: 20),
          _PolicySection(
            title: 'Information we collect',
            paragraphs: [
              'We collect the details you provide while creating an account, placing an order, or contacting support. This may include your name, phone number, email address, delivery address, and order history.',
              'Basic device and app usage information may also be processed to improve reliability, security, and app performance.',
            ],
          ),
          _PolicySection(
            title: 'How we use your data',
            paragraphs: [
              'Your information is used to process orders, coordinate deliveries, send order updates, respond to support requests, and improve the shopping experience.',
              'We may also use operational data to prevent fraud, troubleshoot technical issues, and maintain service quality.',
            ],
          ),
          _PolicySection(
            title: 'When data may be shared',
            paragraphs: [
              'We only share the information needed to fulfill your order or operate the service, such as with delivery partners, payment providers, or infrastructure services.',
              'We may also disclose information if required by law, legal process, or to protect users, the app, or the business from misuse.',
            ],
          ),
          _PolicySection(
            title: 'Your choices',
            paragraphs: [
              'You can review the information tied to your account through the app and contact support if you need help correcting order-related details.',
              'If you no longer want to use the service, you can sign out of your account at any time. Additional account or data requests can be directed to support.',
            ],
          ),
          _PolicySection(
            title: 'Data protection',
            paragraphs: [
              'We take reasonable steps to protect personal information through secure tools, controlled access, and service monitoring. No digital system can guarantee absolute security, but protecting customer trust is a priority.',
            ],
          ),
          _PolicySection(
            title: 'Policy updates',
            paragraphs: [
              'This policy may be updated as the app evolves, business processes change, or legal requirements require clarification. Continued use of the app after updates means the revised policy applies.',
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicyHeroCard extends StatelessWidget {
  const _PolicyHeroCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer.withValues(alpha: 0.92),
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
              Icons.verified_user_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your privacy matters',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This page explains what information Bajariyo uses, why it is used, and the choices customers have while using the app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            ...paragraphs.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  paragraph,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
