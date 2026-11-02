import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifies its listeners when the user logs in or out.
abstract class AuthRepository extends ChangeNotifier {
  bool get isLoggedIn;
  String? get userName;
  Future<void> login();
  Future<void> logout();
}

/// The app's own implementation. A real app would call its backend here.
class SessionAuthRepository extends AuthRepository {
  String? _user;

  @override
  bool get isLoggedIn => _user != null;

  @override
  String? get userName => _user;

  @override
  Future<void> login() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _user = 'koji';
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SessionAuthRepository(),
);
