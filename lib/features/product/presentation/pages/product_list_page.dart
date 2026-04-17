import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/fresh_veggie_header.dart';
import '../cubits/product_cubit.dart';
import '../cubits/product_details_cubit.dart';
import '../pages/product_details_page.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../../../core/network/network_info.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../wishlist/presentation/cubits/wishlist_cubit.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({
    super.key,
    this.categoryId,
  });

  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductCubit(getProductsUseCase: getIt())
        ..getProducts(categoryId: categoryId),
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
              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.62,
                ),
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
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

                          return Align(
                            alignment: Alignment.topCenter,
                            child: ProductCard(
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
                                  // TODO: Show tier selection for product list
                                  cartCubit.addToCart(product);
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
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            } else if (state is ProductError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProductCubit>().getProducts();
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
