import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../vendor/data/models/vendor_application_model.dart';
import '../../../vendor/domain/entities/vendor_application_entity.dart';
import '../../../vendor/domain/repositories/vendor_repository.dart';

class VendorApplicationDetailAdminPage extends StatelessWidget {
  const VendorApplicationDetailAdminPage({
    super.key,
    required this.applicationId,
  });

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<VendorRepository>();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('vendor_applications')
            .where(FieldPath.documentId, isEqualTo: applicationId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final app = VendorApplicationModel.fromFirestore(snap.data!.docs.first);
          return _ApplicationDetailView(application: app);
        },
      ),
    );
  }
}

class _ApplicationDetailView extends StatelessWidget {
  const _ApplicationDetailView({required this.application});

  final VendorApplicationEntity application;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<VendorRepository>();
    final user = FirebaseAuth.instance.currentUser;
    final commentController = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/admin/vendor-applications'),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'Vendor Application: ${application.storeName}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    _StatusChip(status: application.status),
                    SizedBox(height: 24.h),
                    _SectionTitle('Basic Business Information'),
                    _InfoRow('Store Name', application.storeName),
                    _InfoRow('Owner Full Name', application.ownerName),
                    _InfoRow('Mobile Number', application.mobileNumber),
                    _InfoRow('Email Address', application.email),
                    _InfoRow('Business Type', _businessTypeToString(application.businessType)),
                    _InfoRow('Years in Business', application.yearsInBusiness ?? 'Not provided'),
                    SizedBox(height: 24.h),
                    _SectionTitle('Business Address'),
                    _InfoRow('Complete Shop Address', application.shopAddress ?? 'Not provided'),
                    _InfoRow('Landmark', application.landmark ?? 'Not provided'),
                    _InfoRow('City', application.city ?? 'Not provided'),
                    _InfoRow('State', application.state ?? 'Not provided'),
                    _InfoRow('PIN Code', application.pinCode ?? 'Not provided'),
                    SizedBox(height: 24.h),
                    _SectionTitle('Documents'),
                    if (application.aadhaarUrl != null)
                      _DocumentPreview('Aadhaar Card', application.aadhaarUrl!),
                    if (application.panUrl != null)
                      _DocumentPreview('PAN Card', application.panUrl!),
                    _InfoRow('GST Number', application.gstNumber ?? 'Not provided'),
                    if (application.gstCertificateUrl != null)
                      _DocumentPreview('GST Certificate', application.gstCertificateUrl!),
                    _InfoRow('FSSAI Number', application.fssaiNumber ?? 'Not provided'),
                    if (application.fssaiCertificateUrl != null)
                      _DocumentPreview('FSSAI Certificate', application.fssaiCertificateUrl!),
                    SizedBox(height: 24.h),
                    _SectionTitle('Bank Details'),
                    _InfoRow('Account Holder Name', application.bankAccountHolderName ?? 'Not provided'),
                    _InfoRow('Bank Name', application.bankName ?? 'Not provided'),
                    _InfoRow('Account Number', application.bankAccountNumber ?? 'Not provided'),
                    _InfoRow('IFSC Code', application.bankIfscCode ?? 'Not provided'),
                    _InfoRow('UPI ID', application.upiId ?? 'Not provided'),
                    SizedBox(height: 24.h),
                    _SectionTitle('Store Information'),
                    _InfoRow('Store Opening Time', application.storeOpeningTime ?? 'Not provided'),
                    _InfoRow('Store Closing Time', application.storeClosingTime ?? 'Not provided'),
                    _InfoRow('Weekly Off Days', application.weeklyOffDays?.join(', ') ?? 'Not provided'),
                    _InfoRow('Emergency Contact Number', application.emergencyContactNumber ?? 'Not provided'),
                    SizedBox(height: 24.h),
                    _SectionTitle('Store Media'),
                    if (application.storeLogoUrl != null)
                      _ImagePreview('Store Logo', application.storeLogoUrl!),
                    if (application.storeFrontImageUrl != null)
                      _ImagePreview('Store Front', application.storeFrontImageUrl!),
                    if (application.storeInteriorImageUrl != null)
                      _ImagePreview('Store Interior', application.storeInteriorImageUrl!),
                    SizedBox(height: 24.h),
                    _SectionTitle('Review'),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Review Comment',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await repo.updateVendorApplicationStatus(
                              applicationId: application.id,
                              status: 'under_review',
                              reviewedBy: user?.email,
                              reviewComment: commentController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Status updated to Under Review')),
                              );
                            }
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Mark as Under Review'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await repo.updateVendorApplicationStatus(
                              applicationId: application.id,
                              status: 'documents_pending',
                              reviewedBy: user?.email,
                              reviewComment: commentController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Status updated to Documents Pending')),
                              );
                            }
                          },
                          icon: const Icon(Icons.pending_actions),
                          label: const Text('Request More Documents'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await repo.updateVendorApplicationStatus(
                              applicationId: application.id,
                              status: 'approved',
                              reviewedBy: user?.email,
                              reviewComment: commentController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Application Approved')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Approve'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await repo.updateVendorApplicationStatus(
                              applicationId: application.id,
                              status: 'rejected',
                              reviewedBy: user?.email,
                              reviewComment: commentController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Application Rejected')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180.w,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview(this.label, this.url);

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          const Icon(Icons.description),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(label),
          ),
          TextButton(
            onPressed: () {
              // TODO: Open the document
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview(this.label, this.url);

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              height: 200.h,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
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
