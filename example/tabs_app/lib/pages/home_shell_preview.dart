import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:tabs_app/pages/home_shell.dart';
import 'package:tabs_app/previews/fake_services.dart';

@Preview(group: 'Tabs', name: 'Feed', size: Size(390, 844), wrapper: guest)
Widget feedTab() => const HomeShell();

@Preview(group: 'Tabs', name: 'Search', size: Size(390, 844), wrapper: guest)
Widget searchTab() => const HomeShell(initialTab: 1);

@Preview(
  group: 'Tabs',
  name: 'Profile (guest)',
  size: Size(390, 844),
  wrapper: guest,
)
@Preview(
  group: 'Tabs',
  name: 'Profile (signed in)',
  size: Size(390, 844),
  wrapper: signedIn,
)
Widget profileTab() => const HomeShell(initialTab: 2);
