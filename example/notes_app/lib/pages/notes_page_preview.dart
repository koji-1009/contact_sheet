import 'package:flutter/widgets.dart';

import 'package:notes_app/pages/notes_page.dart';
import 'package:notes_app/previews/devices.dart';
import 'package:notes_app/previews/fake_notes.dart';

@Devices(group: 'メモ一覧 · 3件', wrapper: threeNotes)
@Devices(group: 'メモ一覧 · 空', wrapper: noNotes)
@Devices(group: 'メモ一覧 · 読み込み中', wrapper: loadingNotes)
Widget notesPage() => const NotesPage();
