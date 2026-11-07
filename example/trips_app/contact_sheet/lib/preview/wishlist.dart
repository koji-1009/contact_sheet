import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Empty', size: phone, wrapper: signedIn)
Widget wishlistEmpty() => startAt('/account/wishlist');

@Preview(name: 'Saved', size: phone, wrapper: saved)
Widget wishlistSaved() => startAt('/account/wishlist');
