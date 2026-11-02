import 'package:flutter/widgets.dart';

import 'package:notes_app/pages/note_page.dart';
import 'package:notes_app/previews/devices.dart';
import 'package:notes_app/previews/fake_notes.dart';

@Devices(group: 'メモ', wrapper: threeNotes)
Widget notePage() => const NotePage(id: 'n1');
