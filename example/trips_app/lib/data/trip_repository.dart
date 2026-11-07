import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trips_app/data/models.dart';

/// The user's trips: booked, and cancelled.
abstract class TripRepository extends ChangeNotifier {
  List<Trip> get trips;
  Trip? trip(String id);
  Future<Trip> book(Hotel hotel, Room room);
  Future<void> cancel(String id);
}

/// The app's own implementation: a real app would call its API here.
class ApiTripRepository extends TripRepository {
  final _trips = <Trip>[];

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
  Future<Trip> book(Hotel hotel, Room room) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final trip = Trip(
      id: 't${_trips.length + 1}',
      hotel: hotel,
      room: room,
      dates: 'Dec 20 – Dec 22',
    );
    _trips.add(trip);
    notifyListeners();
    return trip;
  }

  @override
  Future<void> cancel(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => ApiTripRepository(),
);
