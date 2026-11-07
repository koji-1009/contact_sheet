import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/wallet_repository.dart';

/// Booking, second: the card to pay with. Without a card kept, one is added
/// first; Continue waits for one.
class PaymentPage extends ConsumerWidget {
  const PaymentPage({super.key, required this.hotelId, required this.roomId});

  final String hotelId;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletRepositoryProvider);
    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: ListView(
          children: [
            for (final c in wallet.cards)
              ListTile(
                leading: Icon(
                  c == wallet.cards.first
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text('${c.brand} •••• ${c.last4}'),
              ),
            if (wallet.cards.isEmpty)
              const ListTile(title: Text('No card yet')),
            ListTile(
              leading: const Icon(Icons.add_card),
              title: const Text('Add a card'),
              onTap: () => context.push('/cards/add'),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: wallet.cards.isEmpty
                ? null
                : () => context.push(
                    Uri(
                      path: '/book/review',
                      queryParameters: {'hotel': hotelId, 'room': roomId},
                    ).toString(),
                  ),
            child: const Text('Continue'),
          ),
        ),
      ),
    );
  }
}
