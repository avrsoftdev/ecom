import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/banner_entity.dart';

class BannerSlider extends StatefulWidget {
  final List<BannerEntity> banners;
  final Function(BannerEntity)? onBannerTap;

  const BannerSlider({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.banners.isEmpty) {
      return SizedBox(
        height: 180.h,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No banners available',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 180.h,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            enableInfiniteScroll: widget.banners.length > 1,
            autoPlay: widget.banners.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          itemCount: widget.banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = widget.banners[index];
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: () => widget.onBannerTap?.call(banner),
                  borderRadius: BorderRadius.circular(12.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: colorScheme.onSurfaceVariant,
                                size: 48.sp,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colorScheme.error,
                                size: 48.sp,
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay for better text visibility
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        // Banner content
                        if (banner.title.isNotEmpty || banner.description != null)
                          Positioned(
                            bottom: 16.h,
                            left: 16.w,
                            right: 16.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (banner.title.isNotEmpty)
                                  Text(
                                    banner.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (banner.description != null) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    banner.description!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12.sp,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.banners.length > 1) ...[
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.banners.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(entry.key, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                child: Container(
                  width: _currentIndex == entry.key ? 20.w : 6.w,
                  height: 6.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.r),
                    color: _currentIndex == entry.key
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
