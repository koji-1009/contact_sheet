import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:contact_sheet/src/basis.dart';
import 'package:contact_sheet/src/docs.dart';
import 'package:contact_sheet/src/export.dart';
import 'package:contact_sheet/src/lint.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/process.dart';
import 'package:contact_sheet/src/repo.dart';
import 'package:contact_sheet/src/runs.dart';
import 'package:contact_sheet/src/scaffold.dart';
import 'package:contact_sheet/src/version.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:shutter/shutter.dart';
import 'package:stack_trace/stack_trace.dart';

/// Runs `sheet` with [args] and returns its exit code (sysexits).
///
/// [out] gets what it gives (and the usage, when asked for or no command is
/// given), [err] what went wrong (and the usage, after a wrong use), in
/// English, each call one message, which may hold several lines (the
/// usage, the playbook); the map is in the sheet's `locale` (English
/// without one) unless `--locale` says otherwise.
Future<int> runCli(
  List<String> args, {
  required void Function(String line) out,
  required void Function(String line) err,
}) => runSheet(args, out: out, err: err);

/// [runCli], with [runner] running flutter and git and [shoot] shooting the
/// previews (shutter's `shot`).
Future<int> runSheet(
  List<String> args, {
  required void Function(String line) out,
  required void Function(String line) err,
  ProcessRunner runner = const SystemProcessRunner(),
  Shoot shoot = shot,
}) async {
  const m = MessagesEn();
  final cli = ContactSheetRunner(
    m: m,
    out: out,
    err: err,
    processes: runner,
    shoot: shoot,
  );
  try {
    return await cli.run(args) ?? ExitCode.success.code;
  } on UsageException catch (e) {
    err(e.message);
    err(e.usage);
    return ExitCode.usage.code;
  } catch (e, trace) {
    // Something no command expected: said, with where when asked.
    err(m.fatal(e));
    if (args.contains('-v') || args.contains('--verbose')) {
      err('${Trace.from(trace).terse}');
    }
    return ExitCode.software.code;
  }
}

/// The `sheet` command and its subcommands.
class ContactSheetRunner extends CommandRunner<int> {
  ContactSheetRunner({
    required this.m,
    required this.out,
    required this.err,
    required this.processes,
    required this.shoot,
  }) : super('sheet', m.runnerDescription) {
    argParser
      ..addFlag('version', negatable: false, help: m.helpVersion)
      ..addFlag('verbose', abbr: 'v', negatable: false, help: m.helpVerbose);
    for (final command in [
      _TextCommand(m, 'agent', m.descAgent, agentText),
      _TextCommand(m, 'manual', m.descManual, manualText),
      _InitCommand(m),
      _ExportCommand(m),
      _LintCommand(m),
      _BasisCommand(m),
      _ChangedCommand(m),
      _PruneCommand(m),
    ]) {
      addCommand(command);
    }
  }

  /// What the command tells.
  final Messages m;
  final void Function(String line) out;
  final void Function(String line) err;
  final ProcessRunner processes;
  final Shoot shoot;

  @override
  String get usageFooter => m.usageFooter;

  @override
  void printUsage() => out(usage);

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.flag('version')) {
      out('contact_sheet $packageVersion');
      return ExitCode.success.code;
    }
    return await super.runCommand(topLevelResults);
  }
}

/// A command of `sheet`, in [m]'s words, which prints its usage
/// through the runner's [ContactSheetRunner.out].
abstract class _Command extends Command<int> {
  _Command(this.m);

  final Messages m;

  ContactSheetRunner get cli => runner! as ContactSheetRunner;

  @override
  void printUsage() => cli.out(usage);
}

/// A command run on an app: its directory the one argument, the current one
/// by default. A failure it can tell is said on `err`, with its exit code.
abstract class _AppCommand extends _Command {
  _AppCommand(super.m);

