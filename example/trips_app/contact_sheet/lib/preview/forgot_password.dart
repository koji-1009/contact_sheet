import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Reset your password', size: phone, wrapper: guest)
Widget forgotPassword() => startAt('/forgot-password', from: '/sign-in');
