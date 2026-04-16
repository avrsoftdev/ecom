import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../product/domain/entities/product_pricing.dart';
import '../../../product/domain/entities/product_unit_type.dart';

class PricingTiersWidget extends StatefulWidget {
  final List<ProductPricing> pricingTiers;
  final ProductUnitType unitType;
  final Function(List<ProductPricing>) onChanged;

  const PricingTiersWidget({
    super.key,
    required this.pricingTiers,
    required this.unitType,
    required this.onChanged,
  });

  @override
  State<PricingTiersWidget> createState() => _PricingTiersWidgetState();
}

class _PricingTiersWidgetState extends State<PricingTiersWidget> {
  late List<ProductPricing> _tiers;

  @override
  void initState() {
    super.initState();
    _tiers = List.from(widget.pricingTiers);
  }

  @override
  void didUpdateWidget(PricingTiersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pricingTiers != widget.pricingTiers) {
      _tiers = List.from(widget.pricingTiers);
    }
  }

  void _addPricingTier() {
    setState(() {
      _tiers.add(ProductPricing(
        quantity: 1.0,
        price: 0.0,
        description: '',
      ));
    });
    widget.onChanged(_tiers);
  }

  void _removePricingTier(int index) {
    setState(() {
      _tiers.removeAt(index);
    });
    widget.onChanged(_tiers);
  }

  void _updatePricingTier(int index, ProductPricing tier) {
    setState(() {
      _tiers[index] = tier;
    });
    widget.onChanged(_tiers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pricing Tiers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: _addPricingTier,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Tier'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (_tiers.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'No pricing tiers added. Standard price will be used.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._tiers.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;
            return _PricingTierCard(
              tier: tier,
              unitType: widget.unitType,
              index: index,
              onUpdate: (newTier) => _updatePricingTier(index, newTier),
              onRemove: () => _removePricingTier(index),
            );
          }).toList(),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _PricingTierCard extends StatefulWidget {
  final ProductPricing tier;
  final ProductUnitType unitType;
  final int index;
  final Function(ProductPricing) onUpdate;
  final VoidCallback onRemove;

  const _PricingTierCard({
    required this.tier,
    required this.unitType,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_PricingTierCard> createState() => _PricingTierCardState();
}

class _PricingTierCardState extends State<_PricingTierCard> {
  late final _quantityController = TextEditingController(
    text: widget.tier.quantity.toString(),
  );
  late final _priceController = TextEditingController(
    text: widget.tier.price.toStringAsFixed(2),
  );
  late final _descriptionController = TextEditingController(
    text: widget.tier.description ?? '',
  );

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateTier() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final description = _descriptionController.text.trim();

    widget.onUpdate(ProductPricing(
      quantity: quantity,
      price: price,
      description: description.isEmpty ? null : description,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tier ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 32.w,
                    minHeight: 32.h,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity (${widget.unitType.displayUnit})',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateTier(),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateTier(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _updateTier(),
            ),
            if (widget.tier.quantity > 0) ...[
              SizedBox(height: 4.h),
              Text(
                'Price per ${widget.unitType.displayUnit}: ${widget.tier.pricePerUnit.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
