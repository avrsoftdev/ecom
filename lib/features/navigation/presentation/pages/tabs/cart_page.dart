import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../../wishlist/presentation/widgets/cart_item_widget.dart';
import '../../../../checkout/presentation/pages/checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const FreshVeggieHeader(),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartInitial || state is CartLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is! CartLoaded) {
            return const SizedBox.shrink();
          }

          final cartItems = state.items;
          
          if (cartItems.isEmpty) {
            return _EmptyCartView(colorScheme: colorScheme);
          }

          return Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_rounded,
                      color: colorScheme.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'My Cart',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        '${state.totalItems} items',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cart Items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    
                    return CartItemWidget(
                      item: item,
                      onRemove: () {
                        context.read<CartCubit>().removeFromCart(item.id);
                      },
                      onIncrement: () {
                        context.read<CartCubit>().incrementQuantity(item.id);
                      },
                      onDecrement: () {
                        context.read<CartCubit>().decrementQuantity(item.id);
                      },
                    );
                  },
                ),
              ),

              // Cart Summary
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: _CartSummary(
                  totalItems: state.totalItems,
                  subtotal: state.totalPrice,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80.sp,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add fresh vegetables to your cart and review them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                // Navigate to home page
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'Start Shopping',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.totalItems,
    required this.subtotal,
    required this.colorScheme,
  });

  final int totalItems;
  final double subtotal;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final deliveryFee = 40.0;
    final total = subtotal + deliveryFee;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal ($totalItems items)',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              formatCurrency(subtotal),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Fee',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              formatCurrency(deliveryFee),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              formatCurrency(total),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: totalItems > 0 ? () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CheckoutBottomSheet(),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.surfaceContainerHighest,
              disabledForegroundColor: colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Proceed to Checkout',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
