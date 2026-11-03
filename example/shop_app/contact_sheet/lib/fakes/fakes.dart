import 'package:shop_app/data/auth_repository.dart';
import 'package:shop_app/data/cart_repository.dart';
import 'package:shop_app/data/models.dart';
import 'package:shop_app/data/product_repository.dart';

/// Fakes at the repository layer: no network, the same in shutter (VM) and
/// in the live panel.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository.guest() : _user = null;
  FakeAuthRepository.loggedIn() : _user = 'koji';

  String? _user;

  @override
  bool get isLoggedIn => _user != null;

  @override
  String? get userName => _user;

  @override
  Future<void> login() async {
    _user = 'koji';
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}

class FakeProductRepository implements ProductRepository {
  static const products = [
    Product(id: 'p1', name: 'Table lamp', price: 1200),
    Product(id: 'p2', name: 'Mug', price: 800),
    Product(id: 'p3', name: 'Notebook', price: 300),
  ];

  @override
  Future<List<Product>> list() async => products;

  @override
  Future<Product> find(String id) async =>
      products.firstWhere((p) => p.id == id);
}

class FakeCartRepository extends CartRepository {
  FakeCartRepository({int items = 0})
    : _items = [
        for (final p in FakeProductRepository.products.take(items))
          CartItem(product: p, quantity: 1),
      ];

  final List<CartItem> _items;

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
