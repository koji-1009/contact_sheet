import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// The Explore tab's first page: a search field, destinations, and the
/// popular stays.
class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(destinationsProvider);
    final popular = ref.watch(popularHotelsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => context.go('/explore/search'),
              child: const InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                child: Text('Where to?'),
              ),
            ),
          ),
          const _Heading('Destinations'),
          SizedBox(
            height: 120,
            child: AsyncBody(
              value: destinations,
              data: (items) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final d in items)
                    Card(
                      child: InkWell(
                        onTap: () =>
                            context.go('/explore/destinations/${d.id}'),
                        child: SizedBox(
                          width: 160,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(d.blurb),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const _Heading('Popular stays'),
          AsyncBody(
            value: popular,
            data: (hotels) => Column(
              children: [
                for (final h in hotels)
                  HotelTile(
                    hotel: h,
                    onTap: () => context.go('/explore/hotels/${h.id}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}
