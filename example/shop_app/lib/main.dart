import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_app/router.dart';

void main() => runApp(const ProviderScope(child: ShopApp()));

class ShopApp extends StatefulWidget {
  const ShopApp({super.key});

  @override
  State<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends State<ShopApp> {
  late final _router = GoRouter(routes: appRoutes, redirect: appRedirect);

  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(theme: appTheme, routerConfig: _router);
}
