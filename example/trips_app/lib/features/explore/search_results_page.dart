import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// The hotels a search found: filters, the map, and each hotel.
class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));
    return Scaffold(
      appBar: AppBar(
        title: Text('“$query”'),
        actions: [
          IconButton(
            tooltip: 'Map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.go('/explore/map'),
          ),
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(
              Uri(
                path: '/explore/search/results/filters',
                queryParameters: {'q': query},
              ).toString(),
            ),
          ),
        ],
      ),
      body: AsyncBody(
        value: results,
        data: (hotels) => hotels.isEmpty
            ? const Center(child: Text('No stays match. Try another place.'))
            : ListView(
                children: [
                  for (final h in hotels)
                    HotelTile(
                      hotel: h,
                      onTap: () => context.go('/explore/hotels/${h.id}'),
                    ),
                ],
              ),
      ),
    );
  }
}
