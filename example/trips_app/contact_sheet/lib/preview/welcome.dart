import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// The welcome, shown first until it is seen.
@Preview(name: 'Welcome', size: phone, wrapper: fresh)
Widget welcome() => startAt('/welcome');
