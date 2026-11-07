import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/settings_repository.dart';

/// The languages: one chosen, back to the settings.
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  static const _languages = ['English', '日本語', 'Français'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView(
        children: [
          for (final l in _languages)
            ListTile(
              title: Text(l),
              trailing: l == settings.language ? const Icon(Icons.check) : null,
              onTap: () async {
                await settings.setLanguage(l);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
    );
  }
}
