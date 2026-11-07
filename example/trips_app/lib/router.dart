import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';
import 'package:trips_app/data/settings_repository.dart';
import 'package:trips_app/features/account/about_page.dart';
import 'package:trips_app/features/account/account_page.dart';
import 'package:trips_app/features/account/add_card_page.dart';
import 'package:trips_app/features/account/help_page.dart';
import 'package:trips_app/features/account/language_page.dart';
import 'package:trips_app/features/account/payment_methods_page.dart';
import 'package:trips_app/features/account/profile_page.dart';
import 'package:trips_app/features/account/settings_page.dart';
import 'package:trips_app/features/account/wishlist_page.dart';
import 'package:trips_app/features/auth/forgot_password_page.dart';
import 'package:trips_app/features/auth/reset_sent_page.dart';
import 'package:trips_app/features/auth/sign_in_page.dart';
import 'package:trips_app/features/auth/sign_up_page.dart';
import 'package:trips_app/features/booking/done_page.dart';
import 'package:trips_app/features/booking/guests_page.dart';
import 'package:trips_app/features/booking/payment_page.dart';
import 'package:trips_app/features/booking/review_page.dart';
import 'package:trips_app/features/explore/destination_page.dart';
import 'package:trips_app/features/explore/explore_page.dart';
import 'package:trips_app/features/explore/filters_page.dart';
import 'package:trips_app/features/explore/hotel_page.dart';
import 'package:trips_app/features/explore/map_page.dart';
import 'package:trips_app/features/explore/photos_page.dart';
import 'package:trips_app/features/explore/reviews_page.dart';
import 'package:trips_app/features/explore/rooms_page.dart';
import 'package:trips_app/features/explore/search_page.dart';
import 'package:trips_app/features/explore/search_results_page.dart';
import 'package:trips_app/features/inbox/conversation_page.dart';
import 'package:trips_app/features/inbox/inbox_page.dart';
import 'package:trips_app/features/inbox/notifications_page.dart';
import 'package:trips_app/features/onboarding/welcome_page.dart';
import 'package:trips_app/features/shell.dart';
import 'package:trips_app/features/trips/cancel_page.dart';
import 'package:trips_app/features/trips/itinerary_page.dart';
import 'package:trips_app/features/trips/trip_page.dart';
import 'package:trips_app/features/trips/trips_page.dart';
import 'package:trips_app/features/trips/voucher_page.dart';

/// The navigator over the tab bar: the pages that cover the whole screen.
final rootNavigatorKey = GlobalKey<NavigatorState>();

String _id(GoRouterState state, [String name = 'id']) =>
    state.pathParameters[name]!;

