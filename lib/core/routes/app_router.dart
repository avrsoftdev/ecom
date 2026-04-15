import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_role_notifier.dart';
import '../di/injection.dart';
import '../../features/admin/admin_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/cubits/home_cubit.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/navigation/presentation/pages/main_navigation_page.dart';
import '../../features/navigation/presentation/pages/tabs/cart_page.dart';
import '../../features/navigation/presentation/pages/tabs/favourites_page.dart';
import '../../features/navigation/presentation/pages/tabs/profile_page.dart';
import '../../features/navigation/presentation/pages/tabs/search_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<HomeCubit>()..loadHomeData(),
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wishlist',
                builder: (context, state) => const FavouritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => ProductListPage(
          categoryId: state.uri.queryParameters['categoryId'],
        ),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final isOnAuthPage = location == '/login' || location == '/register';

      if (!isLoggedIn && !isOnAuthPage) {
        return '/login';
      }

      if (isLoggedIn && (location == '/' || isOnAuthPage)) {
        return '/home';
      }

      return null;
    },
  );

  static final adminRouter = GoRouter(
    initialLocation: '/admin/dashboard',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: AuthRoleNotifier.instance,
    routes: AdminRouter.routes(),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isOnAuthPage = location == '/login' || location == '/register';

      if (!kIsWeb) {
        return '/login';
      }

      if (!isLoggedIn) {
        return '/login';
      }

      final role = AuthRoleNotifier.instance.role;
      final isOnUnauthorized = location == '/admin/unauthorized';

      if (role == null) {
        return null;
      }

      if (isOnAuthPage) {
        if (role == 'admin') {
          return '/admin/dashboard';
        }
        return '/admin/unauthorized';
      }

      if (role != 'admin' && !isOnUnauthorized) {
        return '/admin/unauthorized';
      }

      if (role == 'admin' && isOnUnauthorized) {
        return '/admin/dashboard';
      }

      return null;
    },
  );
}
