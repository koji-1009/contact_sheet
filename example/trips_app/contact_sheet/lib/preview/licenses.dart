import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trips_app/features/account/about_page.dart';
import 'package:trips_app/router.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// Flutter's own licenses page, as `showLicensePage` pushes it over About.
@Preview(name: 'Licenses', size: phone, wrapper: guest)
Widget licenses() => MaterialApp(
  theme: appTheme,
  debugShowCheckedModeBanner: false,
  initialRoute: '/licenses',
  routes: {
    '/': (_) => const AboutPage(),
    '/licenses': (_) => const LicensePage(
      applicationName: 'Trips',
      applicationVersion: '2.4.0',
    ),
  },
);
