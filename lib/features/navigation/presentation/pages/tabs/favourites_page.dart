import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../wishlist/presentation/cubits/wishlist_cubit.dart';
import '../../../../home/presentation/widgets/product_card.dart';
import '../../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../../product/presentation/cubits/product_details_cubit.dart';
import '../../../../product/presentation/pages/product_details_page.dart';
import '../../../../product/presentation/widgets/tier_selection_sheet.dart';
import '../../../../product/data/repositories/product_repository_impl.dart';
import '../../../../product/data/datasources/product_remote_datasource.dart';
import '../../../../../core/network/network_info.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FreshVeggieHeader(),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state is WishlistInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is! WishlistLoaded) {
            return const Center(
              child: Text('Error loading wishlist'),
            );
          }

          final wishlistProducts = state.wishlistProducts.values.toList();

          if (wishlistProducts.isEmpty) {
            return _EmptyWishlistView();
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                Text(
                  'My Favourites',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${wishlistProducts.length} items in your wishlist',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: wishlistProducts.length,
                    itemBuilder: (context, index) {
                      final product = wishlistProducts[index];
                      return BlocBuilder<CartCubit, CartState>(
                        builder: (context, cartState) {
                          return BlocBuilder<WishlistCubit, WishlistState>(
                            builder: (context, wishlistState) {
                              final isWishlisted = wishlistState is WishlistLoaded &&
                                  wishlistState.wishlistProducts.containsKey(product.id);
                              final cartCubit = context.read<CartCubit>();
                              final quantity = cartState is CartLoaded
                                  ? cartCubit.quantityForProduct(product.id)
                                  : 0;
                              final hasTiers = product.pricingTiers.isNotEmpty;
                              final baseCartItem = cartState is CartLoaded
                                  ? cartCubit.baseItemForProduct(product.id)
                                  : null;

                              return ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                        create: (context) => ProductDetailsCubit(
                                          productRepository: ProductRepositoryImpl(
                                            remoteDataSource: ProductRemoteDataSourceImpl(
                                              firestore: FirebaseFirestore.instance,
                                            ),
                                            networkInfo: NetworkInfoImpl(
                                              Connectivity(),
                                            ),
                                          ),
                                        )..getProductDetails(product.id),
                                        child: ProductDetailsView(),
                                      ),
                                    ),
                                  );
                                },
                                onAddToCart: () {
                                  if (hasTiers) {
                                    TierSelectionSheet.show(context, product);
                                    return;
                                  }
                                  cartCubit.addToCart(product);
                                },
                                onWishlistToggle: () {
                                  context.read<WishlistCubit>().toggleWishlist(product);
                                },
                                isWishlisted: isWishlisted,
                                quantity: quantity,
                                showQuantityControls: !hasTiers,
                                onIncrementQuantity: () {
                                  if (baseCartItem != null) {
                                    cartCubit.incrementQuantity(baseCartItem.id);
                                  }
                                },
                                onDecrementQuantity: () {
                                  if (baseCartItem != null) {
                                    cartCubit.decrementQuantity(baseCartItem.id);
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyWishlistView extends StatelessWidget {
  const _EmptyWishlistView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80.sp,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add fresh vegetables to your wishlist and they\'ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
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
