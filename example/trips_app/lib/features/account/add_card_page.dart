import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/models.dart';
import 'package:trips_app/data/wallet_repository.dart';

/// A new card, over the whole screen: saved, back to where it was added
/// from (the payment of a booking, or the payment methods).
class AddCardPage extends ConsumerWidget {
  const AddCardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Add a card')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        TextField(decoration: InputDecoration(labelText: 'Card number')),
        TextField(decoration: InputDecoration(labelText: 'Expiry')),
        TextField(decoration: InputDecoration(labelText: 'CVC')),
      ],
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: () async {
          await ref
              .read(walletRepositoryProvider)
              .add(const PaymentCard(brand: 'Visa', last4: '4242'));
          if (context.mounted) context.pop();
        },
        child: const Text('Save card'),
      ),
    ),
  );
}
