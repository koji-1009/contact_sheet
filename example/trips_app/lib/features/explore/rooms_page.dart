import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// A hotel's rooms: selecting one starts booking it (the router sends a
/// guest to sign in first).
class RoomsPage extends ConsumerWidget {
  const RoomsPage({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Choose a room')),
    body: AsyncBody(
      value: ref.watch(roomsProvider(hotelId)),
      data: (rooms) => ListView(
        children: [
          for (final r in rooms)
            ListTile(
              title: Text(r.name),
              subtitle: Text('¥${r.price} a night'),
              trailing: FilledButton.tonal(
                onPressed: () => context.push(
                  Uri(
                    path: '/book/guests',
                    queryParameters: {'hotel': hotelId, 'room': r.id},
                  ).toString(),
                ),
                child: const Text('Select'),
              ),
            ),
        ],
      ),
    ),
  );
}
