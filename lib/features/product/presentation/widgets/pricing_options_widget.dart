import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_pricing.dart';
import '../../domain/entities/product_unit_type.dart';
import '../../../../core/utils/currency_formatter.dart';

class PricingOptionsWidget extends StatelessWidget {
  final ProductEntity product;
  final Function(double quantity, double price)? onOptionSelected;

  const PricingOptionsWidget({
    super.key,
    required this.product,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (product.pricingTiers.isEmpty) {
      return _SinglePriceDisplay(product: product);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing Options:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: 4.h),
        ...product.pricingTiers.map((tier) => _PricingTierItem(
              tier: tier,
              unitType: product.unitType,
              onSelected: () => onOptionSelected?.call(tier.quantity, tier.price),
            )),
        _StandardPriceOption(
          product: product,
          onSelected: () => onOptionSelected?.call(1.0, product.price),
        ),
      ],
    );
  }
}

class _SinglePriceDisplay extends StatelessWidget {
  final ProductEntity product;

  const _SinglePriceDisplay({required this.product});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatCurrency(product.price),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _PricingTierItem extends StatelessWidget {
  final ProductPricing tier;
  final ProductUnitType unitType;
  final VoidCallback? onSelected;

  const _PricingTierItem({
    required this.tier,
    required this.unitType,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${tier.quantity} ${unitType.displayUnit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              formatCurrency(tier.price),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandardPriceOption extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onSelected;

  const _StandardPriceOption({
    required this.product,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Standard (1 ${product.unitType.displayUnit})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
            Text(
              formatCurrency(product.price),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
