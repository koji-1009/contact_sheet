import 'package:material_ui/material_ui.dart';

import 'package:notes_app/data/notes.dart';

class NotePage extends StatelessWidget {
  const NotePage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final store = NotesScope.of(context);
    final note = store.byId(id);
    return Scaffold(
      appBar: AppBar(
        title: Text(note?.title ?? ''),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, '/edit', arguments: id),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await store.delete(id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(note?.body ?? 'This note was deleted'),
      ),
    );
  }
}
