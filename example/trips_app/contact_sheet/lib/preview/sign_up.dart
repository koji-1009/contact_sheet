import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/sign_in.dart';
import 'package:trips_app_sheet/preview/start.dart';

String _signUpFrom(String from) =>
    Uri(path: '/sign-up', queryParameters: {'from': from}).toString();

/// Opened from the sign-in or the account: Create account goes to Explore.
@Preview(name: 'Create an account', size: phone, wrapper: guest)
Widget signUp() => startAt('/sign-up', from: '/sign-in');

/// Opened from the sign-in the Trips tab asked for.
@Preview(name: 'From trips', size: phone, wrapper: guest)
Widget signUpFromTrips() =>
    startAt(_signUpFrom('/trips'), from: signInFrom('/trips'));

/// Opened from the sign-in the Inbox tab asked for.
@Preview(name: 'From inbox', size: phone, wrapper: guest)
Widget signUpFromInbox() =>
    startAt(_signUpFrom('/inbox'), from: signInFrom('/inbox'));

/// Opened from the sign-in the heart on a stay asked for.
@Preview(name: 'From a stay', size: phone, wrapper: guest)
Widget signUpFromStay() => startAt(
  _signUpFrom('/explore/hotels/h1'),
  from: signInFrom('/explore/hotels/h1'),
);

/// Opened from the sign-in the booking asked for.
@Preview(name: 'For booking', size: phone, wrapper: guest)
Widget signUpForBooking() => startAt(
  _signUpFrom('/book/guests?hotel=h1&room=r1'),
  from: signInFrom('/book/guests?hotel=h1&room=r1'),
);
