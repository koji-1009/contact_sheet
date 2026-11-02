/// Contact Sheet's command line: the map of every page of a Flutter app,
/// from its widget previews shot with shutter, written as HTML, SVG and
/// JSON. An AI agent drives it, following the playbook `contact_sheet agent`
/// prints (`contact_sheet manual`: the reference).
library;

export 'src/basis.dart' show currentBasis, writeBasis;
export 'src/commands.dart' show ContactSheetRunner, runCli;
export 'src/export.dart' show ExportException, SheetExport, Shoot;
export 'src/lint.dart' show lintSheet;
export 'src/messages.g.dart';
export 'src/process.dart' show ProcessRunner;
export 'src/repo.dart' show SheetRepo;
export 'src/scaffold.dart' show scaffoldSheet;
export 'src/sheet.dart';
