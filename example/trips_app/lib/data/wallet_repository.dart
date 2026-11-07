import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trips_app/data/models.dart';

/// The cards the user keeps for booking.
abstract class WalletRepository extends ChangeNotifier {
  List<PaymentCard> get cards;
  Future<void> add(PaymentCard card);
}

class ApiWalletRepository extends WalletRepository {
  final _cards = <PaymentCard>[];

  @override
  List<PaymentCard> get cards => List.unmodifiable(_cards);

  @override
  Future<void> add(PaymentCard card) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _cards.add(card);
    notifyListeners();
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => ApiWalletRepository(),
);

/// The hotels the user saved.
abstract class WishlistRepository extends ChangeNotifier {
  Set<String> get saved;
  void toggle(String hotelId);
}

class ApiWishlistRepository extends WishlistRepository {
  final _saved = <String>{};

  @override
  Set<String> get saved => Set.unmodifiable(_saved);

  @override
  void toggle(String hotelId) {
    if (!_saved.remove(hotelId)) _saved.add(hotelId);
    notifyListeners();
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => ApiWishlistRepository(),
);
