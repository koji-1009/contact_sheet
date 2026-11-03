import 'package:material_ui/material_ui.dart';

import 'package:notes_app/data/notes.dart';
import 'package:notes_app/pages/notes_page.dart';
import 'package:notes_app/routes.dart';

// The team's preview wrappers: each page in the app's theme, with a
// NotesStore on fixed notes, as main.dart gives the real one.

const previewNotes = [
  Note(id: 'n1', title: '買い物', body: '牛乳、卵、パン'),
  Note(id: 'n2', title: '会議のメモ', body: '来週までに見積もりを出す'),
  Note(id: 'n3', title: '本', body: '読みたい本のリスト'),
];

class _FakeApi implements NotesApi {
  @override
  Future<List<Note>> fetch() async => previewNotes;

  @override
  Future<void> save(Note note) async {}

  @override
  Future<void> delete(String id) async {}
}

/// [page] with the notes: alone, or, [over] the list, as the app pushes it
/// (its back button shown; a new note's close, as a full-screen [dialog]).
Widget _with(
  Widget page, {
  List<Note> notes = previewNotes,
  bool loading = false,
  bool over = false,
  bool dialog = false,
}) {
  final store = NotesStore(_FakeApi())
    ..notes = notes
    ..loading = loading;
  return NotesScope(
    store: store,
    child: MaterialApp(
      theme: notesTheme,
      debugShowCheckedModeBanner: false,
      onGenerateInitialRoutes: (_) => [
        if (over) MaterialPageRoute<void>(builder: (_) => const NotesPage()),
        MaterialPageRoute<void>(fullscreenDialog: dialog, builder: (_) => page),
      ],
      onGenerateRoute: onGenerateRoute,
    ),
  );
}

Widget threeNotes(Widget page) => _with(page);

Widget noNotes(Widget page) => _with(page, notes: const []);

Widget loadingNotes(Widget page) => _with(page, notes: const [], loading: true);

/// A page the list opens, over it.
Widget overNotes(Widget page) => _with(page, over: true);

/// A new note, as the list opens it: a full-screen dialog over it.
Widget newOverNotes(Widget page) => _with(page, over: true, dialog: true);
