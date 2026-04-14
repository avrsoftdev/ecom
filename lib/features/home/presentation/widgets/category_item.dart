   import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/category_entity.dart';

class CategoryItem extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Image
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.category_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 24.sp,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.error,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Category Name
            SizedBox(
              width: 72.w,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
