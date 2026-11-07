import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Profile', size: phone, wrapper: signedIn)
Widget profile() => startAt('/account/profile');
