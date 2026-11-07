import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// The trip at the Harbor Inn.
const trip = '/trips/t1';

@Preview(name: 'Trip', size: phone, wrapper: booked)
Widget tripPage() => startAt(trip);

/// The trip is gone (cancelled): nothing to show.
@Preview(name: 'Cancelled', size: phone, wrapper: signedIn)
Widget tripCancelled() => startAt(trip);
