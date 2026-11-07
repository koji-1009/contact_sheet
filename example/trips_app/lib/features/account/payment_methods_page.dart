import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/wallet_repository.dart';

/// The cards kept for booking, and adding one.
class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletRepositoryProvider);
    return ListenableBuilder(
      listenable: wallet,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Payment methods')),
        body: ListView(
          children: [
            if (wallet.cards.isEmpty)
              const ListTile(title: Text('No cards yet.')),
            for (final c in wallet.cards)
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text('${c.brand} •••• ${c.last4}'),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/cards/add'),
          icon: const Icon(Icons.add),
          label: const Text('Add a card'),
        ),
      ),
    );
  }
}
