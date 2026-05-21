import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/cart/presentation/cubits/cart_cubit.dart';

class FloatingCartOverlay extends StatefulWidget {
  const FloatingCartOverlay({
    super.key,
    required this.child,
    required this.routeListenable,
    required this.onCartTap,
  });

  final Widget child;
  final ValueListenable<RouteInformation> routeListenable;
  final VoidCallback onCartTap;

  @override
  State<FloatingCartOverlay> createState() => _FloatingCartOverlayState();
}

class _FloatingCartOverlayState extends State<FloatingCartOverlay> {
  final ValueNotifier<Offset?> _cartPositionNotifier =
      ValueNotifier<Offset?>(null);
  bool _hasUserMovedCart = false;

  static const Set<String> _bottomNavigationPaths = {
    '/home',
    '/orders',
    '/cart',
    '/categories',
    '/profile',
  };

  bool _isAuthPath(String path) {
    final normalizedPath = path.toLowerCase();
    return normalizedPath == '/login' ||
        normalizedPath == '/register' ||
        normalizedPath == '/signup' ||
        normalizedPath.contains('otp') ||
        normalizedPath.contains('verification');
  }

  @override
  void dispose() {
    _cartPositionNotifier.dispose();
    super.dispose();
  }

  Offset _defaultCartPosition(
    Size screenSize,
    EdgeInsets viewPadding,
    bool hasBottomNavigation,
  ) {
    final buttonSize = _FloatingCartButton.buttonSize;
    return Offset(
      screenSize.width - buttonSize - 16.w,
      screenSize.height -
          buttonSize -
          viewPadding.bottom -
          (hasBottomNavigation ? 92.h : 24.h),
    );
  }

  Offset _clampCartPosition(
    Offset position,
    Size screenSize,
    EdgeInsets viewPadding,
  ) {
    final buttonSize = _FloatingCartButton.buttonSize;
    final minX = 8.w;
    final maxX = screenSize.width - buttonSize - 8.w;
    final minY = viewPadding.top + 8.h;
    final maxY = screenSize.height - buttonSize - viewPadding.bottom - 8.h;

    return Offset(
      position.dx.clamp(minX, maxX).toDouble(),
      position.dy.clamp(minY, maxY).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: widget.routeListenable,
          builder: (context, _) {
            final path = widget.routeListenable.value.uri.path;
            final showCart = !_isAuthPath(path);
            final hasBottomNavigation = _bottomNavigationPaths.contains(path);
            final screenSize = constraints.biggest;
            final viewPadding = MediaQuery.viewPaddingOf(context);

            final defaultPosition = _defaultCartPosition(
              screenSize,
              viewPadding,
              hasBottomNavigation,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                if (showCart)
                  ValueListenableBuilder<Offset?>(
                    valueListenable: _cartPositionNotifier,
                    builder: (context, cartPosition, _) {
                      final effectivePosition = _clampCartPosition(
                        _hasUserMovedCart
                            ? (cartPosition ?? defaultPosition)
                            : defaultPosition,
                        screenSize,
                        viewPadding,
                      );

                      return Positioned(
                        left: effectivePosition.dx,
                        top: effectivePosition.dy,
                        child: RepaintBoundary(
                          child: _FloatingCartButton(
                            onTap: widget.onCartTap,
                            onDragUpdate: (details) {
                              _hasUserMovedCart = true;
                              _cartPositionNotifier.value = _clampCartPosition(
                                effectivePosition + details.delta,
                                screenSize,
                                viewPadding,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FloatingCartButton extends StatefulWidget {
  const _FloatingCartButton({
    required this.onTap,
    required this.onDragUpdate,
  });

  static double get buttonSize => 58.r;

  final VoidCallback onTap;
  final GestureDragUpdateCallback onDragUpdate;

  @override
  State<_FloatingCartButton> createState() => _FloatingCartButtonState();
}

class _FloatingCartButtonState extends State<_FloatingCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _shakeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 2),
    ]).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _itemCount(CartState state) {
    return state is CartLoaded ? state.totalItems : 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<CartCubit, CartState>(
      listenWhen: (previous, current) {
        return previous is CartLoaded &&
            _itemCount(current) > previous.totalItems;
      },
      listener: (context, state) {
        _animationController.forward(from: 0);
      },
      builder: (context, state) {
        final itemCount = _itemCount(state);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: widget.onDragUpdate,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value.w, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                customBorder: const CircleBorder(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: _FloatingCartButton.buttonSize,
                      height: _FloatingCartButton.buttonSize,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      foregroundDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 3.r,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/cart_icon.png',
                        width: _FloatingCartButton.buttonSize,
                        height: _FloatingCartButton.buttonSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: -2.r,
                      top: -3.r,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: 20.r,
                          minHeight: 20.r,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 1.5.r,
                          ),
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : itemCount.toString(),
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
