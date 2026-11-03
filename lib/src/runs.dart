import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/src/repo.dart';
import 'package:path/path.dart' as p;

/// The runs of shutter's an export made, kept only until their images are
/// copied into the map: then deleted, so the app's own runs (the team's,
/// when it shoots in the app) stay as the team left them. Listed in
/// `contact_sheet/.dart_tool/contact_sheet/runs` meanwhile, so that
/// `contact_sheet prune` finds those an export did not get to delete; and,
/// before each is shot, the runs its project had (`shooting`), so that
/// `prune` tells one an interrupted shot left half made from them.
class ExportRuns {
  ExportRuns(this.repo);

  final SheetRepo repo;

  Directory get _dir =>
      Directory(p.join(repo.sheetDir, '.dart_tool', 'contact_sheet'));

  File get _record => File(p.join(_dir.path, 'runs'));
  File get _shooting => File(p.join(_dir.path, 'shooting'));

  /// The run directories listed: made by an export, and not deleted yet.
  List<String> get listed => _record.existsSync()
      ? [
          for (final line in _record.readAsLinesSync())
            if (line.trim().isNotEmpty) line.trim(),
        ]
      : const [];

  /// Lists [dir], a run an export just made.
  void add(String dir) {
    _dir.createSync(recursive: true);
    _record.writeAsStringSync('$dir\n', mode: FileMode.append);
  }

  /// Where shutter keeps the runs of the project at [project].
  static String runsIn(String project) =>
      p.join(project, '.dart_tool', 'shutter', 'runs');

  /// Notes that a run is about to be shot in the project at [project]: the
  /// runs it has now.
  void shooting(String project) {
    final runs = Directory(runsIn(project));
    final before = runs.existsSync()
        ? [
            for (final entity in runs.listSync())
              if (entity is Directory) p.basename(entity.path),
          ]
        : const <String>[];
    _dir.createSync(recursive: true);
    _shooting.writeAsStringSync(
      '${jsonEncode({'runs': runs.path, 'before': before})}\n',
      mode: FileMode.append,
    );
  }

  /// Deletes the runs listed, with the file shutter claims each run's id by
  /// (`.<id>` beside it), and the list: how many runs there were. With
  /// [halfMade], those an interrupted shot left too: a run shutter had not
  /// finished (no manifest yet) that was not there before the export shot
  /// in its project.
  int deleteAll({bool halfMade = false}) {
    var deleted = 0;
    void delete(String dir) {
      final run = Directory(dir);
      final claim = File(p.join(p.dirname(dir), '.${p.basename(dir)}'));
      if (claim.existsSync()) claim.deleteSync();
      if (run.existsSync()) {
        run.deleteSync(recursive: true);
        deleted++;
      }
    }

    listed.forEach(delete);
    if (halfMade && _shooting.existsSync()) {
      for (final line in _shooting.readAsLinesSync()) {
        if (line.trim().isEmpty) continue;
        final Object? entry;
        try {
          entry = jsonDecode(line);
        } on FormatException {
          continue;
        }
        if (entry case {
          'runs': final String runs,
          'before': final List<Object?> before,
        }) {
          if (!Directory(runs).existsSync()) continue;
          for (final entity in Directory(runs).listSync()) {
            if (entity is Directory &&
                !before.contains(p.basename(entity.path)) &&
                // shutter writes it last: a run without it was not finished.
                !File(p.join(entity.path, 'manifest.json')).existsSync()) {
              delete(entity.path);
            }
          }
        }
      }
    }
    if (_record.existsSync()) _record.deleteSync();
    if (_shooting.existsSync()) _shooting.deleteSync();
    return deleted;
  }
}
