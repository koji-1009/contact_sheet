import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';
import 'package:trips_app_sheet/preview/trip.dart';

@Preview(name: 'Voucher', size: phone, wrapper: booked)
Widget voucher() => startAt('$trip/voucher', from: trip);
