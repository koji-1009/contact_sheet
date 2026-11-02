import 'package:material_ui/material_ui.dart';

import 'package:notes_app/data/notes.dart';
import 'package:notes_app/routes.dart';

void main() {
  final store = NotesStore(_ServerApi())..load();
  runApp(
    NotesScope(
      store: store,
      child: MaterialApp(
        theme: notesTheme,
        initialRoute: '/',
        onGenerateRoute: onGenerateRoute,
      ),
    ),
  );
}

/// The real server, which this example does not have.
class _ServerApi implements NotesApi {
  @override
  Future<List<Note>> fetch() async => const [];

  @override
  Future<void> save(Note note) async {}

  @override
  Future<void> delete(String id) async {}
}
