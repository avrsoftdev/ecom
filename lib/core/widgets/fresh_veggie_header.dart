import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme_cubit.dart';
import '../../features/location/presentation/cubits/location_cubit.dart';
import '../../features/location/presentation/cubits/location_state.dart';

class FreshVeggieHeader extends StatelessWidget implements PreferredSizeWidget {
  const FreshVeggieHeader({
    super.key,
    this.title = 'Bajariyo',
    this.showBackButton = false,
    this.onBackPressed,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => Size.fromHeight(70.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF006400),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: showBackButton,
      toolbarHeight: 70.h,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              textStyle: (Theme.of(context).appBarTheme.titleTextStyle ??
                      Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
              ),
            ),
          ),
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              String locationText = 'Fetching location...';
              IconData locationIcon = Icons.location_on_outlined;

              if (state is LocationLoaded) {
                locationText = state.address;
                locationIcon = Icons.location_on;
              } else if (state is LocationError) {
                locationText = 'Location error';
                locationIcon = Icons.location_off;
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    locationIcon,
                    size: 12.sp,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      locationText,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDarkMode = themeMode == ThemeMode.dark;

            return IconButton(
              tooltip:
                  isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              icon: Icon(
                isDarkMode
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
              ),
            );
          },
        ),
      ],
    );
  }
}
