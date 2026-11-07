// The app's repositories with fixed data, so that pages render without a
// network, a device, or a wait.
// MockPlatformInterfaceMixin is for tests: the previews are shot in one.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trips_app/data/auth_repository.dart';
import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/data/inbox_repository.dart';
import 'package:trips_app/data/models.dart';
import 'package:trips_app/data/settings_repository.dart';
import 'package:trips_app/data/trip_repository.dart';
import 'package:trips_app/data/wallet_repository.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const sampleHotels = [
  Hotel(id: 'h1', name: 'Harbor Inn', city: 'Kobe', price: 14000, rating: 4.5),
  Hotel(
    id: 'h2',
    name: 'Maple Lodge',
    city: 'Kyoto',
    price: 22000,
    rating: 4.8,
  ),
  Hotel(id: 'h3', name: 'Sky Tower', city: 'Tokyo', price: 31000, rating: 4.2),
];

const sampleRooms = [
  Room(id: 'r1', name: 'Twin room', price: 14000),
  Room(id: 'r2', name: 'Suite', price: 38000),
];

/// Who is signed in: a guest, or a traveler.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({required this.signedIn});

  final bool signedIn;

  @override
  bool get isSignedIn => signedIn;

  @override
  String? get userName => signedIn ? 'Aki' : null;

  @override
  Future<void> signIn(String email) async {}

  @override
  Future<void> signUp(String email, String name) async {}

  @override
  void signOut() {}
}

/// The hotels, rooms and reviews, at once.
class FakeHotelRepository implements HotelRepository {
  const FakeHotelRepository();

  @override
  Future<List<Destination>> destinations() async => const [
    Destination(id: 'kyoto', name: 'Kyoto', blurb: 'Temples and gardens'),
    Destination(id: 'kobe', name: 'Kobe', blurb: 'The harbor and the hills'),
  ];

  @override
  Future<List<Hotel>> popular() async => sampleHotels;

  @override
  Future<List<Hotel>> inDestination(String destinationId) async => [
    for (final h in sampleHotels)
      if (h.city.toLowerCase() == destinationId) h,
  ];

  @override
  Future<List<Hotel>> search(String query) async => [
    for (final h in sampleHotels)
      if ('${h.name} ${h.city}'.toLowerCase().contains(query.toLowerCase())) h,
  ];

  @override
  Future<Hotel> hotel(String id) async =>
      sampleHotels.firstWhere((h) => h.id == id);

  @override
  Future<List<Room>> rooms(String hotelId) async => sampleRooms;

  @override
  Future<List<Review>> reviews(String hotelId) async => const [
    Review(author: 'Aki', text: 'Quiet, and close to the station.', stars: 5),
    Review(author: 'Ben', text: 'Small rooms.', stars: 3),
  ];
}

/// The trips booked: none, or one at the Harbor Inn (t1).
class FakeTripRepository extends TripRepository {
  FakeTripRepository({required bool booked})
    : _trips = booked
          ? [
              Trip(
                id: 't1',
                hotel: sampleHotels.first,
                room: sampleRooms.first,
                dates: 'Dec 20 – Dec 22',
              ),
            ]
          : [];

  final List<Trip> _trips;

  @override
  List<Trip> get trips => List.unmodifiable(_trips);

  @override
  Trip? trip(String id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<Trip> book(Hotel hotel, Room room) async => _trips.first;

  @override
  Future<void> cancel(String id) async {}
}

/// The cards kept: none, or a Visa.
class FakeWalletRepository extends WalletRepository {
  FakeWalletRepository({required bool card})
    : _cards = card ? const [PaymentCard(brand: 'Visa', last4: '4242')] : [];

  final List<PaymentCard> _cards;

  @override
  List<PaymentCard> get cards => _cards;

  @override
  Future<void> add(PaymentCard card) async {}
}

/// The stays saved: none, or the Harbor Inn (h1).
class FakeWishlistRepository extends WishlistRepository {
  FakeWishlistRepository({required bool saved}) : _saved = saved ? {'h1'} : {};

  final Set<String> _saved;

  @override
  Set<String> get saved => _saved;

  @override
  void toggle(String hotelId) {}
}

/// One thread with the Harbor Inn, and one notification.
class FakeInboxRepository implements InboxRepository {
  const FakeInboxRepository();

  @override
  Future<List<Conversation>> conversations() async => const [
    Conversation(
      id: 'c1',
      hotelName: 'Harbor Inn',
      lastMessage: 'Your room is ready from 3 pm.',
    ),
  ];

  @override
  Future<List<String>> messages(String conversationId) async => const [
    'Hello! Can we check in early?',
    'Your room is ready from 3 pm.',
  ];

  @override
  Future<List<AppNotification>> notifications() async => const [
    AppNotification(
      id: 'n1',
      text: 'Your stay at Harbor Inn is in 3 days',
      tripId: 't1',
    ),
  ];
}

/// The device's settings without the device: whether the welcome was seen,
/// and the language.
class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository({this.onboarded = true, this.language = 'English'})
    : super(_NoPreferences());

  @override
  final bool onboarded;

  @override
  final String language;

  @override
  Future<void> setOnboarded() async {}

  @override
  Future<void> resetOnboarding() async {}

  @override
  Future<void> setLanguage(String language) async {}
}

/// Stands for the preferences [SettingsRepository] asks for; never read.
class _NoPreferences implements SharedPreferences {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('The fake settings read no preferences');
}

/// url_launcher without the plugin: whether the device can send an email.
/// The mixin lets it be set as the platform outside a test, which is what
/// shutter's shot is not at the time the preview function runs.
class FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  FakeUrlLauncher({required this.canEmail});

  final bool canEmail;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async =>
      url.startsWith('mailto:') ? canEmail : true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => true;
}
