import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuantityCounterWidget extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double? width;
  final double? height;

  const QuantityCounterWidget({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: width ?? double.infinity,
      height: height ?? 28.h,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decrement button
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6.r),
                bottomLeft: Radius.circular(6.r),
              ),
              child: Container(
                height: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  color: colorScheme.onPrimary,
                  size: 16.sp,
                ),
              ),
            ),
          ),
          // Quantity display
          Expanded(
            flex: 1,
            child: Container(
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: colorScheme.onPrimary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Increment button
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(6.r),
                bottomRight: Radius.circular(6.r),
              ),
              child: Container(
                height: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  color: colorScheme.onPrimary,
                  size: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
