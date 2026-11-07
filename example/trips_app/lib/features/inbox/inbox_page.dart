import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';
import 'package:trips_app/data/inbox_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// The Inbox tab's first page: a guest is asked to sign in; signed in, the
/// threads with hotels.
class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Inbox'),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        body: !auth.isSignedIn
            ? SignInPrompt(
                icon: Icons.chat_bubble_outline,
                text: 'Sign in to message the hotels you booked.',
                onSignIn: () => context.push(
                  Uri(
                    path: '/sign-in',
                    queryParameters: {'from': '/inbox'},
                  ).toString(),
                ),
              )
            : AsyncBody(
                value: ref.watch(conversationsProvider),
                data: (threads) => ListView(
                  children: [
                    for (final c in threads)
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.hotel)),
                        title: Text(c.hotelName),
                        subtitle: Text(c.lastMessage),
                        onTap: () => context.go('/inbox/conversations/${c.id}'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
