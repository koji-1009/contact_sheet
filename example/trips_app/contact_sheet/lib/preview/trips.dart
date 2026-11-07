import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Guest', size: phone, wrapper: guest)
Widget tripsGuest() => startAt('/trips');

@Preview(name: 'No trips', size: phone, wrapper: signedIn)
Widget tripsEmpty() => startAt('/trips');

@Preview(name: 'Booked', size: phone, wrapper: booked)
Widget tripsBooked() => startAt('/trips');
