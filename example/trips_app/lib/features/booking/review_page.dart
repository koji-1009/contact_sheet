import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/data/trip_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// Booking, last: what is booked, and paying for it. The booking done
/// starts the history again.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key, required this.hotelId, required this.roomId});

  final String hotelId;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotel = ref.watch(hotelProvider(hotelId));
    final rooms = ref.watch(roomsProvider(hotelId));
    return Scaffold(
      appBar: AppBar(title: const Text('Review and pay')),
      body: AsyncBody(
        value: hotel,
        data: (h) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(h.name, style: Theme.of(context).textTheme.headlineSmall),
            const Text('Dec 20 – Dec 22 · 2 nights · 2 adults'),
            const Divider(),
            ListTile(
              title: const Text('Total'),
              trailing: Text('¥${h.price * 2}'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () async {
            final room = rooms.requireValue.firstWhere((r) => r.id == roomId);
            final trip = await ref
                .read(tripRepositoryProvider)
                .book(hotel.requireValue, room);
            if (context.mounted) context.go('/book/done/${trip.id}');
          },
          child: Text('Pay ¥${(hotel.value?.price ?? 0) * 2}'),
        ),
      ),
    );
  }
}
