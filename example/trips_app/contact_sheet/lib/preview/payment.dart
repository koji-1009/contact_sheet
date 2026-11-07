import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/guests.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// Booking, second step.
const payment = '/book/payment?hotel=h1&room=r1';

@Preview(name: 'No card', size: phone, wrapper: signedIn)
Widget paymentNoCard() => startAt(payment, from: guests);

@Preview(name: 'Card saved', size: phone, wrapper: withCard)
Widget paymentWithCard() => startAt(payment, from: guests);
