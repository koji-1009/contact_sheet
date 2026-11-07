import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// The popular stays on a map: a pin's card opens its hotel.
class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotels = ref.watch(popularHotelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.map, size: 120)),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AsyncBody(
              value: hotels,
              data: (items) => Card(
                child: HotelTile(
                  hotel: items.first,
                  onTap: () =>
                      context.push('/explore/hotels/${items.first.id}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
