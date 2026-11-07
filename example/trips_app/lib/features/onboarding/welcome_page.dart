import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/settings_repository.dart';

/// What the app shows until the welcome is seen: getting started, or
/// signing in to an account the user has.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.travel_explore, size: 96),
              const SizedBox(height: 24),
              Text(
                'Stays you will remember',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Find a place, book it in a minute, and keep every trip in one place.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await settings.setOnboarded();
                  if (context.mounted) context.go('/explore');
                },
                child: const Text('Get started'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await settings.setOnboarded();
                  if (context.mounted) await context.push('/sign-in');
                },
                child: const Text('I have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
