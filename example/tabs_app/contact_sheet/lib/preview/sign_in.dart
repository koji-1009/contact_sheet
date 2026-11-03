import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tabs_app/main.dart';
import 'package:tabs_app/pages/home_shell.dart';
import 'package:tabs_app/pages/sign_in_page.dart';
import 'package:tabs_app/previews/fake_services.dart';

// The app has no preview that shows signing in as it opens: a full-screen
// dialog over the profile tab. The app's own fakes are used.

Widget guestServices(Widget child) {
  fakeServices();
  return child;
}

@Preview(
  group: 'Sign in',
  name: 'Default',
  size: Size(390, 844),
  wrapper: guestServices,
)
Widget signIn() => MaterialApp(
  theme: tabsTheme,
  debugShowCheckedModeBanner: false,
  // The app names no routes, but without one of home, routes or
  // onGenerateRoute the MaterialApp has no navigator at all.
  onGenerateRoute: (_) => null,
  onGenerateInitialRoutes: (_) => [
    MaterialPageRoute<void>(builder: (_) => const HomeShell(initialTab: 2)),
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const SignInPage(),
    ),
  ],
);
