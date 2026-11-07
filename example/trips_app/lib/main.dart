import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trips_app/data/auth_repository.dart';
import 'package:trips_app/data/settings_repository.dart';
import 'package:trips_app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TripsApp(),
    ),
  );
}

class TripsApp extends ConsumerStatefulWidget {
  const TripsApp({super.key});

  @override
  ConsumerState<TripsApp> createState() => _TripsAppState();
}

class _TripsAppState extends ConsumerState<TripsApp> {
  late final _router = appRouter(
    Listenable.merge([
      ref.read(authRepositoryProvider),
      ref.read(settingsRepositoryProvider),
    ]),
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Trips',
    theme: appTheme,
    routerConfig: _router,
  );
}
