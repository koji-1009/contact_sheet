import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shop_app/data/models.dart';

abstract class ProductRepository {
  Future<List<Product>> list();
  Future<Product> find(String id);
}

/// The app's own implementation. A real app would call its backend here.
class ApiProductRepository implements ProductRepository {
  static const _catalog = [
    Product(id: 'p1', name: 'テーブルランプ', price: 1200),
    Product(id: 'p2', name: 'マグカップ', price: 800),
    Product(id: 'p3', name: 'ノート', price: 300),
  ];

  @override
  Future<List<Product>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _catalog;
  }

  @override
  Future<Product> find(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _catalog.firstWhere((p) => p.id == id);
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ApiProductRepository(),
);

final productsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).list(),
);

final productProvider = FutureProvider.family<Product, String>(
  (ref, id) => ref.watch(productRepositoryProvider).find(id),
);
