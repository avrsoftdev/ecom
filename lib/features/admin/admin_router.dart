import 'package:go_router/go_router.dart';

import '../auth/presentation/pages/login_page.dart';
import '../auth/presentation/pages/register_page.dart';
import 'presentation/layout/admin_scaffold.dart';
import 'presentation/pages/admin_products_page.dart';
import 'presentation/pages/banners_admin_page.dart';
import 'presentation/pages/categories_admin_page.dart';
import 'presentation/pages/customer_detail_page.dart';
import 'presentation/pages/customers_admin_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/order_detail_page.dart';
import 'presentation/pages/orders_admin_page.dart';
import 'presentation/pages/product_form_page.dart';
import 'presentation/pages/settings_admin_page.dart';
import 'presentation/pages/unauthorized_page.dart';

class AdminRouter {
  static List<RouteBase> routes() {
    return [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/admin/unauthorized',
        builder: (context, state) => const UnauthorizedPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const AdminProductsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProductFormPage(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => ProductFormPage(
                  productId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/categories',
            builder: (context, state) => const CategoriesAdminPage(),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (context, state) => const OrdersAdminPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => OrderDetailPage(
                  orderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/banners',
            builder: (context, state) => const BannersAdminPage(),
          ),
          GoRoute(
            path: '/admin/customers',
            builder: (context, state) => const CustomersAdminPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CustomerDetailPage(
                  customerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const SettingsAdminPage(),
          ),
        ],
      ),
    ];
  }
}

