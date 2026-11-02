import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:shop_app_sheet/fakes/states.dart';
import 'package:shop_app_sheet/preview/start.dart';

// One page = one file = one node on the map. Each @Preview is a state of
// the page. The preview returns the app's own router started at the page,
// so the live page walks real transitions.

@Preview(
  group: 'カート',
  name: 'カート2件',
  size: Size(390, 844),
  wrapper: loggedInCart2,
)
@Preview(group: 'カート', name: '空のカート', size: Size(390, 844), wrapper: loggedIn)
// home_page.dart pushes it from the app bar's cart button.
Widget cart() => startAt('/cart', from: '/');
