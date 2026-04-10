import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../domain/repositories/admin_order_repository.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<Either<Failure, OrderEntity?>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = getIt<AdminOrderRepository>().getOrderById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final repo = getIt<AdminOrderRepository>();

    return FutureBuilder<Either<Failure, OrderEntity?>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snap.data;
        if (result == null) {
          return const Center(child: Text('Error'));
        }
        return result.fold(
          (f) => Center(child: Text(f.message)),
          (order) {
            if (order == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Order not found'),
                    TextButton(onPressed: () => context.go('/admin/orders'), child: const Text('Back')),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Order ${order.id}', style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      DropdownButton<String>(
                        value: order.status,
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('pending')),
                          DropdownMenuItem(value: 'processing', child: Text('processing')),
                          DropdownMenuItem(value: 'shipped', child: Text('shipped')),
                          DropdownMenuItem(value: 'delivered', child: Text('delivered')),
                          DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                        ],
                        onChanged: (v) async {
                          if (v == null) return;
                          await repo.updateOrderStatus(order.id, v);
                          if (mounted) {
                            setState(_reload);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text('Customer: ${order.customerName ?? '-'}'),
                  Text('Email: ${order.customerEmail ?? '-'}'),
                  Text('Phone: ${order.phone ?? '-'}'),
                  Text('Address: ${order.shippingAddress ?? '-'}'),
                  SizedBox(height: 16.h),
                  Text('Items', style: Theme.of(context).textTheme.titleMedium),
                  Card(
                    child: Column(
                      children: order.items
                          .map(
                            (i) => ListTile(
                              title: Text(i.name),
                              subtitle: Text('Qty ${i.quantity} × ${currency.format(i.unitPrice)}'),
                              trailing: Text(currency.format(i.lineTotal)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text('Subtotal: ${currency.format(order.subtotal)}'),
                  Text('Delivery: ${currency.format(order.deliveryCharge)}'),
                  Text('Tax: ${currency.format(order.tax)}'),
                  Text('Total: ${currency.format(order.total)}', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
