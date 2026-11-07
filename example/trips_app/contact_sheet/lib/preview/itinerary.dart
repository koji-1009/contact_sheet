import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';
import 'package:trips_app_sheet/preview/trip.dart';

@Preview(name: 'Itinerary', size: phone, wrapper: booked)
Widget itinerary() => startAt('$trip/itinerary');
