import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device's preferences, opened by `main` before the app starts.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main overrides it'),
);

/// What the app keeps on the device: whether the welcome was seen, and the
/// language chosen.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  bool get onboarded => _prefs.getBool('onboarded') ?? false;

  String get language => _prefs.getString('language') ?? 'English';

  Future<void> setOnboarded() async {
    await _prefs.setBool('onboarded', true);
    notifyListeners();
  }

  /// Shows the welcome again, from the settings.
  Future<void> resetOnboarding() async {
    await _prefs.setBool('onboarded', false);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    await _prefs.setString('language', language);
    notifyListeners();
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);
