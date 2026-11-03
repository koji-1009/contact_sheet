import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_app/data/models.dart';

/// Notifies its listeners when what is in the cart changes.
abstract class CartRepository extends ChangeNotifier {
  List<CartItem> get items;
  void add(Product product);
  void clear();
}

class MemoryCartRepository extends CartRepository {
  final List<CartItem> _items = [];

  @override
  List<CartItem> get items => List.unmodifiable(_items);

  @override
  void add(Product product) {
    _items.add(CartItem(product: product, quantity: 1));
    notifyListeners();
  }

  @override
  void clear() {
    _items.clear();
    notifyListeners();
  }
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => MemoryCartRepository(),
);
