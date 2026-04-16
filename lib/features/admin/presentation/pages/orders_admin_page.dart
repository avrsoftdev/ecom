import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../domain/repositories/admin_order_repository.dart';

class OrdersAdminPage extends StatelessWidget {
  const OrdersAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<AdminOrderRepository>();

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Orders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: StreamBuilder<List<OrderEntity>>(
              stream: repo.watchOrders(limit: 100),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data!;
                if (orders.isEmpty) {
                  return const Center(child: Text('No orders yet'));
                }
                return Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('')),
                      ],
                      rows: orders
                          .map(
                            (o) => DataRow(
                              cells: [
                                DataCell(Text(o.id.length <= 10 ? o.id : o.id.substring(0, 10))),
                                DataCell(Text(o.customerEmail ?? o.userId)),
                                DataCell(Text(formatCurrency(o.total))),
                                DataCell(Text(o.status)),
                                DataCell(Text(DateFormat.yMMMd().format(o.createdAt))),
                                DataCell(
                                  TextButton(
                                    onPressed: () => context.go('/admin/orders/${o.id}'),
                                    child: const Text('Details'),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
