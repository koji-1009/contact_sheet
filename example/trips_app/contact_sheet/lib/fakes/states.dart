// The states pages start in: public top-level functions
// `Widget name(Widget child)` that put the app's DI on fakes.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trips_app/data/auth_repository.dart';
import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/data/inbox_repository.dart';
import 'package:trips_app/data/settings_repository.dart';
import 'package:trips_app/data/trip_repository.dart';
import 'package:trips_app/data/wallet_repository.dart';
import 'package:trips_app_sheet/fakes/fakes.dart';

Widget _scope(
  Widget child, {
  bool onboarded = true,
  bool signedIn = false,
  bool booked = false,
  bool card = false,
  bool saved = false,
  String language = 'English',
}) => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(onboarded: onboarded, language: language),
    ),
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(signedIn: signedIn),
    ),
    hotelRepositoryProvider.overrideWithValue(const FakeHotelRepository()),
    tripRepositoryProvider.overrideWithValue(
      FakeTripRepository(booked: booked),
    ),
    walletRepositoryProvider.overrideWithValue(
      FakeWalletRepository(card: card),
    ),
    wishlistRepositoryProvider.overrideWithValue(
      FakeWishlistRepository(saved: saved),
    ),
    inboxRepositoryProvider.overrideWithValue(const FakeInboxRepository()),
  ],
  child: child,
);

/// The app as first installed: the welcome not seen yet, a guest.
Widget fresh(Widget child) => _scope(child, onboarded: false);

/// The welcome seen, not signed in.
Widget guest(Widget child) => _scope(child);

/// Signed in as Aki: no trip, no card, nothing saved.
Widget signedIn(Widget child) => _scope(child, signedIn: true);

/// Signed in, a trip at the Harbor Inn booked.
Widget booked(Widget child) => _scope(child, signedIn: true, booked: true);

/// Signed in, a Visa kept.
Widget withCard(Widget child) => _scope(child, signedIn: true, card: true);

/// Signed in, the Harbor Inn saved.
Widget saved(Widget child) => _scope(child, signedIn: true, saved: true);

/// The language set to Japanese.
Widget japanese(Widget child) => _scope(child, language: '日本語');

/// The language set to French.
Widget french(Widget child) => _scope(child, language: 'Français');
