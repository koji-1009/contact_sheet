import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// What guests wrote of a hotel.
class ReviewsPage extends ConsumerWidget {
  const ReviewsPage({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Reviews')),
    body: AsyncBody(
      value: ref.watch(reviewsProvider(hotelId)),
      data: (reviews) => ListView(
        children: [
          for (final r in reviews)
            ListTile(
              title: Text('${'★' * r.stars} ${r.author}'),
              subtitle: Text(r.text),
            ),
        ],
      ),
    ),
  );
}
