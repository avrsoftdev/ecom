import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../common/domain/entities/customer_profile_entity.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../domain/repositories/admin_customer_repository.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<AdminCustomerRepository>();

    return FutureBuilder<Either<Failure, CustomerProfileEntity?>>(
      future: repo.getById(customerId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snap.data;
        if (result == null) return const Center(child: Text('Error'));

        return result.fold(
          (f) => Center(child: Text(f.message)),
          (customer) {
            if (customer == null) return const Center(child: Text('Customer not found'));

            return SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.displayName ?? customer.email,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8.h),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${customer.email}'),
                          if (customer.phone != null) Text('Phone: ${customer.phone}'),
                          if (customer.address != null) Text('Address: ${customer.address}'),
                          Text('Role: ${customer.role}'),
                          Text('Created: ${DateFormat.yMMMd().format(customer.createdAt)}'),
                          if (customer.lastSignInAt != null)
                            Text('Last sign in: ${DateFormat.yMMMd().add_jm().format(customer.lastSignInAt!)}'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  StreamBuilder<List<OrderEntity>>(
                    stream: repo.watchOrdersForUser(customer.id),
                    builder: (context, s2) {
                      if (s2.hasError) return Text('${s2.error}');
                      if (!s2.hasData) return const Center(child: CircularProgressIndicator());
                      final orders = s2.data!;
                      if (orders.isEmpty) return const Text('No orders yet.');
                      return Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Order')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Date')),
                            ],
                            rows: orders
                                .map(
                                  (o) => DataRow(
                                    cells: [
                                      DataCell(Text(o.id.length <= 10 ? o.id : o.id.substring(0, 10))),
                                      DataCell(Text(formatCurrency(o.total))),
                                      DataCell(Text(o.status)),
                                      DataCell(Text(DateFormat.yMMMd().format(o.createdAt))),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

