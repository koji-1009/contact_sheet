import 'package:material_ui/material_ui.dart';

import 'package:notes_app/data/notes.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NotesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ'),
        actions: [
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : store.notes.isEmpty
          ? const Center(child: Text('メモはまだありません'))
          : ListView(
              children: [
                for (final note in store.notes)
                  ListTile(
                    key: ValueKey('note-${note.id}'),
                    title: Text(note.title),
                    subtitle: Text(note.body, maxLines: 1),
                    onTap: () =>
                        Navigator.pushNamed(context, '/note', arguments: note.id),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新しいメモ',
        onPressed: () => Navigator.pushNamed(context, '/edit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
