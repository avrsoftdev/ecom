import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../cubits/product_details_cubit.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_pricing.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../../cart/presentation/cubits/cart_cubit.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../wishlist/presentation/cubits/wishlist_cubit.dart';
import '../widgets/tier_selection_sheet.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  static Route<void> route(String productId) {
    return MaterialPageRoute(
      builder: (context) => ProductDetailsPage(productId: productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductDetailsCubit(
        productRepository: ProductRepositoryImpl(
          remoteDataSource: ProductRemoteDataSourceImpl(
            firestore: FirebaseFirestore.instance,
          ),
          networkInfo: NetworkInfoImpl(
            Connectivity(),
          ),
        ),
      )..getProductDetails(productId),
      child: const ProductDetailsView(),
    );
  }
}

class ProductDetailsView extends StatefulWidget {
  const ProductDetailsView({super.key});

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  ProductPricing? _selectedTier;

  @override
  void initState() {
    super.initState();
    // We'll set the default tier in the build method when we have access to the product
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      body: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
        builder: (context, state) {
          if (state is ProductDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading
                      context.read<ProductDetailsCubit>().reset();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ProductDetailsLoaded) {
            // Set default tier to tier 1 if not already set
            if (_selectedTier == null && state.product.pricingTiers.isNotEmpty) {
              _selectedTier = state.product.pricingTiers.first;
            }
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImageSection(product: state.product),
                  _ProductInfoSection(
                    product: state.product,
                    selectedTier: _selectedTier,
                    onTierSelected: (tier) {
                      setState(() {
                        _selectedTier = tier;
                      });
                    },
                  ),
                  _RelatedProductsSection(
                    relatedProducts: state.relatedProducts,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProductImageSection extends StatelessWidget {
  final ProductEntity product;

  const _ProductImageSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      child: CachedNetworkImage(
        imageUrl: product.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, size: 50),
        ),
      ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  final ProductEntity product;
  final ProductPricing? selectedTier;
  final Function(ProductPricing) onTierSelected;

  const _ProductInfoSection({
    required this.product,
    this.selectedTier,
    required this.onTierSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedTier != null) ...[
                      Text(
                        formatCurrency(selectedTier!.price),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ] else if (product.discountPercent > 0) ...[
                      Row(
                        children: [
                          Text(
                            formatCurrency(product.price),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatCurrency(product.effectivePrice),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.discountPercent.toInt()}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        formatCurrency(product.price),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (product.stock > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'In Stock',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isNotEmpty 
                ? product.description 
                : 'No description available for this product.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Stock: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${product.stock} ${product.unitType.displayUnit}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tier selection card for products with tiers
          if (product.pricingTiers.isNotEmpty) ...[
            _TierSelectionCard(
              product: product,
              selectedTier: selectedTier,
              onTierSelected: onTierSelected,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: product.stock > 0 ? () {
                final hasTiers = product.pricingTiers.isNotEmpty;
                if (hasTiers && selectedTier != null) {
                  // Add to cart logic for tiered products
                  context.read<CartCubit>().addToCart(
                    product,
                    tierId: selectedTier!.tierId,
                    tierLabel: '${selectedTier!.quantity} ${product.unitType.displayUnit}',
                    tierPrice: selectedTier!.price,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added to cart!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                // Add to cart logic for non-tiered products
                context.read<CartCubit>().addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product added to cart!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: product.stock > 0 ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text(
                product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierSelectionCard extends StatelessWidget {
  final ProductEntity product;
  final ProductPricing? selectedTier;
  final Function(ProductPricing) onTierSelected;

  const _TierSelectionCard({
    required this.product,
    this.selectedTier,
    required this.onTierSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Tier',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: product.pricingTiers.map(
                (tier) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _CompactTierOption(
                    product: product,
                    tier: tier,
                    isSelected: selectedTier?.tierId == tier.tierId,
                    onTap: () => onTierSelected(tier),
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTierOption extends StatelessWidget {
  final ProductEntity product;
  final ProductPricing tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactTierOption({
    required this.product,
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${tier.quantity}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.unitType.displayUnit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isSelected ? colorScheme.onPrimary.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrency(tier.price),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedProductsSection extends StatelessWidget {
  final List<ProductEntity> relatedProducts;

  const _RelatedProductsSection({required this.relatedProducts});

  @override
  Widget build(BuildContext context) {
    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Related Products',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              final product = relatedProducts[index];
              return BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  return BlocBuilder<WishlistCubit, WishlistState>(
                    builder: (context, wishlistState) {
                      final isWishlisted = wishlistState is WishlistLoaded &&
                          wishlistState.wishlistProducts.containsKey(product.id);
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

                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              ProductDetailsPage.route(product.id),
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
                          selectedTierLabel: displayCartItem?.tierLabel,
                          showQuantityControls: quantity > 0,
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
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
