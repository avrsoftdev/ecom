import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // App Bar Shimmer
        SliverAppBar(
          expandedHeight: 120.h,
          floating: false,
          pinned: true,
          backgroundColor: colorScheme.surface,
          flexibleSpace: FlexibleSpaceBar(
            title: _buildShimmerContainer(context, width: 120.w, height: 24.h),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          centerTitle: true,
        ),
        // Banner Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: _buildShimmerContainer(
              context,
              width: double.infinity,
              height: 180.h,
              borderRadius: 12.r,
            ),
          ),
        ),
        // Categories Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(context, width: 150.w, height: 20.h),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 100.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: _buildShimmerContainer(
                        context,
                        width: 64.w,
                        height: 64.w,
                        borderRadius: 12.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Featured Products Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(context, width: 150.w, height: 20.h),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 220.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: _buildProductShimmer(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Deals Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(context, width: 120.w, height: 20.h),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 220.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: _buildProductShimmer(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // New Arrivals Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(context, width: 120.w, height: 20.h),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 220.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: _buildProductShimmer(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Recommended Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(context, width: 150.w, height: 20.h),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 220.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: _buildProductShimmer(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerContainer(
    BuildContext context, {
    required double width,
    required double height,
    double borderRadius = 8.0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      highlightColor: colorScheme.surface.withValues(alpha: 0.8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildProductShimmer(BuildContext context) {
    return Container(
      width: 160.w,
      height: 220.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildShimmerContainer(
              context,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 12.r,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerContainer(context, width: 120.w, height: 12.h),
                  SizedBox(height: 4.h),
                  _buildShimmerContainer(context, width: 80.w, height: 10.h),
                  SizedBox(height: 4.h),
                  _buildShimmerContainer(context, width: 60.w, height: 14.h),
                  SizedBox(height: 8.h),
                  _buildShimmerContainer(
                    context,
                    width: double.infinity,
                    height: 32.h,
                    borderRadius: 6.r,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
