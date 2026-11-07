import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/trip_repository.dart';

/// A trip: its itinerary, its voucher, a message to the hotel, and
/// cancelling it.
class TripPage extends ConsumerWidget {
  const TripPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripRepositoryProvider).trip(tripId);
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This trip was cancelled.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(trip.hotel.name)),
      body: ListView(
        children: [
          ListTile(title: Text(trip.dates), subtitle: Text(trip.room.name)),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Itinerary'),
            onTap: () => context.go('/trips/$tripId/itinerary'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('Voucher'),
            onTap: () => context.push('/trips/$tripId/voucher'),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Message the hotel'),
            onTap: () => context.go('/inbox/conversations/c1'),
          ),
          ListTile(
            leading: const Icon(Icons.cancel_outlined),
            title: const Text('Cancel booking'),
            onTap: () => context.push('/trips/$tripId/cancel'),
          ),
        ],
      ),
    );
  }
}
