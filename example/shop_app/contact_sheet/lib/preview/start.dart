import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shop_app/router.dart';

/// The app's own router (go_router), started at [location], in the app's
/// own MaterialApp (main.dart): the page is built by the app's routes,
/// redirects included.
///
/// [from] is the page the app pushes this one from (the home page pushes
/// the product detail). It is put under the page from the first frame, so
/// the page's back button shows as in the app.
Widget startAt(String location, {String? from}) {
  final router = GoRouter(
    initialLocation: from ?? location,
    routes: appRoutes,
    redirect: appRedirect,
  );
  if (from != null) {
    // GoRouter.push pushes on the current stack, which is empty until the
    // first frame: the stack under the page is given instead.
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
