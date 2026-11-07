import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/payment_methods.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Add a card', size: phone, wrapper: signedIn)
Widget addCard() => startAt('/cards/add', from: paymentMethods);
