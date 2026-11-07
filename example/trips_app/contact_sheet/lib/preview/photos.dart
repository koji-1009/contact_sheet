import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/hotel.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Photos', size: phone, wrapper: guest)
Widget photos() => startAt('/photos/h1', from: hotel);
