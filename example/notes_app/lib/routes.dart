import 'package:material_ui/material_ui.dart';

import 'package:notes_app/pages/edit_page.dart';
import 'package:notes_app/pages/note_page.dart';
import 'package:notes_app/pages/notes_page.dart';
import 'package:notes_app/pages/settings_page.dart';

final notesTheme = ThemeData(colorSchemeSeed: Colors.amber);

/// The app's routes: a note's id is the argument of `/note` and `/edit`
/// (none for a new note).
Route<Object?>? onGenerateRoute(RouteSettings settings) {
  final page = switch (settings.name) {
    '/' => const NotesPage(),
    '/note' => NotePage(id: settings.arguments! as String),
    '/edit' => EditPage(id: settings.arguments as String?),
    '/settings' => const SettingsPage(),
    _ => null,
  };
  if (page == null) return null;
  return MaterialPageRoute<Object?>(
    settings: settings,
    // A new note opens as a dialog over the list.
    fullscreenDialog: settings.name == '/edit' && settings.arguments == null,
    builder: (_) => page,
  );
}
