import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../admin/domain/repositories/admin_customer_repository.dart';
import '../../../../common/domain/entities/order_entity.dart';
import '../../../../common/domain/entities/order_item_entity.dart';

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
          subtitle:
              'Your placed orders will appear here once you are logged in.',
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
    final statusDetails = _OrderStatusDetails.fromStatus(order.status);
    final shortOrderId =
        order.id.length <= 8 ? order.id : order.id.substring(0, 8);
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
                      'Order #${shortOrderId.toUpperCase()}',
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
              _StatusChip(details: statusDetails),
            ],
          ),
          const SizedBox(height: 16),
          _OrderStatusSummary(details: statusDetails),
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
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                _OrderItemsHeader(colorScheme: colorScheme),
                ...order.items.map(
                  (item) => _OrderItemRow(item: item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusSummary extends StatelessWidget {
  const _OrderStatusSummary({required this.details});

  final _OrderStatusDetails details;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: details.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: details.foreground.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(details.icon, size: 22, color: details.foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  details.customerMessage,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: details.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusStep(
                label: 'Soon',
                isActive: details.step >= 0,
                color: details.foreground,
              ),
              _StatusLine(
                  isActive: details.step >= 1, color: details.foreground),
              _StatusStep(
                label: 'Dispatched',
                isActive: details.step >= 1,
                color: details.foreground,
              ),
              _StatusLine(
                  isActive: details.step >= 2, color: details.foreground),
              _StatusStep(
                label: 'Delivered',
                isActive: details.step >= 2,
                color: details.foreground,
              ),
            ],
          ),
          if (details.isCancelled) ...[
            const SizedBox(height: 8),
            Text(
              'Please contact support if you need help with this order.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.label,
    required this.isActive,
    required this.color,
  });

  final String label;
  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Theme.of(context).colorScheme.outline;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? color : inactiveColor),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: isActive ? Colors.white : Colors.transparent,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 82,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? color : inactiveColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.isActive,
    required this.color,
  });

  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isActive ? color : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _OrderItemsHeader extends StatelessWidget {
  const _OrderItemsHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text('Qty', style: labelStyle),
          ),
          Expanded(
            flex: 3,
            child: Text('Item', style: labelStyle),
          ),
          SizedBox(
            width: 84,
            child: Text(
              'Unit Price',
              style: labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'Amt',
              style: labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tierLabel = item.tierLabel?.trim();
    final hasTierLabel = tierLabel != null && tierLabel.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${item.quantity}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (hasTierLabel) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tier: $tierLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              formatCurrency(item.unitPrice),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              formatCurrency(item.lineTotal),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.details});

  final _OrderStatusDetails details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: details.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        details.chipLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: details.foreground,
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

class _OrderStatusDetails {
  const _OrderStatusDetails({
    required this.chipLabel,
    required this.customerMessage,
    required this.step,
    required this.icon,
    required this.background,
    required this.foreground,
    this.isCancelled = false,
  });

  final String chipLabel;
  final String customerMessage;
  final int step;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool isCancelled;

  factory _OrderStatusDetails.fromStatus(String status) {
    final normalized = status.trim().toLowerCase();

    switch (normalized) {
      case 'delivered':
        return _OrderStatusDetails(
          chipLabel: 'Delivered',
          customerMessage: 'Your Order has been Delivered',
          step: 2,
          icon: Icons.check_circle_outline_rounded,
          background: Colors.green.withValues(alpha: 0.12),
          foreground: Colors.green.shade800,
        );
      case 'dispatched':
      case 'shipped':
      case 'out_for_delivery':
        return _OrderStatusDetails(
          chipLabel: 'Dispatched',
          customerMessage: 'Your Order has been Dispatched',
          step: 1,
          icon: Icons.local_shipping_outlined,
          background: Colors.orange.withValues(alpha: 0.15),
          foreground: Colors.orange.shade800,
        );
      case 'cancelled':
        return _OrderStatusDetails(
          chipLabel: 'Cancelled',
          customerMessage: 'Your Order has been Cancelled',
          step: -1,
          icon: Icons.cancel_outlined,
          background: Colors.red.withValues(alpha: 0.12),
          foreground: Colors.red.shade800,
          isCancelled: true,
        );
      case 'pending':
      case 'processing':
      default:
        return _OrderStatusDetails(
          chipLabel: 'Soon',
          customerMessage: 'Your Order will be Delivered Soon',
          step: 0,
          icon: Icons.schedule_outlined,
          background: Colors.blue.withValues(alpha: 0.12),
          foreground: Colors.blue.shade800,
        );
    }
  }
}
