import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// Signing in, as the sign-in page is opened from a page it carries back to.
String signInFrom(String from) =>
    Uri(path: '/sign-in', queryParameters: {'from': from}).toString();

/// Opened from the welcome or the account: Continue goes to Explore.
@Preview(name: 'Sign in', size: phone, wrapper: guest)
Widget signIn() => startAt('/sign-in', from: '/welcome');

/// Opened from the Trips tab's prompt: Continue goes back to Trips.
@Preview(name: 'From trips', size: phone, wrapper: guest)
Widget signInFromTrips() => startAt(signInFrom('/trips'), from: '/trips');

/// Opened from the Inbox tab's prompt: Continue goes back to Inbox.
@Preview(name: 'From inbox', size: phone, wrapper: guest)
Widget signInFromInbox() => startAt(signInFrom('/inbox'), from: '/inbox');

/// Opened by the heart on a stay: Continue goes back to the stay.
@Preview(name: 'From a stay', size: phone, wrapper: guest)
Widget signInFromStay() =>
    startAt(signInFrom('/explore/hotels/h1'), from: '/explore/hotels/h1');

/// Opened by the router when a guest selects a room: Continue goes on to
/// the booking.
@Preview(name: 'For booking', size: phone, wrapper: guest)
Widget signInForBooking() => startAt(
  signInFrom('/book/guests?hotel=h1&room=r1'),
  from: '/explore/hotels/h1/rooms',
);
