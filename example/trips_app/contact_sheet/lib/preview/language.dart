import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'English', size: phone, wrapper: guest)
Widget languageEnglish() => startAt('/account/settings/language');

@Preview(name: '日本語', size: phone, wrapper: japanese)
Widget languageJapanese() => startAt('/account/settings/language');

@Preview(name: 'Français', size: phone, wrapper: french)
Widget languageFrench() => startAt('/account/settings/language');
