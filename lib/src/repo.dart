import 'dart:io';

import 'package:contact_sheet/src/sheet.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A Flutter app's repository, and where Contact Sheet keeps its files in
/// it:
///
/// | Path | What | In git |
/// | --- | --- | --- |
/// | `contact_sheet/sheet.yaml` | The sheet. Written by an AI agent or by hand | yes |
/// | `contact_sheet/basis.json` | What the app was when the sheet was written | yes |
/// | `contact_sheet/map/` | The map, written by `sheet export` | as the app's owners choose |
/// | `contact_sheet/pubspec.yaml`, `pubspec.lock`, `lib/` | The sheet package, for the previews the app lacks | yes |
/// | `contact_sheet/.dart_tool/contact_sheet/` | What an export keeps between runs: the WebP made of each shot, when `flutter pub get` last ran, the runs it made | no |
class SheetRepo {
  SheetRepo(String root) : root = p.normalize(p.absolute(root));

  /// The app's directory: where its `pubspec.yaml` is.
  final String root;

  String get sheetDir => p.join(root, SheetState.sheetPackage);

  File get pubspecFile => File(p.join(root, 'pubspec.yaml'));
  File get sheetFile => File(p.join(sheetDir, 'sheet.yaml'));
  File get sheetPubspecFile => File(p.join(sheetDir, 'pubspec.yaml'));
  File get basisFile => File(p.join(sheetDir, 'basis.json'));

  /// Where the map is written by default: with the sheet it is drawn from.
  String get mapDir => p.join(sheetDir, 'map');

  /// The app's pubspec, or null if it has none or it cannot be read.
  late final YamlMap? pubspec = () {
    if (!pubspecFile.existsSync()) return null;
    try {
      final yaml = loadYaml(pubspecFile.readAsStringSync());
      return yaml is YamlMap ? yaml : null;
    } on YamlException {
      return null;
    } on FileSystemException {
      return null;
    }
  }();

  /// The app's package name.
  String? get appName => pubspec?['name'] as String?;

  /// The app's version, as its pubspec gives it.
  String? get appVersion => switch (pubspec?['version']) {
    null => null,
    final v => '$v',
  };

  /// What the app is called in the map: its package name, or its directory.
  String get displayName => appName ?? p.basename(root);

  /// Whether the app has [file], relative to it with `/`, as the sheet
  /// names files.
  bool hasFile(String file) => File(pathIn(root, file)).existsSync();
}

/// [relative], written with `/` (as in the sheet), under [dir], with the
/// platform's separators.
String pathIn(String dir, String relative) =>
    p.joinAll([dir, ...relative.split('/')]);
