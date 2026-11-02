import 'package:flutter/widgets.dart';

class Note {
  const Note({required this.id, required this.title, required this.body});

  final String id;
  final String title;
  final String body;
}

/// Where the notes are kept: a server in the app.
abstract class NotesApi {
  Future<List<Note>> fetch();
  Future<void> save(Note note);
  Future<void> delete(String id);
}

/// The notes the pages show, read from a [NotesApi].
class NotesStore extends ChangeNotifier {
  NotesStore(this.api);

  final NotesApi api;
  List<Note> notes = const [];
  bool loading = true;

  Future<void> load() async {
    notes = await api.fetch();
    loading = false;
    notifyListeners();
  }

  Note? byId(String id) {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  Future<void> save(Note note) async {
    await api.save(note);
    notes = [
      for (final n in notes)
        if (n.id != note.id) n,
      note,
    ];
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await api.delete(id);
    notes = [
      for (final n in notes)
        if (n.id != id) n,
    ];
    notifyListeners();
  }
}

/// Gives the pages the [NotesStore].
class NotesScope extends InheritedNotifier<NotesStore> {
  const NotesScope({super.key, required NotesStore store, required super.child})
    : super(notifier: store);

  static NotesStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NotesScope>()!.notifier!;
}
