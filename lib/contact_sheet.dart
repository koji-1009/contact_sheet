/// Contact Sheet's command line: the map of every page of a Flutter app,
/// from its widget previews shot with shutter, written as HTML and JSON,
/// and SVG when asked: the `sheet` command. An AI agent drives it, following the playbook
/// `sheet agent` prints (`sheet manual`: the reference).
library;

export 'src/basis.dart' show currentBasis, writeBasis;
export 'src/commands.dart' show ContactSheetRunner, runCli;
export 'src/export.dart' show ExportException, SheetExport, Shoot;
export 'src/lint.dart' show LintHint, lintHints, lintSheet;
export 'src/messages.g.dart';
export 'src/process.dart' show ProcessRunner;
export 'src/repo.dart' show SheetRepo;
export 'src/scaffold.dart' show scaffoldSheet;
export 'src/sheet.dart';
