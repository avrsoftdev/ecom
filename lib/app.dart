import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/routes/app_router.dart';
import 'core/di/injection.dart';
import 'core/widgets/notification_listener.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/cart/presentation/cubits/cart_cubit.dart';
import 'features/wishlist/presentation/cubits/wishlist_cubit.dart';
import 'features/location/presentation/cubits/location_cubit.dart';
import 'features/location/presentation/cubits/location_state.dart';
import 'features/notification/presentation/cubits/notification_cubit.dart';

class FreshVeggieApp extends StatelessWidget {
  const FreshVeggieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: getIt<ThemeCubit>(),
            ),
            BlocProvider(
              create: (context) => getIt<AuthCubit>()..checkAuthStatus(),
            ),
            BlocProvider(
              create: (context) => getIt<WishlistCubit>()..loadWishlist(),
            ),
            BlocProvider(
              create: (context) => getIt<CartCubit>()..loadCart(),
            ),
            BlocProvider(
              create: (context) => getIt<LocationCubit>()..fetchLocation(),
            ),
            BlocProvider(
              create: (context) {
                try {
                  final cubit = getIt<NotificationCubit>();
                  // Initialize notifications with a delay to ensure everything is ready
                  Future.delayed(const Duration(milliseconds: 500), () {
                    try {
                      cubit.loadNotifications();
                    } catch (e) {
                      print('Error loading notifications after delay: $e');
                    }
                  });
                  return cubit;
                } catch (e) {
                  print('Error creating NotificationCubit: $e');
                  // Return a dummy cubit that won't crash
                  return NotificationCubit(
                    firestore: getIt(),
                    firebaseAuth: getIt(),
                  );
                }
              },
            ),
            // Add other global cubits here
          ],
          child: BlocListener<LocationCubit, LocationState>(
            listener: (context, state) {
              if (state is LocationLoaded) {
                AppRouter.locationServiceableNotifier.value = true;
              } else if (state is LocationUnserviceable || state is LocationError) {
                AppRouter.locationServiceableNotifier.value = false;
              }
            },
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return PushNotificationListener(
                  child: MaterialApp.router(
                    title: 'Bajariyo',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeMode,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: context.locale,
                    routerConfig: AppRouter.router,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class FreshVeggieAdminApp extends StatelessWidget {
  const FreshVeggieAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 1024), // Web admin design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: getIt<ThemeCubit>(),
            ),
            BlocProvider(
              create: (context) => getIt<AuthCubit>()..checkAuthStatus(),
            ),
            // Add admin-specific cubits here
          ],
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                title: 'FreshVeggie Admin',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                routerConfig: AppRouter.adminRouter,
              );
            },
          ),
        );
      },
    );
  }
}
