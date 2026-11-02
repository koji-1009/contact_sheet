import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_app/data/auth_repository.dart';
import 'package:shop_app/data/cart_repository.dart';
import 'package:shop_app/data/product_repository.dart';

import 'package:shop_app_sheet/fakes/fakes.dart';

// The states a page can be shown in. Each is a `@Preview.wrapper`: it puts
// the app's providers on fakes. They are public top-level functions, so the
// annotations can refer to them.

Widget guest(Widget child) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository.guest()),
    productRepositoryProvider.overrideWithValue(FakeProductRepository()),
    cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
  ],
  child: child,
);

Widget loggedIn(Widget child) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository.loggedIn()),
    productRepositoryProvider.overrideWithValue(FakeProductRepository()),
    cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
  ],
  child: child,
);

Widget loggedInCart2(Widget child) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository.loggedIn()),
    productRepositoryProvider.overrideWithValue(FakeProductRepository()),
    cartRepositoryProvider.overrideWithValue(FakeCartRepository(items: 2)),
  ],
  child: child,
);
