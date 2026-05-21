import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/delivery_fee_calculator.dart';
import '../../features/cart/presentation/cubits/cart_cubit.dart';

class FreeDeliverySnackBarListener extends StatelessWidget {
  const FreeDeliverySnackBarListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
      listenWhen: (previous, current) {
        return previous is CartLoaded &&
            current is CartLoaded &&
            previous.totalPrice < freeDeliveryMinimum &&
            current.totalPrice >= freeDeliveryMinimum;
      },
      listener: (context, state) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) {
          return;
        }

        final colorScheme = Theme.of(context).colorScheme;
        messenger
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.primary,
              margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              content: Text(
                '🛍️ Awesome! You are now eligible for FREE Delivery.',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
      },
      child: child,
    );
  }
}
