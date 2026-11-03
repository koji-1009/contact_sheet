import 'package:flutter/widgets.dart';

import 'package:notes_app/pages/edit_page.dart';
import 'package:notes_app/previews/devices.dart';
import 'package:notes_app/previews/fake_notes.dart';

@Devices(group: '編集 · 新規', wrapper: newOverNotes)
Widget newNote() => const EditPage();

@Devices(group: '編集 · 編集', wrapper: overNotes)
Widget editNote() => const EditPage(id: 'n1');
