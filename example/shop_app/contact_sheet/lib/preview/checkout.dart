import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:shop_app_sheet/fakes/states.dart';
import 'package:shop_app_sheet/preview/start.dart';

// One page = one file = one node on the map. Each @Preview is a state of
// the page. The preview returns the app's own router started at the page,
// so the live page walks real transitions.

@Preview(
  group: '決済',
  name: 'カート2件',
  size: Size(390, 844),
  wrapper: loggedInCart2,
)
@Preview(group: '決済', name: '空のカート', size: Size(390, 844), wrapper: loggedIn)
// product_detail_page.dart pushes it from the product detail.
Widget checkout() => startAt('/checkout', from: '/products/p1');
