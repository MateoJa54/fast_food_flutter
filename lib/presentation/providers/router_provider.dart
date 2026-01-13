import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../view/home/home_page.dart';
import '../view/catalog/categories_page.dart';
import '../view/catalog/products_page.dart';
import '../view/catalog/product_detail_page.dart';
import '../view/checkout/checkout_page.dart';
import '../view/orders/order_tracking_page.dart';
import '../view/auth/login_page.dart';
import '../view/auth/register_page.dart';
import '../view/auth/reset_password_page.dart';
import '../view/stores/stores_page.dart';
import '../view/cart/cart_page.dart';
import '../view/payments/payment_simulate_page.dart';
import '../view/orders/create_order_page.dart';
import '../view/orders/orders_history_page.dart';
import '../view/recommendation/recommendations_page.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = FirebaseAuth.instance;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshAuth(auth),
    redirect: (context, state) {
      final user = auth.currentUser;
      final isLoggedIn = user != null;

      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/reset';

      if (!isLoggedIn && !isGoingToAuth) return '/login';
      if (isLoggedIn && isGoingToAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
      GoRoute(path: '/stores', builder: (_, __) => const StoresPage()),
      GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersHistoryPage()),
      GoRoute(path: '/pay', builder: (_, __) => const PaymentSimulatePage()),
      GoRoute(
  path: '/recommendations',
  builder: (_, __) => const RecommendationsPage(),
),

GoRoute(path: '/create-order', builder: (_, __) => const CreateOrderPage()),

      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
GoRoute(
  path: '/orders/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return OrderTrackingPage(orderId: id);
  },
),
      GoRoute(
        path: '/products/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final categoryName = state.uri.queryParameters['name'];
          return ProductsPage(categoryId: categoryId, categoryName: categoryName);
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailPage(productId: id);
        },
      ),

      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/reset', builder: (_, __) => const ResetPasswordPage()),
    ],
  );
});

class GoRouterRefreshAuth extends ChangeNotifier {
  GoRouterRefreshAuth(FirebaseAuth auth) {
    _sub = auth.authStateChanges().listen((_) => notifyListeners());
  }
  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
