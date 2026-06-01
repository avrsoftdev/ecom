import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/fresh_veggie_header.dart';
import '../cubits/product_cubit.dart';
import '../pages/product_details_page.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../widgets/tier_selection_sheet.dart';
import '../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../wishlist/presentation/cubits/wishlist_cubit.dart';
import '../../../location/presentation/cubits/location_cubit.dart';
import '../../../location/presentation/cubits/location_state.dart';
import '../../../../core/widgets/update_snackbar.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({
    super.key,
    this.categoryId,
  });

  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    final locationState = context.read<LocationCubit>().state;
    final coords = _coordsFromLocationState(locationState);

    return BlocProvider(
      create: (context) => ProductCubit(getProductsUseCase: getIt())
        ..getProducts(
          categoryId: categoryId,
          userLatitude: coords.$1,
          userLongitude: coords.$2,
        ),
      child: Scaffold(
        appBar: FreshVeggieHeader(
          showBackButton: true,
          onBackPressed: () => context.go('/home'),
        ),
        body: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductLoaded) {
              if (state.products.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => context.read<ProductCubit>().getProducts(
                        categoryId: categoryId,
                        userLatitude: coords.$1,
                        userLongitude: coords.$2,
                      ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Center(child: Text('No vendors nearby')),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => context.read<ProductCubit>().getProducts(
                      categoryId: categoryId,
                      userLatitude: coords.$1,
                      userLongitude: coords.$2,
                    ),
                child: GridView.builder(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        return BlocBuilder<WishlistCubit, WishlistState>(
                          builder: (context, wishlistState) {
                            final isWishlisted =
                                wishlistState is WishlistLoaded &&
                                    wishlistState.wishlistProducts
                                        .containsKey(product.id);
                            final cartCubit = context.read<CartCubit>();
                            final hasTiers = product.pricingTiers.isNotEmpty;
                            final displayCartItem = cartState is CartLoaded
                                ? (hasTiers
                                    ? cartCubit.preferredDisplayItemForProduct(
                                        product.id,
                                      )
                                    : cartCubit.baseItemForProduct(product.id))
                                : null;
                            final quantity = cartState is CartLoaded
                                ? cartCubit.totalQuantityForProduct(product.id)
                                : 0;

                            return Align(
                              alignment: Alignment.topCenter,
                              child: ProductCard(
                                product: product,
                                onTap: () {
                                Navigator.push(
                                  context,
                                  ProductDetailsPage.route(product.id),
                                );
                                },
                                onAddToCart: () {
                                  if (!product.isDeliverableToUser) {
                                    updateSnackbar(
                                      context,
                                      message:
                                          'Out-of-delivery-area item cannot be added to cart.',
                                      backgroundColor: Colors.red,
                                    );
                                    return;
                                  }
                                  if (hasTiers) {
                                    TierSelectionSheet.show(context, product);
                                    return;
                                  }
                                  cartCubit.addToCart(product);
                                },
                                onWishlistToggle: () {
                                  context
                                      .read<WishlistCubit>()
                                      .toggleWishlist(product);
                                },
                                isWishlisted: isWishlisted,
                                quantity: quantity,
                                showQuantityControls: true,
                                selectedTierLabel: displayCartItem?.tierLabel,
                                onIncrementQuantity: () {
                                  if (!product.isDeliverableToUser) {
                                    updateSnackbar(
                                      context,
                                      message:
                                          'Out-of-delivery-area item cannot be added to cart.',
                                      backgroundColor: Colors.red,
                                    );
                                    return;
                                  }
                                  if (hasTiers) {
                                    TierSelectionSheet.show(context, product);
                                    return;
                                  }
                                  if (displayCartItem != null) {
                                    cartCubit
                                        .incrementQuantity(displayCartItem.id);
                                  }
                                },
                                onDecrementQuantity: () {
                                  if (hasTiers) {
                                    TierSelectionSheet.show(context, product);
                                    return;
                                  }
                                  if (displayCartItem != null) {
                                    cartCubit
                                        .decrementQuantity(displayCartItem.id);
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              );
            } else if (state is ProductError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProductCubit>().getProducts(
                              categoryId: categoryId,
                              userLatitude: coords.$1,
                              userLongitude: coords.$2,
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('No products found'));
          },
        ),
      ),
    );
  }
}

(double?, double?) _coordsFromLocationState(LocationState state) {
  if (state is LocationLoaded) {
    return (state.location.latitude, state.location.longitude);
  }
  if (state is LocationUnserviceable) {
    return (state.location.latitude, state.location.longitude);
  }
  return (null, null);
}
