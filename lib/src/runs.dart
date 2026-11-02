import 'dart:io';

import 'package:contact_sheet/src/repo.dart';
import 'package:path/path.dart' as p;

/// The runs of shutter's an export made, kept only until their images are
/// copied into the map: then deleted, so the app's own runs (the team's,
/// when it shoots in the app) stay as the team left them. Listed in
/// `contact_sheet/.dart_tool/contact_sheet/runs` meanwhile, so that
/// `contact_sheet prune` finds those an export did not get to delete.
class ExportRuns {
  ExportRuns(this.repo);

  final SheetRepo repo;

  File get _record =>
      File(p.join(repo.sheetDir, '.dart_tool', 'contact_sheet', 'runs'));

  /// The run directories listed: made by an export, and not deleted yet.
  List<String> get listed => _record.existsSync()
      ? [
          for (final line in _record.readAsLinesSync())
            if (line.trim().isNotEmpty) line.trim(),
        ]
      : const [];

  /// Lists [dir], a run an export just made.
  void add(String dir) {
    _record.parent.createSync(recursive: true);
    _record.writeAsStringSync('$dir\n', mode: FileMode.append);
  }

  /// Deletes the runs listed, with the file shutter claims each run's id by
  /// (`.<id>` beside it), and the list: how many runs there were.
  int deleteAll() {
    var deleted = 0;
    for (final dir in listed) {
      final run = Directory(dir);
      final claim = File(p.join(p.dirname(dir), '.${p.basename(dir)}'));
      if (claim.existsSync()) claim.deleteSync();
      if (run.existsSync()) {
        run.deleteSync(recursive: true);
        deleted++;
      }
    }
    if (_record.existsSync()) _record.deleteSync();
    return deleted;
  }
}
