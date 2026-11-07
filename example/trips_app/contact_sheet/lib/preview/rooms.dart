import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/hotel.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// The Harbor Inn's rooms.
const rooms = '$hotel/rooms';

@Preview(name: 'Choose a room', size: phone, wrapper: guest)
Widget roomsPage() => startAt(rooms, from: hotel);
