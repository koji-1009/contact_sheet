import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/src/repo.dart';
import 'package:contact_sheet/src/sheet.dart';
import 'package:path/path.dart' as p;

/// Writes an empty `contact_sheet/sheet.yaml`; with [package], the sheet
/// package's skeleton too: a Flutter package that imports the app, for the
/// previews (and fakes) the app does not have, whose shots are kept out of
/// git ([_ignoreShots]). Files that exist are left alone.
///
/// Returns the files written.
List<String> scaffoldSheet(SheetRepo repo, {bool package = false}) {
  final app = repo.appName ?? 'app';
  final sdk = switch (repo.pubspec?['environment']) {
    final Map<Object?, Object?> env when env['sdk'] is String =>
      env['sdk']! as String,
    _ => '^3.13.0',
  };
  final written = <String>[];
  void write(String path, String content) {
    final file = File(pathIn(repo.sheetDir, path));
    if (file.existsSync()) return;
    file
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
    written.add('${SheetState.sheetPackage}/$path');
  }

  write('sheet.yaml', '''
# The transition structure of $app: the screen transitions that actually
# happen in it, found out from what tells how it works, such as its code and
# its specifications: its pages, the @Preview each state of a page is, and the
# transitions.
# `sheet agent` prints how to write it.
pages: []
edges: []
''');
  if (!package) return written;

  write('pubspec.yaml', '''
name: ${app}_sheet
description: The previews Contact Sheet's map of $app needs that the app does not have.
publish_to: none

environment:
  sdk: ${jsonEncode(sdk)}

dependencies:
  flutter:
    sdk: flutter
  # The app, imported as is.
  $app:
    path: ..
  # Add here the app's own dependencies that the fakes and previews use
  # directly (flutter_riverpod, go_router, ...).

dev_dependencies:
  # shutter shoots the previews in flutter test.
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''');
  write('analysis_options.yaml', '''
analyzer:
  exclude:
    - build/**
''');
  write('lib/fakes/states.dart', '''
// The states pages start in: public top-level functions
// `Widget name(Widget child)` that put the app's DI on fakes.
import 'package:flutter/widgets.dart';

Widget standard(Widget child) => child;
''');
  if (_ignoreShots(repo)) written.add('.gitignore');
  return written;
}

/// Keeps shutter's shots (the sheet package's `.dart_tool/`) out of the
/// app's git. Returns whether `.gitignore` changed.
bool _ignoreShots(SheetRepo repo) {
  const ignored = '${SheetState.sheetPackage}/.dart_tool/';
  final gitignore = File(p.join(repo.root, '.gitignore'));
  final text = gitignore.existsSync() ? gitignore.readAsStringSync() : '';
  final lines = text.split('\n').map((l) => l.trim()).toSet();
  // Flutter's own .gitignore has `.dart_tool/`, at any depth.
  if (lines.any(
    const {'.dart_tool', '.dart_tool/', ignored, '/$ignored'}.contains,
  )) {
    return false;
  }
  gitignore.writeAsStringSync(
    '$text${text.isEmpty || text.endsWith('\n') ? '' : '\n'}'
    '\n# Contact Sheet: shutter\'s shots\n'
    '$ignored\n',
  );
  return true;
}
