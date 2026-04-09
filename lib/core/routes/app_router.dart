import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
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
      final isOnLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLoginPage) {
        return '/login';
      }

      if (isLoggedIn && isOnLoginPage) {
        return '/home';
      }

      return null;
    },
  );

  static final adminRouter = GoRouter(
    initialLocation: '/admin/dashboard',
    debugLogDiagnostics: kDebugMode,
    routes: [
      // Admin routes - only accessible on web
      // Add admin routes here
    ],
    redirect: (context, state) {
      // Admin auth guard
      return null;
    },
  );
}