  @override
  String get invocation => '${runner!.executableName} $name [<app directory>]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length > 1) usageException(m.tooManyArguments);
    final repo = SheetRepo(rest.isEmpty ? Directory.current.path : rest.single);
    if (!repo.pubspecFile.existsSync()) {
      cli.err(m.notApp(repo.root));
      return ExitCode.noInput.code;
    }
    try {
      return await runOn(repo);
    } on ExportException catch (e) {
      // A wrong use: said as every wrong use is, the usage after it.
      if (e.exitCode == ExitCode.usage.code) usageException(e.message);
      cli.err(e.message);
      return e.exitCode;
    } on ShutterException catch (e) {
      cli.err(e.message);
      return e.exitCode;
    } on FileSystemException catch (e) {
      // A folder not to be written in, a full disk: said as it is.
      cli.err(m.ioFailed(e.path ?? '', e.osError?.message ?? e.message));
      return ExitCode.ioError.code;
    }
  }

  Future<int> runOn(SheetRepo repo);
}

/// A command that prints a document for AI agents (`lib/src/docs.dart`).
class _TextCommand extends _Command {
  _TextCommand(super.m, this.name, this.description, this.text);

  @override
  final String name;

  @override
  final String description;

  final String text;

  // `sheet agent foo` is a wrong use, not the playbook.
  @override
  bool get takesArguments => false;

  @override
  Future<int> run() async {
    // As `doc/` has it: `out` ends the line.
    cli.out(text.trimRight());
    return ExitCode.success.code;
  }
}

class _InitCommand extends _AppCommand {
  _InitCommand(super.m) {
    argParser.addFlag('package', negatable: false, help: m.helpPackage);
  }

  @override
  String get name => 'init';

  @override
  String get description => m.descInit;

  @override
  Future<int> runOn(SheetRepo repo) async {
    final written = scaffoldSheet(repo, package: argResults!.flag('package'));
    cli.out(
      written.isEmpty ? m.initNothing : m.initWritten(written.join(', ')),
    );
    return ExitCode.success.code;
  }
}

class _ExportCommand extends _AppCommand {
  _ExportCommand(super.m) {
    argParser
      ..addOption('out', valueHelp: 'folder', help: m.helpOut)
      ..addMultiOption('only', valueHelp: 'page id', help: m.helpOnly)
      ..addOption(
        'locale',
        valueHelp: 'language',
        allowed: Messages.locales,
        help: m.helpLocale,
      )
      ..addFlag('strict', negatable: false, help: m.helpStrict)
      ..addFlag('svg', negatable: false, help: m.helpSvg)
      ..addOption(
        'pixel-ratio',
        valueHelp: 'ratio',
        defaultsTo: '${SheetExport.defaultPixelRatio}',
        help: m.helpPixelRatio,
      )
      ..addOption(
        'images',
        valueHelp: 'folder',
        defaultsTo: SheetMap.defaultImagesDir,
        help: m.helpImages,
      );
  }

  @override
  String get name => 'export';

  @override
  String get description => m.descExport;

  @override
  Future<int> runOn(SheetRepo repo) async {
    final args = argResults!;
    final locale = args.option('locale');
    final ratio = args.option('pixel-ratio')!;
    final pixelRatio = double.tryParse(ratio);
    if (pixelRatio == null || !(pixelRatio > 0) || !pixelRatio.isFinite) {
      usageException(m.noPixelRatio(ratio));
    }
    final images = args.option('images')!;
    if (!SheetExport.isImagesDir(images)) usageException(m.noImagesDir(images));
    final (:dir, :missing) = await SheetExport(
      repo,
      runner: cli.processes,
      shoot: cli.shoot,
      m: m,
      locale: locale,
      svg: args.flag('svg'),
      pixelRatio: pixelRatio,
      imagesDir: images,
      log: cli.out,
      warn: cli.err,
    ).run(args.option('out'), {...args.multiOption('only')});
    cli.out(m.exportDone(dir));
    if (missing > 0 && args.flag('strict')) {
      cli.err(
        missing == 1 ? m.exportIncompleteOne : m.exportIncomplete(missing),
      );
      return ExitCode.data.code;
    }
    return ExitCode.success.code;
  }
}

