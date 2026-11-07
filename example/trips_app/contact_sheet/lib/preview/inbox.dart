import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Guest', size: phone, wrapper: guest)
Widget inboxGuest() => startAt('/inbox');

@Preview(name: 'Signed in', size: phone, wrapper: signedIn)
Widget inboxSignedIn() => startAt('/inbox');
