import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../product/domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onWishlistToggle;
  final bool isWishlisted;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    required this.onWishlistToggle,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDiscount = product.discountPercent > 0;
    final discountedPrice = hasDiscount
        ? product.price * (1 - product.discountPercent / 100)
        : product.price;

    return Container(
      width: 160.w,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 32.sp,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colorScheme.error,
                              size: 32.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Wishlist Button
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: onWishlistToggle,
                        icon: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isWishlisted
                              ? colorScheme.error
                              : colorScheme.onSurface,
                          size: 20.sp,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 32.w,
                          minHeight: 32.h,
                        ),
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '${product.discountPercent.toInt()}% OFF',
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Sold count (using as rating placeholder)
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 12.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (product.soldCount > 0) ...[
                          SizedBox(width: 2.w),
                          Text(
                            '(${product.soldCount} sold)',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // Price
                    Row(
                      children: [
                        Text(
                          'Rs.${discountedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (hasDiscount) ...[
                          SizedBox(width: 4.w),
                          Text(
                            'Rs.${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 32.h,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_shopping_cart, size: 12.sp),
                            SizedBox(width: 4.w),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
