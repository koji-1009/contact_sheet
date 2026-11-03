import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:shop_app_sheet/fakes/states.dart';
import 'package:shop_app_sheet/preview/start.dart';

// One page = one file = one node on the map. Each @Preview is a state of
// the page. The preview returns the app's own router started at the page,
// so the page shows as the app shows it there, over the page under it.

// It looks the same signed in or not: one state.
@Preview(
  group: 'Product',
  name: 'Default',
  size: Size(390, 844),
  wrapper: guest,
)
// home_page.dart pushes it from the home page.
Widget productDetail() => startAt('/products/p1', from: '/');
