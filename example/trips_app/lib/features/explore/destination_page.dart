import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// A city: what it is, and the stays in it.
class DestinationPage extends ConsumerWidget {
  const DestinationPage({super.key, required this.destinationId});

  final String destinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotels = ref.watch(destinationHotelsProvider(destinationId));
    final name = destinationId[0].toUpperCase() + destinationId.substring(1);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: AsyncBody(
        value: hotels,
        data: (items) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Stays in $name'),
            ),
            for (final h in items)
              HotelTile(
                hotel: h,
                onTap: () => context.push('/explore/hotels/${h.id}'),
              ),
          ],
        ),
      ),
    );
  }
}
