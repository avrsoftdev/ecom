import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_role_notifier.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/admin/admin_router.dart';
import '../../features/navigation/presentation/pages/main_navigation_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListPage(),
      ),
      // Add more routes as features are implemented
    ],
    // Add redirect logic for authentication
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final isOnAuthPage = location == '/login' || location == '/register';

      if (!isLoggedIn && !isOnAuthPage) {
        return '/login';
      }

      if (isLoggedIn && isOnAuthPage) {
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

      // While role is still loading, avoid bouncing between pages.
      if (role == null) {
        return null;
      }

      // If logged in and currently on auth pages, route based on role.
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
