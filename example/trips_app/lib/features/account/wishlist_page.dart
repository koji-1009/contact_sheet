import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/data/wallet_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// The stays the user saved: each opens its hotel, in the Explore tab.
class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistRepositoryProvider);
    final hotels = ref.watch(popularHotelsProvider);
    return ListenableBuilder(
      listenable: wishlist,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Saved stays')),
        body: AsyncBody(
          value: hotels,
          data: (all) {
            final saved = [
              for (final h in all)
                if (wishlist.saved.contains(h.id)) h,
            ];
            if (saved.isEmpty) {
              return const Center(
                child: Text('Tap the heart on a stay to save it here.'),
              );
            }
            return ListView(
              children: [
                for (final h in saved)
                  HotelTile(
                    hotel: h,
                    onTap: () => context.go('/explore/hotels/${h.id}'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
