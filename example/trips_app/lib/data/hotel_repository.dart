import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trips_app/data/models.dart';

/// The hotels, rooms and reviews, from the backend.
abstract class HotelRepository {
  Future<List<Destination>> destinations();
  Future<List<Hotel>> popular();
  Future<List<Hotel>> inDestination(String destinationId);
  Future<List<Hotel>> search(String query);
  Future<Hotel> hotel(String id);
  Future<List<Room>> rooms(String hotelId);
  Future<List<Review>> reviews(String hotelId);
}

/// The app's own implementation: a real app would call its API here.
class ApiHotelRepository implements HotelRepository {
  static const _hotels = [
    Hotel(
      id: 'h1',
      name: 'Harbor Inn',
      city: 'Kobe',
      price: 14000,
      rating: 4.5,
    ),
    Hotel(
      id: 'h2',
      name: 'Maple Lodge',
      city: 'Kyoto',
      price: 22000,
      rating: 4.8,
    ),
    Hotel(
      id: 'h3',
      name: 'Sky Tower',
      city: 'Tokyo',
      price: 31000,
      rating: 4.2,
    ),
  ];

  Future<T> _later<T>(T value) =>
      Future<T>.delayed(const Duration(milliseconds: 600), () => value);

  @override
  Future<List<Destination>> destinations() => _later(const [
    Destination(id: 'kyoto', name: 'Kyoto', blurb: 'Temples and gardens'),
    Destination(id: 'kobe', name: 'Kobe', blurb: 'The harbor and the hills'),
  ]);

  @override
  Future<List<Hotel>> popular() => _later(_hotels);

  @override
  Future<List<Hotel>> inDestination(String destinationId) => _later([
    for (final h in _hotels)
      if (h.city.toLowerCase() == destinationId) h,
  ]);

  @override
  Future<List<Hotel>> search(String query) => _later([
    for (final h in _hotels)
      if ('${h.name} ${h.city}'.toLowerCase().contains(query.toLowerCase())) h,
  ]);

  @override
  Future<Hotel> hotel(String id) =>
      _later(_hotels.firstWhere((h) => h.id == id));

  @override
  Future<List<Room>> rooms(String hotelId) => _later(const [
    Room(id: 'r1', name: 'Twin room', price: 14000),
    Room(id: 'r2', name: 'Suite', price: 38000),
  ]);

  @override
  Future<List<Review>> reviews(String hotelId) => _later(const [
    Review(author: 'Aki', text: 'Quiet, and close to the station.', stars: 5),
    Review(author: 'Ben', text: 'Small rooms.', stars: 3),
  ]);
}

final hotelRepositoryProvider = Provider<HotelRepository>(
  (ref) => ApiHotelRepository(),
);

final destinationsProvider = FutureProvider<List<Destination>>(
  (ref) => ref.watch(hotelRepositoryProvider).destinations(),
);

final popularHotelsProvider = FutureProvider<List<Hotel>>(
  (ref) => ref.watch(hotelRepositoryProvider).popular(),
);

final destinationHotelsProvider = FutureProvider.family<List<Hotel>, String>(
  (ref, id) => ref.watch(hotelRepositoryProvider).inDestination(id),
);

final searchResultsProvider = FutureProvider.family<List<Hotel>, String>(
  (ref, query) => ref.watch(hotelRepositoryProvider).search(query),
);

final hotelProvider = FutureProvider.family<Hotel, String>(
  (ref, id) => ref.watch(hotelRepositoryProvider).hotel(id),
);

final roomsProvider = FutureProvider.family<List<Room>, String>(
  (ref, id) => ref.watch(hotelRepositoryProvider).rooms(id),
);

final reviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, id) => ref.watch(hotelRepositoryProvider).reviews(id),
);
