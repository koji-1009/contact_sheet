import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/inbox_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// What the app told the user of, over the whole screen: each opens its
/// trip, in the Trips tab.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: AsyncBody(
      value: ref.watch(notificationsProvider),
      data: (items) => items.isEmpty
          ? const Center(child: Text('Nothing new.'))
          : ListView(
              children: [
                for (final n in items)
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(n.text),
                    onTap: () => context.go('/trips/${n.tripId}'),
                  ),
              ],
            ),
    ),
  );
}
