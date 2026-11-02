import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_app/data/auth_repository.dart';
import 'package:shop_app/features/cart_page.dart';
import 'package:shop_app/features/checkout_page.dart';
import 'package:shop_app/features/complete_page.dart';
import 'package:shop_app/features/home_page.dart';
import 'package:shop_app/features/login_page.dart';
import 'package:shop_app/features/orders_page.dart';
import 'package:shop_app/features/product_detail_page.dart';

final appRoutes = <RouteBase>[
  GoRoute(path: '/', builder: (context, state) => const HomePage()),
  GoRoute(
    path: '/products/:id',
    builder: (context, state) =>
        ProductDetailPage(productId: state.pathParameters['id']!),
  ),
  GoRoute(path: '/checkout', builder: (context, state) => const CheckoutPage()),
  GoRoute(
    path: '/login',
    builder: (context, state) =>
        LoginPage(from: state.uri.queryParameters['from']),
  ),
  GoRoute(path: '/complete', builder: (context, state) => const CompletePage()),
  GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
  GoRoute(path: '/orders', builder: (context, state) => const OrdersPage()),
];

/// A guest who opens the checkout is sent to log in first.
String? appRedirect(BuildContext context, GoRouterState state) {
  final auth = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(authRepositoryProvider);
  if (state.matchedLocation == '/checkout' && !auth.isLoggedIn) {
    return '/login?from=/checkout';
  }
  return null;
}

final appTheme = ThemeData(colorSchemeSeed: Colors.teal);
