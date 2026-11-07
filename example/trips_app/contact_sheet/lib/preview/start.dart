// The app started at a location, as the app itself starts: its router,
// its redirect, its theme.
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trips_app/router.dart';

/// The size every preview is shot at: a phone.
const phone = Size(390, 844);

/// The app at [location]; pushed over [from] when given, so that its back
/// button shows as in the app.
Widget startAt(String location, {String? from}) {
  final router = GoRouter(
    // The routes over the tab bar name it as their parentNavigatorKey.
    navigatorKey: rootNavigatorKey,
    initialLocation: from ?? location,
    routes: appRoutes,
    redirect: appRedirect,
  );
  if (from != null) {
    // The router's stack is empty until the first frame: give it the stack
    // under the page.
    router.routeInformationProvider.push<void>(
      location,
      base: router.configuration.findMatch(Uri.parse(from)),
    );
  }
  return MaterialApp.router(
    routerConfig: router,
    theme: appTheme,
    debugShowCheckedModeBanner: false,
  );
}
