import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../admin/domain/repositories/admin_customer_repository.dart';
import '../../../../common/domain/entities/order_entity.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: const FreshVeggieHeader(),
        body: _EmptyOrderState(
          icon: Icons.receipt_long_outlined,
          title: 'Sign in to view orders',
          subtitle: 'Your placed orders will appear here once you are logged in.',
        ),
      );
    }

    final repository = getIt<AdminCustomerRepository>();

    return Scaffold(
      appBar: const FreshVeggieHeader(),
      body: StreamBuilder<List<OrderEntity>>(
        stream: repository.watchOrdersForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _EmptyOrderState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load orders',
              subtitle: 'Please try again in a moment.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? const <OrderEntity>[];
          if (orders.isEmpty) {
            return _EmptyOrderState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Orders you place from the cart will show up here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
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
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(order.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.shopping_bag_outlined,
                label: '$itemCount item${itemCount == 1 ? '' : 's'}',
              ),
              _InfoChip(
                icon: Icons.payments_outlined,
                label: formatCurrency(order.total),
              ),
            ],
          ),
          if (order.shippingAddress?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(
              'Delivery address',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              order.shippingAddress!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Items',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _buildItemTitle(item.quantity, item.unitType, item.name),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unit price: ${formatCurrency(item.unitPrice)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatCurrency(item.lineTotal),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = status.trim().toLowerCase();

    Color background;
    Color foreground;

    switch (normalized) {
      case 'delivered':
        background = Colors.green.withValues(alpha: 0.12);
        foreground = Colors.green.shade800;
        break;
      case 'cancelled':
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        break;
      case 'processing':
      case 'shipped':
        background = Colors.orange.withValues(alpha: 0.15);
        foreground = Colors.orange.shade800;
        break;
      default:
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _titleCase(normalized),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return 'Pending';
  return value[0].toUpperCase() + value.substring(1);
}

String _buildItemTitle(int quantity, String? unitType, String name) {
  final cleanUnitType = unitType?.trim();
  if (cleanUnitType == null || cleanUnitType.isEmpty) {
    return '$quantity x $name';
  }

  return '$quantity $cleanUnitType x $name';
}
