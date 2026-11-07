import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trips_app/data/models.dart';

/// The messages with hotels, and the app's notifications.
abstract class InboxRepository {
  Future<List<Conversation>> conversations();
  Future<List<String>> messages(String conversationId);
  Future<List<AppNotification>> notifications();
}

/// The app's own implementation: a real app would call its API here.
class ApiInboxRepository implements InboxRepository {
  @override
  Future<List<Conversation>> conversations() async => const [
    Conversation(
      id: 'c1',
      hotelName: 'Harbor Inn',
      lastMessage: 'Your room is ready from 3 pm.',
    ),
  ];

  @override
  Future<List<String>> messages(String conversationId) async => const [
    'Hello! Can we check in early?',
    'Your room is ready from 3 pm.',
  ];

  @override
  Future<List<AppNotification>> notifications() async => const [
    AppNotification(
      id: 'n1',
      text: 'Your stay at Harbor Inn is in 3 days',
      tripId: 't1',
    ),
  ];
}

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => ApiInboxRepository(),
);

final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(inboxRepositoryProvider).conversations(),
);

final messagesProvider = FutureProvider.family<List<String>, String>(
  (ref, id) => ref.watch(inboxRepositoryProvider).messages(id),
);

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(inboxRepositoryProvider).notifications(),
);
