import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme_cubit.dart';
import '../../features/location/presentation/cubits/location_cubit.dart';
import '../../features/location/presentation/cubits/location_state.dart';
import '../../features/notification/presentation/cubits/notification_cubit.dart';
import '../../features/notification/presentation/cubits/notification_state.dart';
import '../../features/notification/presentation/pages/notification_page.dart';

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF006400),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: showBackButton,
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
                  ?.copyWith(color: Colors.white),
            ),
          ),
          if (!showBackButton) ...[
            SizedBox(height: 2.h),
            BlocBuilder<LocationCubit, LocationState>(
              builder: (context, state) {
                if (state is LocationLoaded) {
                  return Text(
                    state.address,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                } else if (state is LocationLoading) {
                  return Text(
                    'Getting location...',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                } else if (state is LocationError) {
                  return Text(
                    'Location unavailable',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            int unreadCount = 0;
            if (state is NotificationLoaded) {
              unreadCount = state.unreadCount;
            }

            return IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        try {
                          return BlocProvider.value(
                            value: context.read<NotificationCubit>(),
                            child: const NotificationPage(),
                          );
                        } catch (e) {
                          print('Error creating notification page: $e');
                          // Return a simple page with error message
                          return Scaffold(
                            appBar: AppBar(
                              backgroundColor: const Color(0xFF006400),
                              foregroundColor: Colors.white,
                              title: const Text('Notifications'),
                            ),
                            body: const Center(
                              child: Text('Notifications temporarily unavailable'),
                            ),
                          );
                        }
                      },
                    ),
                  );
                } catch (e) {
                  print('Error navigating to notifications: $e');
                }
              },
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: 16.w,
                          minHeight: 16.w,
                        ),
                        padding: EdgeInsets.all(2.w),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 8.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
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
