import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/fresh_veggie_header.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../location/presentation/cubits/location_cubit.dart';
import '../../../location/presentation/cubits/location_state.dart';
import '../cubits/checkout_cubit.dart';
import '../cubits/checkout_state.dart';
import '../../domain/entities/checkout_contact_entity.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CheckoutCubit>()..startCheckout(),
      child: Scaffold(
        appBar: const FreshVeggieHeader(
          title: 'Checkout',
          showBackButton: true,
        ),
        body: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, state) {
            if (state is CheckoutInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CheckoutContactStep) {
              return _ContactStepView(contact: state.contact);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ContactStepView extends StatefulWidget {
  final CheckoutContactEntity contact;

  const _ContactStepView({required this.contact});

  @override
  State<_ContactStepView> createState() => _ContactStepViewState();
}

class _ContactStepViewState extends State<_ContactStepView> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _landmarkController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _addressController = TextEditingController(text: widget.contact.address);
    _landmarkController = TextEditingController(text: widget.contact.landmark);
    _phoneController = TextEditingController(text: widget.contact.phoneNumber);
  }

  @override
  void didUpdateWidget(_ContactStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contact != oldWidget.contact) {
      _nameController.text = widget.contact.name;
      _addressController.text = widget.contact.address;
      _landmarkController.text = widget.contact.landmark;
      _phoneController.text = widget.contact.phoneNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who are you ordering for?',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _OptionCard(
                  title: 'Myself',
                  subtitle: 'Use my profile',
                  icon: Icons.person_outline_rounded,
                  isSelected: widget.contact.isForSelf,
                  onTap: () {
                    final authState = context.read<AuthCubit>().state;
                    final locationState = context.read<LocationCubit>().state;

                    String name = '';
                    if (authState is Authenticated) {
                      name = authState.user.displayName ?? '';
                    }

                    String address = '';
                    if (locationState is LocationLoaded) {
                      address = locationState.address;
                    }

                    context
                        .read<CheckoutCubit>()
                        .setOrderForSelf(name, address);
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _OptionCard(
                  title: 'Someone Else',
                  subtitle: 'Enter manually',
                  icon: Icons.people_outline_rounded,
                  isSelected: !widget.contact.isForSelf,
                  onTap: () {
                    context.read<CheckoutCubit>().setOrderForSomeoneElse();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'Delivery Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                  widget.contact.copyWith(name: val),
                ),
          ),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                  widget.contact.copyWith(address: val),
                ),
          ),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _landmarkController,
            label: 'Landmark',
            icon: Icons.near_me_outlined,
            onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                  widget.contact.copyWith(landmark: val),
                ),
          ),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                  widget.contact.copyWith(phoneNumber: val),
                ),
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () {
                // Next step in checkout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:
              BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28.sp,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.8)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
