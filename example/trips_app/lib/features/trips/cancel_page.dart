import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/trip_repository.dart';

/// Cancelling a booking, over the whole screen: cancelled, the Trips tab's
/// first page; kept, back to the trip.
class CancelPage extends ConsumerWidget {
  const CancelPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Close',
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      title: const Text('Cancel booking'),
    ),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Cancelling is free until 3 days before you check in. '
        'The full amount goes back to your card.',
      ),
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await ref.read(tripRepositoryProvider).cancel(tripId);
              if (context.mounted) context.go('/trips');
            },
            child: const Text('Cancel booking'),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Keep it'),
          ),
        ],
      ),
    ),
  );
}
