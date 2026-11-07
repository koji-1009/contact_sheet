import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/hotel.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Reviews', size: phone, wrapper: guest)
Widget reviews() => startAt('$hotel/reviews', from: hotel);
