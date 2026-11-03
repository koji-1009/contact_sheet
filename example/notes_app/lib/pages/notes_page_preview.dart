import 'package:flutter/widgets.dart';

import 'package:notes_app/pages/notes_page.dart';
import 'package:notes_app/previews/devices.dart';
import 'package:notes_app/previews/fake_notes.dart';

@Devices(group: 'Notes · Three notes', wrapper: threeNotes)
@Devices(group: 'Notes · Empty', wrapper: noNotes)
@Devices(group: 'Notes · Loading', wrapper: loadingNotes)
Widget notesPage() => const NotesPage();