final appRoutes = <RouteBase>[
  GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
  GoRoute(
    path: '/sign-in',
    builder: (context, state) =>
        SignInPage(from: state.uri.queryParameters['from']),
  ),
  GoRoute(
    path: '/sign-up',
    builder: (context, state) =>
        SignUpPage(from: state.uri.queryParameters['from']),
  ),
  GoRoute(
    path: '/forgot-password',
    builder: (context, state) => const ForgotPasswordPage(),
  ),
  GoRoute(
    path: '/reset-sent',
    builder: (context, state) => const ResetSentPage(),
  ),
  GoRoute(
    path: '/photos/:id',
    builder: (context, state) => PhotosPage(hotelId: _id(state)),
  ),
  GoRoute(
    path: '/notifications',
    builder: (context, state) => const NotificationsPage(),
  ),
  GoRoute(path: '/cards/add', builder: (context, state) => const AddCardPage()),
  // Booking: over the tab bar, signed in only.
  GoRoute(
    path: '/book/guests',
    builder: (context, state) => GuestsPage(
      hotelId: state.uri.queryParameters['hotel']!,
      roomId: state.uri.queryParameters['room']!,
    ),
  ),
  GoRoute(
    path: '/book/payment',
    builder: (context, state) => PaymentPage(
      hotelId: state.uri.queryParameters['hotel']!,
      roomId: state.uri.queryParameters['room']!,
    ),
  ),
  GoRoute(
    path: '/book/review',
    builder: (context, state) => ReviewPage(
      hotelId: state.uri.queryParameters['hotel']!,
      roomId: state.uri.queryParameters['room']!,
    ),
  ),
  GoRoute(
    path: '/book/done/:id',
    builder: (context, state) => DonePage(tripId: _id(state)),
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => AppShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExplorePage(),
            routes: [
              GoRoute(
                path: 'search',
                builder: (context, state) => const SearchPage(),
                routes: [
                  GoRoute(
                    path: 'results',
                    builder: (context, state) => SearchResultsPage(
                      query: state.uri.queryParameters['q'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'filters',
                        parentNavigatorKey: rootNavigatorKey,
                        pageBuilder: (context, state) => const MaterialPage(
                          fullscreenDialog: true,
                          child: FiltersPage(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'map',
                builder: (context, state) => const MapPage(),
              ),
              GoRoute(
                path: 'destinations/:id',
                builder: (context, state) =>
                    DestinationPage(destinationId: _id(state)),
              ),
              GoRoute(
                path: 'hotels/:id',
                builder: (context, state) => HotelPage(hotelId: _id(state)),
                routes: [
                  GoRoute(
                    path: 'reviews',
                    builder: (context, state) =>
                        ReviewsPage(hotelId: _id(state)),
                  ),
                  GoRoute(
                    path: 'rooms',
                    builder: (context, state) => RoomsPage(hotelId: _id(state)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/trips',
            builder: (context, state) => const TripsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => TripPage(tripId: _id(state)),
                routes: [
                  GoRoute(
                    path: 'itinerary',
                    builder: (context, state) =>
                        ItineraryPage(tripId: _id(state)),
                  ),
                  GoRoute(
                    path: 'voucher',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        VoucherPage(tripId: _id(state)),
                  ),
                  GoRoute(
                    path: 'cancel',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) => MaterialPage(
                      fullscreenDialog: true,
                      child: CancelPage(tripId: _id(state)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxPage(),
            routes: [
              GoRoute(
                path: 'conversations/:id',
                builder: (context, state) =>
                    ConversationPage(conversationId: _id(state)),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountPage(),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
              GoRoute(
                path: 'payment-methods',
                builder: (context, state) => const PaymentMethodsPage(),
              ),
              GoRoute(
                path: 'wishlist',
                builder: (context, state) => const WishlistPage(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'language',
                    builder: (context, state) => const LanguagePage(),
                  ),
                ],
              ),
              GoRoute(
                path: 'help',
                builder: (context, state) => const HelpPage(),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];

/// The pages a guest is sent to sign in for.
const _signedInOnly = [
  '/book',
  '/cards',
  '/account/profile',
  '/account/payment-methods',
  '/account/wishlist',
];

/// Before the welcome is seen, the app shows it (and signing in from it);
/// a guest who opens a page for the signed in signs in first, and comes back.
String? appRedirect(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context, listen: false);
  final location = state.matchedLocation;
  final onboarded = container.read(settingsRepositoryProvider).onboarded;
  if (!onboarded &&
      !const ['/welcome', '/sign-in', '/sign-up'].contains(location)) {
    return '/welcome';
  }
  final signedIn = container.read(authRepositoryProvider).isSignedIn;
  if (!signedIn && _signedInOnly.any(location.startsWith)) {
    return Uri(
      path: '/sign-in',
      queryParameters: {'from': state.uri.toString()},
    ).toString();
  }
  return null;
}

/// The app's router: it starts at the explore tab, and redirects again
/// when the user signs in or out, or sees the welcome.
GoRouter appRouter(Listenable refresh) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/explore',
  routes: appRoutes,
  redirect: appRedirect,
  refreshListenable: refresh,
);

final appTheme = ThemeData(colorSchemeSeed: Colors.indigo);
