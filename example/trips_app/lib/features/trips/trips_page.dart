import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';
import 'package:trips_app/data/trip_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// The Trips tab's first page: a guest is asked to sign in; signed in, the
/// trips booked, or a way to Explore when there are none.
class TripsPage extends ConsumerWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final trips = ref.watch(tripRepositoryProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([auth, trips]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Trips')),
        body: !auth.isSignedIn
            ? SignInPrompt(
                icon: Icons.luggage_outlined,
                text: 'Sign in to see your trips.',
                onSignIn: () => context.push(
                  Uri(
                    path: '/sign-in',
                    queryParameters: {'from': '/trips'},
                  ).toString(),
                ),
              )
            : trips.trips.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No trips yet.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/explore'),
                      child: const Text('Find a stay'),
                    ),
                  ],
                ),
              )
            : ListView(
                children: [
                  for (final t in trips.trips)
                    ListTile(
                      leading: const Icon(Icons.hotel),
                      title: Text(t.hotel.name),
                      subtitle: Text(t.dates),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/trips/${t.id}'),
                    ),
                ],
              ),
      ),
    );
  }
}
