import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/fresh_veggie_header.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../cubits/home_cubit.dart';
import '../widgets/banner_slider.dart';
import '../widgets/category_item.dart';
import '../widgets/home_shimmer.dart';
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
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                    child: _WelcomeCard(totalCategories: homeData.categories.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: SectionHeader(
                      title: 'Shop by category',
                      subtitle: 'Fresh produce picked for your everyday kitchen.',
                      showViewAll: false,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120.h,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      scrollDirection: Axis.horizontal,
                      itemCount: homeData.categories.length,
                      separatorBuilder: (_, __) => SizedBox(width: 4.w),
                      itemBuilder: (context, index) {
                        final category = homeData.categories[index];
                        return CategoryItem(
                          category: category,
                          onTap: () => context.go('/products'),
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.totalCategories,
  });

  final int totalCategories;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF43A047),
            Color(0xFF81C784),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              'Farm fresh daily',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Fresh groceries delivered with a modern market feel.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Browse $totalCategories curated categories, seasonal deals, and featured picks built for the new home experience.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 18.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: const [
              _HighlightPill(icon: Icons.bolt_rounded, label: 'Fast delivery'),
              _HighlightPill(icon: Icons.eco_rounded, label: 'Organic picks'),
              _HighlightPill(icon: Icons.local_offer_rounded, label: 'Daily deals'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                  return ProductCard(
                    product: product,
                    onTap: () => context.go('/products'),
                    onAddToCart: () {},
                    onWishlistToggle: () {},
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
