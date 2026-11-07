import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'English', size: phone, wrapper: guest)
Widget settingsEnglish() => startAt('/account/settings');

@Preview(name: '日本語', size: phone, wrapper: japanese)
Widget settingsJapanese() => startAt('/account/settings');

@Preview(name: 'Français', size: phone, wrapper: french)
Widget settingsFrench() => startAt('/account/settings');
