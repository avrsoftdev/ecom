import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../vendor/domain/entities/vendor_application_entity.dart';
import '../../../vendor/domain/repositories/vendor_repository.dart';
import 'vendor_application_detail_admin_page.dart';

class VendorApplicationsAdminPage extends StatelessWidget {
  const VendorApplicationsAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<VendorRepository>();

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vendor Applications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: StreamBuilder<List<VendorApplicationEntity>>(
              stream: repo.watchAllVendorApplications(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final applications = snap.data!;
                if (applications.isEmpty) {
                  return const Center(child: Text('No applications yet'));
                }
                return Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Store Name')),
                        DataColumn(label: Text('Owner Name')),
                        DataColumn(label: Text('Business Type')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('')),
                      ],
                      rows: applications
                          .map(
                            (app) => DataRow(
                              cells: [
                                DataCell(Text(app.storeName)),
                                DataCell(Text(app.ownerName)),
                                DataCell(Text(_businessTypeToString(app.businessType))),
                                DataCell(_StatusChip(status: app.status)),
                                DataCell(Text(DateFormat.yMMMd().format(app.createdAt))),
                                DataCell(
                                  TextButton(
                                    onPressed: () => context.go('/admin/vendor-applications/${app.id}'),
                                    child: const Text('View'),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final VendorApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case VendorApplicationStatus.applied:
        color = Colors.blue;
        break;
      case VendorApplicationStatus.underReview:
        color = Colors.orange;
        break;
      case VendorApplicationStatus.documentsPending:
        color = Colors.red;
        break;
      case VendorApplicationStatus.approved:
        color = Colors.green;
        break;
      case VendorApplicationStatus.rejected:
        color = Colors.red;
        break;
      case VendorApplicationStatus.activeVendor:
        color = Colors.green;
        break;
    }

    return Chip(
      label: Text(
        _statusToString(status),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}

String _businessTypeToString(BusinessType type) {
  switch (type) {
    case BusinessType.groceryStore:
      return 'Grocery Store';
    case BusinessType.supermarket:
      return 'Supermarket';
    case BusinessType.dairy:
      return 'Dairy';
    case BusinessType.fruitsVegetables:
      return 'Fruits & Vegetables';
    case BusinessType.bakery:
      return 'Bakery';
    case BusinessType.other:
      return 'Other';
  }
}

String _statusToString(VendorApplicationStatus status) {
  switch (status) {
    case VendorApplicationStatus.applied:
      return 'Applied';
    case VendorApplicationStatus.underReview:
      return 'Under Review';
    case VendorApplicationStatus.documentsPending:
      return 'Documents Pending';
    case VendorApplicationStatus.approved:
      return 'Approved';
    case VendorApplicationStatus.rejected:
      return 'Rejected';
    case VendorApplicationStatus.activeVendor:
      return 'Active Vendor';
  }
}