class _LintCommand extends _AppCommand {
  _LintCommand(super.m) {
    argParser.addFlag('fail', negatable: false, help: m.helpFail);
  }

  @override
  String get name => 'lint';

  @override
  String get description => m.descLint;

  @override
  Future<int> runOn(SheetRepo repo) async {
    final sheet = SheetExport(repo, m: m).readSheet();
    final (:hints, :checked) = lintReport(sheet, m, exists: repo.hasFile);
    final lines = lintLines(hints, m);
    lines.forEach(cli.out);
    if (lines.isEmpty) {
      cli.out(checked > 0 ? m.lintOnlyChecked(checked) : m.lintNone);
    } else if (checked > 0) {
      cli.out(m.lintChecked(checked));
    }
    return hints.isNotEmpty && argResults!.flag('fail')
        ? ExitCode.data.code
        : ExitCode.success.code;
  }
}

class _BasisCommand extends _AppCommand {
  _BasisCommand(super.m);

  @override
  String get name => 'basis';

  @override
  String get description => m.descBasis;

  @override
  Future<int> runOn(SheetRepo repo) async {
    final now = await currentBasis(cli.processes, repo);
    if (now == null) {
      cli.err(m.basisNoGit);
      return ExitCode.config.code;
    }
    writeBasis(repo, now);
    cli.out(m.basisWritten(now.commit));
    return ExitCode.success.code;
  }
}

class _ChangedCommand extends _AppCommand {
  _ChangedCommand(super.m) {
    argParser.addFlag('by-page', negatable: false, help: m.helpByPage);
  }

  @override
  String get name => 'changed';

  @override
  String get description => m.descChanged;

  @override
  Future<int> runOn(SheetRepo repo) async {
    final basis = readBasis(repo);
    if (basis == null) {
      cli.err(m.changedNoBasis);
      return ExitCode.noInput.code;
    }
    final changed = await changedSince(cli.processes, repo, basis);
    if (changed == null) {
      cli.err(m.changedUnknown(basis.commit));
      return ExitCode.data.code;
    }
    if (changed.isEmpty) cli.out(m.changedNone);
    if (changed.isEmpty || !argResults!.flag('by-page')) {
      changed.forEach(cli.out);
      return ExitCode.success.code;
    }
    // By the pages the sheet names them for; the rest on no page.
    final sheet = SheetExport(repo, m: m).readSheet();
    final onPage = <String>{};
    for (final page in sheet.pages) {
      final files = SheetMap.filesOf(sheet, page);
      final mine = [
        for (final file in changed)
          if (files.contains(file)) file,
      ];
      if (mine.isEmpty) continue;
      onPage.addAll(mine);
      cli.out(m.changedPage(page.label, page.id));
      for (final file in mine) {
        cli.out('  $file');
      }
    }
    final rest = [
      for (final file in changed)
        if (!onPage.contains(file)) file,
    ];
    if (rest.isNotEmpty) {
      cli.out(m.changedNoPage);
      for (final file in rest) {
        cli.out('  $file');
      }
    }
    return ExitCode.success.code;
  }
}

class _PruneCommand extends _AppCommand {
  _PruneCommand(super.m);

  @override
  String get name => 'prune';

  @override
  String get description => m.descPrune;

  @override
  Future<int> runOn(SheetRepo repo) async {
    // The sheet package's runs are all Contact Sheet's; of the app's, only
    // those an export listed and did not get to delete, or left half made
    // (the rest are the team's). Without a sheet package, shutter would
    // take the app's.
    final removed =
        (repo.sheetPubspecFile.existsSync()
            ? prune(repo.sheetDir, keep: 0).removed.length
            : 0) +
        ExportRuns(repo).deleteAll(halfMade: true);
    cli.out(m.pruneDone(removed));
    return ExitCode.success.code;
  }
}
