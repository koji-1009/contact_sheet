import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/payment.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Review and pay', size: phone, wrapper: withCard)
Widget review() => startAt('/book/review?hotel=h1&room=r1', from: payment);
