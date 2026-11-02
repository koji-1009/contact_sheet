import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:shop_app_sheet/fakes/states.dart';
import 'package:shop_app_sheet/preview/start.dart';

// One page = one file = one node on the map. Each @Preview is a state of
// the page. The preview returns the app's own router started at the page,
// so the live page walks real transitions.

@Preview(group: 'ログイン', name: '決済から', size: Size(390, 844), wrapper: guest)
// A guest's push of /checkout from the product detail is redirected here.
Widget login() => startAt('/login?from=/checkout', from: '/products/p1');

@Preview(group: 'ログイン', name: 'ホームから', size: Size(390, 844), wrapper: guest)
// The home's ログイン button pushes /login, with no `from`.
Widget loginFromHome() => startAt('/login', from: '/');
