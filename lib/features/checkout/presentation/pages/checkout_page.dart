import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../location/presentation/cubits/location_cubit.dart';
import '../../../location/presentation/cubits/location_state.dart';
import '../cubits/checkout_cubit.dart';
import '../cubits/checkout_state.dart';
import '../../domain/entities/checkout_contact_entity.dart';

class CheckoutBottomSheet extends StatelessWidget {
  const CheckoutBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocProvider(
      create: (context) => getIt<CheckoutCubit>()..startCheckout(),
      child: Container(
        height: screenHeight * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            _buildHandle(context),
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<CheckoutCubit, CheckoutState>(
                builder: (context, state) {
                  if (state is CheckoutInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CheckoutContactStep) {
                    return _ContactStepView(
                      contact: state.contact,
                      savedContacts: state.savedContacts,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Checkout',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CheckoutBottomSheet();
  }
}

class _ContactStepView extends StatefulWidget {
  final CheckoutContactEntity contact;
  final List<CheckoutContactEntity> savedContacts;

  const _ContactStepView({
    required this.contact,
    required this.savedContacts,
  });

  @override
  State<_ContactStepView> createState() => _ContactStepViewState();
}

class _ContactStepViewState extends State<_ContactStepView> {
  late TextEditingController _nameController;
  late TextEditingController _houseFlatBuildingController;
  late TextEditingController _streetAreaColonyController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;
  late TextEditingController _phoneController;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _houseFlatBuildingController = TextEditingController(text: widget.contact.houseFlatBuilding);
    _streetAreaColonyController = TextEditingController(text: widget.contact.streetAreaColony);
    _cityController = TextEditingController(text: widget.contact.city);
    _stateController = TextEditingController(text: widget.contact.state);
    _pincodeController = TextEditingController(text: widget.contact.pincode);
    _landmarkController = TextEditingController(text: widget.contact.landmark);
    _phoneController = TextEditingController(text: widget.contact.phoneNumber);
  }

  @override
  void didUpdateWidget(_ContactStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contact != oldWidget.contact) {
      _nameController.text = widget.contact.name;
      _houseFlatBuildingController.text = widget.contact.houseFlatBuilding;
      _streetAreaColonyController.text = widget.contact.streetAreaColony;
      _cityController.text = widget.contact.city;
      _stateController.text = widget.contact.state;
      _pincodeController.text = widget.contact.pincode;
      _landmarkController.text = widget.contact.landmark;
      _phoneController.text = widget.contact.phoneNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _houseFlatBuildingController.dispose();
    _streetAreaColonyController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
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
          if (widget.savedContacts.isNotEmpty) ...[
            Text(
              'Saved Details',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            ...widget.savedContacts.map(
              (contact) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _SavedDetailsCard(
                  contact: contact,
                  onTap: () {
                    context.read<CheckoutCubit>().useSavedContact(contact);
                  },
                ),
              ),
            ),
            SizedBox(height: 14.h),
          ],
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
            controller: _houseFlatBuildingController,
            label: 'House / Flat / Building No.',
            icon: Icons.home_outlined,
            onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                  widget.contact.copyWith(houseFlatBuilding: val),
                ),
          ),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _streetAreaColonyController,
            label: 'Street / Area / Colony Name',
            icon: Icons.location_on_outlined,
            onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                  widget.contact.copyWith(streetAreaColony: val),
                ),
          ),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city_outlined,
            onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                  widget.contact.copyWith(city: val),
                ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map_outlined,
                  onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                        widget.contact.copyWith(state: val),
                      ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTextField(
                  controller: _pincodeController,
                  label: 'Pincode',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => context.read<CheckoutCubit>().updateContact(
                        widget.contact.copyWith(pincode: val),
                      ),
                ),
              ),
            ],
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
              onPressed: _isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                _isPlacingOrder ? 'Placing order...' : 'Continue',
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

  Future<void> _placeOrder() async {
    final cartState = context.read<CartCubit>().state;
    if (cartState is! CartLoaded || cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place order')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      const deliveryCharge = 40.0;
      const taxRate = 0.0;
      final subtotal = cartState.totalPrice;
      final tax = subtotal * taxRate;
      final total = subtotal + deliveryCharge + tax;
      final shippingAddress = [
        _houseFlatBuildingController.text.trim(),
        _streetAreaColonyController.text.trim(),
        _landmarkController.text.trim(),
        _cityController.text.trim(),
        _stateController.text.trim(),
        _pincodeController.text.trim(),
      ].where((v) => v.isNotEmpty).join(', ');
      final checkoutContact = _currentContact();

      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'items': cartState.items
            .map(
              (item) => {
                'productId': item.product.id,
                'name': item.product.name,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'lineTotal': item.totalPrice,
                'unitType': item.product.unitType.displayUnit,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'deliveryCharge': deliveryCharge,
        'tax': tax,
        'total': total,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'customerName': _nameController.text.trim().isEmpty
            ? (user.displayName ?? '')
            : _nameController.text.trim(),
        'customerEmail': user.email ?? '',
        'shippingAddress': shippingAddress,
        'phone': _phoneController.text.trim(),
        'checkoutContact': checkoutContact.toJson(),
      });

      if (!mounted) return;
      await context.read<CheckoutCubit>().saveContactForLater(checkoutContact);
      context.read<CartCubit>().clearCart();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  CheckoutContactEntity _currentContact() {
    return CheckoutContactEntity(
      name: _nameController.text.trim(),
      houseFlatBuilding: _houseFlatBuildingController.text.trim(),
      streetAreaColony: _streetAreaColonyController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      landmark: _landmarkController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      isForSelf: widget.contact.isForSelf,
    );
  }
}

class _SavedDetailsCard extends StatelessWidget {
  final CheckoutContactEntity contact;
  final VoidCallback onTap;

  const _SavedDetailsCard({
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = [
      contact.houseFlatBuilding,
      contact.streetAreaColony,
      contact.landmark,
      contact.city,
      contact.state,
      contact.pincode,
    ].where((value) => value.trim().isNotEmpty).join(', ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: colorScheme.primary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name.trim().isEmpty ? 'Saved delivery details' : contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12.sp,
                        height: 1.25,
                      ),
                    ),
                  ],
                  if (contact.phoneNumber.trim().isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      contact.phoneNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
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
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
