import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_app/data/models.dart';

abstract class CartRepository {
  List<CartItem> get items;
  void add(Product product);
  void clear();
}

class MemoryCartRepository implements CartRepository {
  final List<CartItem> _items = [];

  @override
  List<CartItem> get items => List.unmodifiable(_items);

  @override
  void add(Product product) =>
      _items.add(CartItem(product: product, quantity: 1));

  @override
  void clear() => _items.clear();
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => MemoryCartRepository(),
);
