import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// Took the place of the reset page, over the sign-in.
@Preview(name: 'Check your email', size: phone, wrapper: guest)
Widget resetSent() => startAt('/reset-sent', from: '/sign-in');
