import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_app/data/auth_repository.dart';
import 'package:shop_app/data/models.dart';
import 'package:shop_app/data/product_repository.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final products = ref.watch(productsProvider);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => _build(context, auth, products),
    );
  }

  Widget _build(
    BuildContext context,
    AuthRepository auth,
    AsyncValue<List<Product>> products,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
          if (auth.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('Hi, ${auth.userName}')),
            )
          else
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Log in'),
            ),
        ],
      ),
      body: products.when(
        data: (items) => ListView(
          children: [
            for (final p in items)
              ListTile(
                key: ValueKey('product-${p.id}'),
                title: Text(p.name),
                subtitle: Text('¥${p.price}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/products/${p.id}'),
              ),
          ],
        ),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
