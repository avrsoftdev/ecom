import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CartIconWithBadge extends StatelessWidget {
  final int itemCount;
  final IconData icon;
  final Color? color;
  final double? size;

  const CartIconWithBadge({
    super.key,
    required this.itemCount,
    this.icon = Icons.shopping_cart_outlined,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = color ?? colorScheme.onSurface;
    final iconSize = size ?? 24.sp;

    return Stack(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
        if (itemCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: colorScheme.surface,
                  width: 1.5.r,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: 16.r,
                minHeight: 16.r,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  itemCount > 99 ? '99+' : itemCount.toString(),
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
