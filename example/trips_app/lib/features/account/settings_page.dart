import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/settings_repository.dart';

/// The app's settings: its language, and the welcome shown again (which
/// the router then shows in place of everything else).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepositoryProvider);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: Text(settings.language),
              onTap: () => context.go('/account/settings/language'),
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Show the welcome again'),
              onTap: settings.resetOnboarding,
            ),
          ],
        ),
      ),
    );
  }
}
