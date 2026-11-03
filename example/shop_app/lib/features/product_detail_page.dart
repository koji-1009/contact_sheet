import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_app/data/cart_repository.dart';
import 'package:shop_app/data/product_repository.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(productId));
    final appBar = AppBar(title: const Text('Product'));
    return product.when(
      // The details scroll, the buy button stays at the bottom: it fits a
      // phone held either way, a tablet and a desktop window.
      data: (p) => Scaffold(
        appBar: appBar,
        // Clear of a phone's notch when held sideways: a ListView given its
        // own padding does not add the safe area on its own.
        body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lightbulb_outline, size: 64),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(
                '¥${p.price}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton(
            key: const ValueKey('buy'),
            onPressed: () {
              ref.read(cartRepositoryProvider).add(p);
              context.push('/checkout');
            },
            child: const Text('Buy now'),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: appBar,
        body: Center(child: Text('Could not load: $e')),
      ),
      loading: () => Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
