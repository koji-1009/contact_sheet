import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:shop_app_sheet/fakes/states.dart';
import 'package:shop_app_sheet/preview/start.dart';

// One page = one file = one node on the map. Each @Preview is a state of
// the page. The preview returns the app's own router started at the page,
// so the page shows as the app shows it there, over the page under it.

@Preview(group: 'Home', name: 'Guest', size: Size(390, 844), wrapper: guest)
@Preview(
  group: 'Home',
  name: 'Signed in',
  size: Size(390, 844),
  wrapper: loggedIn,
)
Widget home() => startAt('/');
