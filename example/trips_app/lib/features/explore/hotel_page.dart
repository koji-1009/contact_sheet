import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';
import 'package:trips_app/data/hotel_repository.dart';
import 'package:trips_app/data/models.dart';
import 'package:trips_app/data/wallet_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// A hotel: its photos, what guests say, its rooms; saved to the wishlist
/// by the heart, which asks a guest to sign in first.
class HotelPage extends ConsumerWidget {
  const HotelPage({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotel = ref.watch(hotelProvider(hotelId));
    final auth = ref.watch(authRepositoryProvider);
    final wishlist = ref.watch(wishlistRepositoryProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([auth, wishlist]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(hotel.value?.name ?? ''),
          actions: [
            IconButton(
              tooltip: wishlist.saved.contains(hotelId) ? 'Saved' : 'Save',
              icon: Icon(
                wishlist.saved.contains(hotelId)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              onPressed: () {
                if (auth.isSignedIn) {
                  wishlist.toggle(hotelId);
                } else {
                  context.push(
                    Uri(
                      path: '/sign-in',
                      queryParameters: {'from': '/explore/hotels/$hotelId'},
                    ).toString(),
                  );
                }
              },
            ),
          ],
        ),
        body: AsyncBody(value: hotel, data: (h) => _body(context, h)),
      ),
    );
  }

  Widget _body(BuildContext context, Hotel h) => ListView(
    children: [
      InkWell(
        onTap: () => context.push('/photos/${h.id}'),
        child: Container(
          height: 200,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Center(child: Icon(Icons.photo_library, size: 64)),
        ),
      ),
      ListTile(
        title: Text(h.name, style: Theme.of(context).textTheme.headlineSmall),
        subtitle: Text('${h.city} · from ¥${h.price} a night'),
      ),
      ListTile(
        leading: const Icon(Icons.star),
        title: Text('${h.rating} · Read the reviews'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/explore/hotels/${h.id}/reviews'),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => context.push('/explore/hotels/${h.id}/rooms'),
          child: const Text('Choose a room'),
        ),
      ),
    ],
  );
}
