import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_app/data/cart_repository.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartRepositoryProvider);
    final total = cart.items.fold<int>(
      0,
      (sum, item) => sum + item.product.price * item.quantity,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('決済')),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('カートは空です'))
                : ListView(
                    children: [
                      for (final item in cart.items)
                        ListTile(
                          title: Text(item.product.name),
                          trailing: Text('¥${item.product.price}'),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('pay'),
                onPressed: cart.items.isEmpty
                    ? null
                    : () {
                        cart.clear();
                        context.go('/complete');
                      },
                child: Text('¥$total を支払う'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
