import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/rooms.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// Booking the Harbor Inn's twin room, first step.
const guests = '/book/guests?hotel=h1&room=r1';

@Preview(name: 'Who is staying?', size: phone, wrapper: signedIn)
Widget guestsPage() => startAt(guests, from: rooms);
