import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/fresh_veggie_header.dart';
import '../../domain/entities/vendor_application_entity.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../cubits/vendor_application_cubit.dart';

class VendorApplicationPage extends StatelessWidget {
  const VendorApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorApplicationCubit(getIt<VendorRepository>()),
      child: const _VendorApplicationView(),
    );
  }
}

class _VendorApplicationView extends StatefulWidget {
  const _VendorApplicationView();

  @override
  State<_VendorApplicationView> createState() => _VendorApplicationViewState();
}

class _VendorApplicationViewState extends State<_VendorApplicationView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VendorApplicationCubit>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: const FreshVeggieHeader(),
      body: BlocConsumer<VendorApplicationCubit, VendorApplicationState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Application submitted successfully! We will review it soon.')),
            );
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.existingApplication != null) {
            return _ExistingApplicationView(
                application: state.existingApplication!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Become a Vendor',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill out the form below to apply to become a vendor on Bazariyo.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Basic Business Info Section
                  _SectionTitle('Basic Business Information'),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Store Name *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.storeName,
                    onChanged: cubit.updateStoreName,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Owner Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.ownerName,
                    onChanged: cubit.updateOwnerName,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    initialValue: state.mobileNumber,
                    onChanged: cubit.updateMobileNumber,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    initialValue:
                        state.email.isEmpty ? user?.email ?? '' : state.email,
                    onChanged: cubit.updateEmail,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BusinessType>(
                    decoration: const InputDecoration(
                      labelText: 'Business Type *',
                      border: OutlineInputBorder(),
                    ),
                    value: state.businessType,
                    items: BusinessType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_businessTypeToString(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        cubit.updateBusinessType(value ?? BusinessType.other),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Years in Business (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: state.yearsInBusiness,
                    onChanged: cubit.updateYearsInBusiness,
                  ),
                  const SizedBox(height: 32),

                  // Business Address Section
                  _SectionTitle('Business Address'),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Complete Shop Address *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    initialValue: state.shopAddress,
                    onChanged: cubit.updateShopAddress,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Landmark',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.landmark,
                    onChanged: cubit.updateLandmark,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: state.city,
                          onChanged: cubit.updateCity,
                          validator: (value) =>
                              value?.isEmpty == true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: state.state,
                          onChanged: cubit.updateState,
                          validator: (value) =>
                              value?.isEmpty == true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'PIN Code *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: state.pinCode,
                    onChanged: cubit.updatePinCode,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Map picker placeholder
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Store Location (Map Picker)'),
                          const SizedBox(height: 8),
                          if (state.latitude != null && state.longitude != null)
                            Text(
                                'Lat: ${state.latitude}, Lng: ${state.longitude}'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // TODO: Implement map picker
                              // For now, just set dummy coordinates
                              cubit.updateLocation(19.0760, 72.8777);
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Pick Location on Map'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Business Documents Section
                  _SectionTitle('Business Documents'),
                  const SizedBox(height: 16),
                  _ImageUploadField(
                    label: 'Aadhaar Card Upload *',
                    file: state.aadhaarImage,
                    onPick: (file) => cubit.updateAadhaarImage(file),
                  ),
                  const SizedBox(height: 16),
                  _ImageUploadField(
                    label: 'PAN Card Upload *',
                    file: state.panImage,
                    onPick: (file) => cubit.updatePanImage(file),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'GST Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.gstNumber,
                    onChanged: cubit.updateGstNumber,
                  ),
                  const SizedBox(height: 16),
                  _ImageUploadField(
                    label: 'GST Certificate Upload (Optional)',
                    file: state.gstCertificateImage,
                    onPick: (file) => cubit.updateGstCertificateImage(file),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'FSSAI License Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.fssaiNumber,
                    onChanged: cubit.updateFssaiNumber,
                  ),
                  const SizedBox(height: 16),
                  _ImageUploadField(
                    label: 'FSSAI Certificate Upload (Optional)',
                    file: state.fssaiCertificateImage,
                    onPick: (file) => cubit.updateFssaiCertificateImage(file),
                  ),
                  const SizedBox(height: 32),

                  // Bank Details Section
                  _SectionTitle('Bank Details'),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.bankAccountHolderName,
                    onChanged: cubit.updateBankAccountHolderName,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Bank Name *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.bankName,
                    onChanged: cubit.updateBankName,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Account Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: state.bankAccountNumber,
                    onChanged: cubit.updateBankAccountNumber,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.bankIfscCode,
                    onChanged: cubit.updateBankIfscCode,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'UPI ID (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: state.upiId,
                    onChanged: cubit.updateUpiId,
                  ),
                  const SizedBox(height: 32),

                  // Store Information Section
                  _SectionTitle('Store Information'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null && mounted) {
                              cubit.updateStoreOpeningTime(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Store Opening Time *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(state.storeOpeningTime ?? 'Select'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null && mounted) {
                              cubit.updateStoreClosingTime(
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Store Closing Time *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(state.storeClosingTime ?? 'Select'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Weekly Off Days:'),
                  ...[
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ].map(
                    (day) => CheckboxListTile(
                      title: Text(day),
                      value: state.weeklyOffDays?.contains(day) ?? false,
                      onChanged: (selected) {
                        final currentDays =
                            List<String>.from(state.weeklyOffDays ?? []);
                        if (selected == true) {
                          currentDays.add(day);
                        } else {
                          currentDays.remove(day);
                        }
                        cubit.updateWeeklyOffDays(currentDays);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    initialValue: state.emergencyContactNumber,
                    onChanged: cubit.updateEmergencyContactNumber,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),

                  // Store Media Section
                  _SectionTitle('Store Media'),
                  const SizedBox(height: 16),
                  _ImageUploadField(
                    label: 'Store Logo Upload *',
                    file: state.storeLogoImage,
                    onPick: (file) => cubit.updateStoreLogoImage(file),
                  ),
                  const SizedBox(height: 16),
                  _ImageUploadField(
                    label: 'Store Front Image Upload *',
                    file: state.storeFrontImage,
                    onPick: (file) => cubit.updateStoreFrontImage(file),
                  ),
                  const SizedBox(height: 16),
                  _ImageUploadField(
                    label: 'Store Interior Image Upload (Optional)',
                    file: state.storeInteriorImage,
                    onPick: (file) => cubit.updateStoreInteriorImage(file),
                  ),
                  const SizedBox(height: 32),

                  // Agreement Section
                  _SectionTitle('Agreement'),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text(
                        'I confirm all provided information is accurate.'),
                    value: state.isInformationAccurate,
                    onChanged: (value) =>
                        cubit.updateIsInformationAccurate(value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text(
                        'I agree to Bazariyo\'s Vendor Terms & Conditions.'),
                    value: state.agreedToTerms,
                    onChanged: (value) =>
                        cubit.updateAgreedToTerms(value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text(
                        'I understand that my application will be reviewed before approval.'),
                    value: state.understoodApprovalProcess,
                    onChanged: (value) =>
                        cubit.updateUnderstoodApprovalProcess(value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () {
                              if (_formKey.currentState!.validate() &&
                                  state.isInformationAccurate &&
                                  state.agreedToTerms &&
                                  state.understoodApprovalProcess &&
                                  state.aadhaarImage != null &&
                                  state.panImage != null &&
                                  state.storeLogoImage != null &&
                                  state.storeFrontImage != null &&
                                  state.storeOpeningTime != null &&
                                  state.storeClosingTime != null) {
                                cubit.submitApplication();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please fill all required fields and accept the agreements.')),
                                );
                              }
                            },
                      child: state.isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('Submit Application'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExistingApplicationView extends StatelessWidget {
  const _ExistingApplicationView({required this.application});

  final VendorApplicationEntity application;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendor Application Status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusChip(status: application.status),
                  const SizedBox(height: 16),
                  Text(
                    'Store Name: ${application.storeName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Owner Name: ${application.ownerName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted on: ${DateFormat.yMMMd().format(application.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (application.reviewComment != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Review Comment:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(application.reviewComment!),
                  ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _ImageUploadField extends StatelessWidget {
  const _ImageUploadField({
    required this.label,
    required this.file,
    required this.onPick,
  });

  final String label;
  final XFile? file;
  final Function(XFile?) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.gallery);
            onPick(image);
          },
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: file != null
                ? Center(
                    child: Text(
                      'Selected: ${file!.name}',
                      textAlign: TextAlign.center,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, size: 40),
                      SizedBox(height: 8),
                      Text('Tap to select file'),
                    ],
                  ),
          ),
        ),
      ],
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
