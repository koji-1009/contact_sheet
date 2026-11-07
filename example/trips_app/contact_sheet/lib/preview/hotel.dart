import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// The Harbor Inn.
const hotel = '/explore/hotels/h1';

@Preview(name: 'Not saved', size: phone, wrapper: guest)
Widget hotelNotSaved() => startAt(hotel);

@Preview(name: 'Saved', size: phone, wrapper: saved)
Widget hotelSaved() => startAt(hotel);
