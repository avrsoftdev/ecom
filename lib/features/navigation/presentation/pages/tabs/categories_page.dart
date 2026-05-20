import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../admin/domain/repositories/admin_category_repository.dart';
import '../../../../common/domain/entities/category_entity.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryRepository = getIt<AdminCategoryRepository>();

    return Scaffold(
      appBar: const FreshVeggieHeader(),
      body: StreamBuilder<List<CategoryEntity>>(
        stream: categoryRepository.watchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _CategoriesMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load categories',
              message: 'Please try again in a moment.',
              iconColor: Theme.of(context).colorScheme.error,
            );
          }

          final categories = [...snapshot.data ?? <CategoryEntity>[]]
            ..sort((a, b) {
              final orderCompare = a.sortOrder.compareTo(b.sortOrder);
              if (orderCompare != 0) {
                return orderCompare;
              }
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

          if (categories.isEmpty) {
            return _CategoriesMessage(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message: 'Fresh categories will appear here soon.',
              iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Browse all fresh picks by category.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      return _CategoryTile(
                        category: category,
                        onTap: () => context.go(
                          '/products?categoryId=${Uri.encodeComponent(category.id)}',
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onTap,
  });

  final CategoryEntity category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _CategoryImageFallback(
                    iconColor: colorScheme.onSurfaceVariant,
                  ),
                  errorWidget: (context, url, error) => _CategoryImageFallback(
                    iconColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryImageFallback extends StatelessWidget {
  const _CategoryImageFallback({
    required this.iconColor,
  });

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.category_outlined,
          size: 34.sp,
          color: iconColor,
        ),
      ),
    );
  }
}

class _CategoriesMessage extends StatelessWidget {
  const _CategoriesMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

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
              icon,
              size: 64.sp,
              color: iconColor,
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
