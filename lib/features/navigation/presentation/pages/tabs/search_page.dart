import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/di/injection.dart';
import '../../../../home/presentation/widgets/home_search_field.dart';
import '../../../../home/presentation/widgets/product_card.dart';
import '../../../../product/presentation/pages/product_details_page.dart';
import '../../../../product/presentation/cubits/product_details_cubit.dart';
import '../../../../product/data/repositories/product_repository_impl.dart';
import '../../../../product/data/datasources/product_remote_datasource.dart';
import '../../../../../core/network/network_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../wishlist/presentation/cubits/wishlist_cubit.dart';
import '../../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../../product/presentation/widgets/tier_selection_sheet.dart';

import '../../../../search/presentation/cubits/search_suggestion_cubit.dart';
import '../../../../search/presentation/cubits/search_cubit.dart';
import '../../../../search/presentation/cubits/search_state.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchController;
  late final SearchCubit _searchCubit;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchCubit = getIt<SearchCubit>();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchCubit.searchProducts(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _searchCubit),
        BlocProvider(
          create: (context) {
            final cubit = getIt<SearchSuggestionCubit>();
            if (widget.initialQuery != null &&
                widget.initialQuery!.isNotEmpty) {
              cubit.getSuggestions(widget.initialQuery!);
            }
            return cubit;
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Search Products',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: Column(
          children: [
            SizedBox(height: 8.h),
            HomeSearchField(
              onSearch: (query) {
                _searchCubit.searchProducts(query);
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
            SizedBox(height: 16.h),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  if (state is SearchInitial) {
                    return _EmptySearchState(
                      icon: Icons.search_rounded,
                      title: 'Search for fresh veggies',
                      subtitle: 'Find the best produce for your kitchen.',
                    );
                  }

                  if (state is SearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SearchError) {
                    return _EmptySearchState(
                      icon: Icons.error_outline_rounded,
                      title: 'Oops!',
                      subtitle: state.message,
                    );
                  }

                  if (state is SearchLoaded) {
                    if (state.products.isEmpty) {
                      return _EmptySearchState(
                        icon: Icons.search_off_rounded,
                        title: 'No products found',
                        subtitle: 'Try searching for something else.',
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
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
                                final hasTiers =
                                    product.pricingTiers.isNotEmpty;
                                final displayCartItem = cartState is CartLoaded
                                    ? (hasTiers
                                        ? cartCubit
                                            .preferredDisplayItemForProduct(
                                            product.id,
                                          )
                                        : cartCubit.baseItemForProduct(
                                            product.id,
                                          ))
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
                                        create: (context) =>
                                            ProductDetailsCubit(
                                          productRepository:
                                              ProductRepositoryImpl(
                                            remoteDataSource:
                                                ProductRemoteDataSourceImpl(
                                              firestore:
                                                  FirebaseFirestore.instance,
                                            ),
                                            networkInfo: NetworkInfoImpl(
                                              Connectivity(),
                                            ),
                                          ),
                                        )..getProductDetails(product.id),
                                        child: const ProductDetailsView(),
                                      ),
                                    ),
                                  ),
                                  isWishlisted: isWishlisted,
                                  onWishlistToggle: () => context
                                      .read<WishlistCubit>()
                                      .toggleWishlist(product),
                                  quantity: quantity,
                                  selectedTierLabel: displayCartItem?.tierLabel,
                                  onAddToCart: () {
                                    if (hasTiers) {
                                      TierSelectionSheet.show(context, product);
                                      return;
                                    }
                                    cartCubit.addToCart(product);
                                  },
                                  showQuantityControls: true,
                                  onIncrementQuantity: () {
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
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64.sp,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
