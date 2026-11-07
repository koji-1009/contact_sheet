import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// Booked: the history started again, nothing under it.
@Preview(name: 'You are booked', size: phone, wrapper: booked)
Widget done() => startAt('/book/done/t1');
