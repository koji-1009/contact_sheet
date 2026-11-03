import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_app/data/cart_repository.dart';
import 'package:shop_app/data/models.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartRepositoryProvider);
    // As the cart changes (a product added, over this page).
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => _cart(context, cart),
    );
  }

  Widget _cart(BuildContext context, CartRepository cart) {
    return Scaffold(
      appBar: AppBar(title: const Text('カート')),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('カートは空です'))
                : ListView(
                    children: [
                      for (final item in cart.items) CartItemTile(item: item),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () => context.push('/checkout'),
                child: const Text('購入手続きへ'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A product in the cart: tapping it opens the product.
class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(item.product.name),
    subtitle: Text('${item.quantity} 点'),
    trailing: Text('¥${item.product.price * item.quantity}'),
    onTap: () => context.push('/products/${item.product.id}'),
  );
}
