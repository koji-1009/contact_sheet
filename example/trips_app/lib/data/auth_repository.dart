import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who is signed in; notifies its listeners when that changes.
abstract class AuthRepository extends ChangeNotifier {
  bool get isSignedIn;
  String? get userName;
  Future<void> signIn(String email);
  Future<void> signUp(String email, String name);
  void signOut();
}

/// The app's own implementation. A real app would call its backend here.
class ApiAuthRepository extends AuthRepository {
  String? _user;

  @override
  bool get isSignedIn => _user != null;

  @override
  String? get userName => _user;

  @override
  Future<void> signIn(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _user = email.split('@').first;
    notifyListeners();
  }

  @override
  Future<void> signUp(String email, String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _user = name;
    notifyListeners();
  }

  @override
  void signOut() {
    _user = null;
    notifyListeners();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(),
);
