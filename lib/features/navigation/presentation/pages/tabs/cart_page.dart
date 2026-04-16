import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../product/domain/entities/product_entity.dart';
import '../../../../wishlist/presentation/cubits/wishlist_cubit.dart';
import '../../../../wishlist/presentation/widgets/cart_item_widget.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const FreshVeggieHeader(),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state is WishlistInitial || state is WishlistLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is! WishlistLoaded) {
            return const SizedBox.shrink();
          }

          final wishlistProducts = state.wishlistProducts;
          final wishlistQuantities = state.wishlistQuantities;
          
          if (wishlistProducts.isEmpty) {
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
                        '${wishlistProducts.length} items',
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
                  itemCount: wishlistProducts.length,
                  itemBuilder: (context, index) {
                    final productId = wishlistProducts.keys.elementAt(index);
                    final product = wishlistProducts[productId]!;
                    final quantity = wishlistQuantities[productId]!;
                    
                    return CartItemWidget(
                      product: product,
                      quantity: quantity,
                      onRemove: () {
                        context.read<WishlistCubit>().removeFromWishlist(productId);
                      },
                      onIncrement: () {
                        context.read<WishlistCubit>().incrementQuantity(productId);
                      },
                      onDecrement: () {
                        context.read<WishlistCubit>().decrementQuantity(productId);
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
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: _CartSummary(
                  wishlistQuantities: wishlistQuantities,
                  wishlistProducts: wishlistProducts,
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
    required this.wishlistQuantities,
    required this.wishlistProducts,
    required this.colorScheme,
  });

  final Map<String, int> wishlistQuantities;
  final Map<String, ProductEntity> wishlistProducts;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Calculate total items and subtotal based on actual product data
    final totalItems = wishlistQuantities.values.fold(0, (sum, quantity) => sum + quantity);
    double subtotal = 0.0;
    
    for (final entry in wishlistQuantities.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      final product = wishlistProducts[productId];
      
      if (product != null) {
        final effectivePrice = product.effectivePrice;
        subtotal += effectivePrice * quantity;
      }
    }
    
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
              'Rs${subtotal.toStringAsFixed(2)}',
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
              'Rs${deliveryFee.toStringAsFixed(2)}',
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
              'Rs${total.toStringAsFixed(2)}',
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
              // Proceed to checkout
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
