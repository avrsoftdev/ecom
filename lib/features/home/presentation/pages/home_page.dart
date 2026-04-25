import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/widgets/fresh_veggie_header.dart';
import '../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/presentation/cubits/product_details_cubit.dart';
import '../../../product/presentation/pages/product_details_page.dart';
import '../../../product/presentation/widgets/tier_selection_sheet.dart';
import '../../../product/data/repositories/product_repository_impl.dart';
import '../../../product/data/datasources/product_remote_datasource.dart';
import '../../../../core/network/network_info.dart';
import '../../../wishlist/presentation/cubits/wishlist_cubit.dart';
import '../cubits/home_cubit.dart';
import '../widgets/banner_slider.dart';
import '../widgets/category_item.dart';
import '../widgets/home_search_field.dart';
import '../widgets/home_shimmer.dart';
import '../../../search/presentation/cubits/search_suggestion_cubit.dart';
import '../../../../core/di/injection.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FreshVeggieHeader(),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const HomeShimmer();
          }

          if (state is HomeError) {
            return _HomeErrorView(message: state.message);
          }

          if (state is! HomeLoaded) {
            return const SizedBox.shrink();
          }

          final homeData = state.homeData;

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refreshHomeData(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  toolbarHeight: 95.h,
                  flexibleSpace: Padding(
                    padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                    child: BlocProvider(
                      create: (context) => getIt<SearchSuggestionCubit>(),
                      child: HomeSearchField(
                        onSearch: (query) {
                          context.go('/search?q=${Uri.encodeComponent(query)}');
                        },
                        onProductSelect: (product) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsPage(productId: product.id),
                            ),
                          );
                        },
                        onCategorySelect: (category) {
                          context.go(
                              '/products?categoryId=${Uri.encodeComponent(category.id)}');
                        },
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: BannerSlider(
                      banners: homeData.banners,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: SectionHeader(
                      title: 'Shop by category',
                      subtitle:
                          'Fresh produce picked for your everyday kitchen.',
                      showViewAll: false,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120.h,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      scrollDirection: Axis.horizontal,
                      itemCount: homeData.categories.length,
                      separatorBuilder: (_, __) => SizedBox(width: 4.w),
                      itemBuilder: (context, index) {
                        final category = homeData.categories[index];
                        return CategoryItem(
                          category: category,
                          onTap: () => context.go(
                            '/products?categoryId=${Uri.encodeComponent(category.id)}',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _ProductSection(
                  title: 'Featured products',
                  subtitle: 'Our best seasonal picks for today.',
                  products: homeData.featuredProducts,
                ),
                _ProductSection(
                  title: 'Deals of the day',
                  subtitle: 'Save more on limited-time fresh picks.',
                  products: homeData.deals,
                ),
                _ProductSection(
                  title: 'New arrivals',
                  subtitle: 'Recently added produce and pantry favorites.',
                  products: homeData.newArrivals,
                ),
                _ProductSection(
                  title: 'Recommended for you',
                  subtitle: 'Popular favorites from the FreshVeggie community.',
                  products: homeData.recommended,
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24.h),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.title,
    required this.subtitle,
    required this.products,
  });

  final String title;
  final String subtitle;
  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 24.h),
          child: SectionHeader(
            title: title,
            subtitle: subtitle,
            showViewAll: false,
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: Column(
          children: [
            SectionHeader(
              title: title,
              subtitle: subtitle,
              onViewAll: () => context.go('/products'),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 260.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final product = products[index];
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

                          return ProductCard(
                            product: product,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (context) => ProductDetailsCubit(
                                    productRepository: ProductRepositoryImpl(
                                      remoteDataSource:
                                          ProductRemoteDataSourceImpl(
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
                            ),
                            onAddToCart: () {
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
                              if (hasTiers) {
                                TierSelectionSheet.show(context, product);
                                return;
                              }
                              if (displayCartItem != null) {
                                cartCubit.incrementQuantity(displayCartItem.id);
                              }
                            },
                            onDecrementQuantity: () {
                              if (hasTiers) {
                                TierSelectionSheet.show(context, product);
                                return;
                              }
                              if (displayCartItem != null) {
                                cartCubit.decrementQuantity(displayCartItem.id);
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
      ),
    );
  }
}


class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56.sp,
              color: colorScheme.error,
            ),
            SizedBox(height: 12.h),
            Text(
              'Unable to load the home screen',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 13.sp,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => context.read<HomeCubit>().loadHomeData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
