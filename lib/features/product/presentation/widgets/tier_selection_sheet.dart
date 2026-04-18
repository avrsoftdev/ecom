import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../wishlist/presentation/widgets/quantity_counter_widget.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_pricing.dart';

class TierSelectionSheet {
  static Future<void> show(
    BuildContext context,
    ProductEntity product,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _TierSelectionSheet(product: product),
    );
  }
}

class _TierSelectionSheet extends StatelessWidget {
  const _TierSelectionSheet({
    required this.product,
  });

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Choose a tier to add to cart',
              style: TextStyle(
                fontSize: 13.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),
            ...product.pricingTiers.map(
              (tier) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _TierCard(
                  product: product,
                  tier: tier,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.product,
    required this.tier,
  });

  final ProductEntity product;
  final ProductPricing tier;

  String get _tierLabel => '${tier.quantity} ${product.unitType.displayUnit}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cartCubit = context.read<CartCubit>();

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final quantity = cartState is CartLoaded
            ? cartCubit.quantityForProduct(product.id, tierId: tier.tierId)
            : 0;
        final cartItem = cartState is CartLoaded
            ? cartCubit.baseItemForProduct(product.id, tierId: tier.tierId)
            : null;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.name} - $_tierLabel',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      formatCurrency(tier.price),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 80.w,
                height: 28.h,
                child: quantity > 0
                    ? QuantityCounterWidget(
                        quantity: quantity,
                        onIncrement: () {
                          if (cartItem != null) {
                            cartCubit.incrementQuantity(cartItem.id);
                          }
                        },
                        onDecrement: () {
                          if (cartItem != null) {
                            cartCubit.decrementQuantity(cartItem.id);
                          }
                        },
                      )
                    : ElevatedButton(
                        onPressed: () {
                          cartCubit.addToCart(
                            product,
                            tierId: tier.tierId,
                            tierLabel: _tierLabel,
                            tierPrice: tier.price,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_shopping_cart, size: 12.sp),
                            SizedBox(width: 4.w),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
