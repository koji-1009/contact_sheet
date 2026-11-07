import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// The cards kept.
const paymentMethods = '/account/payment-methods';

@Preview(name: 'No card', size: phone, wrapper: signedIn)
Widget paymentMethodsNoCard() => startAt(paymentMethods);

@Preview(name: 'Card saved', size: phone, wrapper: withCard)
Widget paymentMethodsWithCard() => startAt(paymentMethods);
