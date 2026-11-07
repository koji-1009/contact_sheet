import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/inbox_repository.dart';
import 'package:trips_app/features/widgets.dart';

/// A thread with a hotel: the messages, and one to send.
class ConversationPage extends ConsumerWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Harbor Inn')),
    body: AsyncBody(
      value: ref.watch(messagesProvider(conversationId)),
      data: (messages) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, m) in messages.indexed)
            Align(
              alignment: i.isEven
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(m),
                ),
              ),
            ),
        ],
      ),
    ),
    bottomNavigationBar: const Padding(
      padding: EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Write a message',
          suffixIcon: Icon(Icons.send),
        ),
      ),
    ),
  );
}
