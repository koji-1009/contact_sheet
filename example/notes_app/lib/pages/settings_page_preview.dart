import 'package:flutter/widgets.dart';

import 'package:notes_app/pages/settings_page.dart';
import 'package:notes_app/previews/devices.dart';
import 'package:notes_app/previews/fake_notes.dart';

@Devices(group: '設定', wrapper: overNotes)
Widget settingsPage() => const SettingsPage();
