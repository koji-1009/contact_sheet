import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/src/commands.dart' show runSheet;
import 'package:contact_sheet/src/export.dart' show SheetExport;
import 'package:contact_sheet/src/repo.dart';
import 'package:contact_sheet/src/runs.dart';
import 'package:path/path.dart' as p;
import 'package:shutter/shutter.dart';
import 'package:test/test.dart';

import 'support.dart';

/// git as it is; flutter pub get failing, as pub tells it.
class _PubGetFails extends Tools {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (executable != 'flutter') {
      return await super.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
      );
    }
    return ProcessResult(
      0,
      1,
      'Resolving dependencies...\n',
      'Because shop depends on missing any, version solving failed.\n',
    );
  }
}

void main() {
  late Directory app;
  late List<String> out;
  late List<String> err;
  // shutter, drawing nothing; the pixel ratios it is asked to draw at.
  final ratios = <double>[];
  setUp(() {
    app = Directory.systemTemp.createTempSync('cli_');
    File('${app.path}/pubspec.yaml').writeAsStringSync('name: shop\n');
    out = [];
    err = [];
    ratios.clear();
  });
  tearDown(() => app.deleteSync(recursive: true));

  Future<ShotRun> nothing(
    String dir,
    ShotSubject subject, {
    ShotPlatform platform = ShotPlatform.ios,
    double pixelRatio = 2,
    void Function(ShotProgress event)? onProgress,
  }) async {
    ratios.add(pixelRatio);
    return ShotRun(id: 'run', dir: p.join(dir, 'run'), shots: const []);
  }

  Future<int> cli(List<String> args) => runSheet(
    args,
    out: out.add,
    err: err.add,
    runner: Tools(),
    shoot: nothing,
  );

  test('the usage when asked for, on out; a wrong use said on err, with the '
      'usage, as a usage error', () async {
    expect(await cli([]), 0);
    expect(out.single, contains('Usage: sheet <command> [arguments]'));
    // Where an AI agent starts reading, from the usage.
    expect(out.single, contains('AI agents: run `sheet agent` first'));
    expect(out.single, contains('  manual'));
    expect(await cli(['export', '--help']), 0);
    expect(out.last, contains('sheet export [<app directory>]'));
    expect(out.last, contains('--out=<folder>'));
    expect(err, isEmpty);

    expect(await cli(['draw', app.path]), 64);
    expect(err.first, contains('Could not find a command named "draw"'));
    expect(err.last, contains('Usage: sheet <command> [arguments]'));
    expect(await cli(['init', app.path, app.path]), 64);
    expect(err[err.length - 2], 'Give one app directory at most.');
    // Not an app.
    final empty = Directory(p.join(app.path, 'empty'))..createSync();
    expect(await cli(['init', empty.path]), 66);
    expect(err.last, 'There is no pubspec.yaml in ${empty.path}');
  });

  test('--version prints the version in the pubspec', () async {
    expect(await cli(['--version']), 0);
    expect(out.single, startsWith('contact_sheet '));
    expect(
      out.single,
      endsWith(
        RegExp(
          r'^version: (.+)$',
          multiLine: true,
        ).firstMatch(File('pubspec.yaml').readAsStringSync())![1]!,
      ),
    );
  });

  test('agent prints the playbook, manual the reference, as doc/ has '
      'them', () async {
    expect(await cli(['agent']), 0);
    expect('${out.single}\n', File('doc/agent.md').readAsStringSync());
    expect(await cli(['manual']), 0);
    expect('${out.last}\n', File('doc/manual.md').readAsStringSync());
  });

  test('init writes the sheet, what an export keeps kept out of git; with '
      '--package, the sheet package too', () async {
    expect(await cli(['init', app.path]), 0);
    expect(out.single, 'Written: contact_sheet/sheet.yaml, .gitignore');
    expect(
      File('${app.path}/contact_sheet/pubspec.yaml').existsSync(),
      isFalse,
    );
    expect(
      File('${app.path}/.gitignore').readAsStringSync(),
      contains('contact_sheet/.dart_tool/'),
    );

    expect(await cli(['init', '--package', app.path]), 0);
    expect(
      out.last,
      'Written: contact_sheet/pubspec.yaml, contact_sheet/analysis_options.yaml, '
      'contact_sheet/lib/fakes/states.dart',
    );
    final pubspec = File('${app.path}/contact_sheet/pubspec.yaml')
        .readAsStringSync();
    expect(pubspec, contains('name: shop_sheet'));
    expect(pubspec, contains('  shop:\n    path: ..'));
    expect(pubspec, isNot(contains('contact_sheet:')));
    expect(
      File('${app.path}/.gitignore').readAsStringSync(),
      contains('contact_sheet/.dart_tool/'),
    );
    expect(await cli(['init', '--package', app.path]), 0);
    expect(out.last, 'It is there already: nothing written');
  });

  test('init --package overrides what the app overrides, its paths from the '
      'sheet package', () async {
    File('${app.path}/pubspec.yaml').writeAsStringSync('''
name: shop
dependency_overrides:
  local: {path: packages/local}
  far: {path: /opt/far}
  pinned: 1.2.3
''');
    expect(await cli(['init', '--package', app.path]), 0);
    final pubspec = File('${app.path}/contact_sheet/pubspec.yaml')
        .readAsStringSync();
    expect(pubspec, contains('dependency_overrides:\n'));
    expect(pubspec, contains('  local: {"path":"../packages/local"}\n'));
    expect(pubspec, contains('  far: {"path":"/opt/far"}\n'));
    expect(pubspec, contains('  pinned: "1.2.3"\n'));
  });

  test('export without a sheet says to write one', () async {
    expect(await cli(['export', app.path]), 66);
    expect(err.single, startsWith('There is no contact_sheet/sheet.yaml'));
  });

  test(
    'basis records the app as it is; changed lists what changed since',
    () async {
      await cli(['init', app.path]);
      File('${app.path}/lib/home.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// home\n');
      // Not a repository yet: nothing to record.
      expect(await cli(['basis', app.path]), 78);
      expect(err.last, startsWith('Not a git repository'));
      expect(await cli(['changed', app.path]), 66);
      expect(err.last, startsWith('No basis yet'));

      git(app.path, ['init', '-q']);
      git(app.path, ['add', '.']);
      git(app.path, ['commit', '-q', '-m', 'first']);
      expect(await cli(['basis', app.path]), 0);
      expect(out.last, startsWith('Recorded the app at '));
      expect(File('${app.path}/contact_sheet/basis.json').existsSync(), isTrue);
      expect(await cli(['changed', app.path]), 0);
      expect(out.last, 'Nothing changed since the sheet was written');

      File('${app.path}/lib/home.dart').writeAsStringSync('// changed\n');
      File('${app.path}/lib/new.dart').writeAsStringSync('// new\n');
      // The sheet package's own files are not the app's changes.
      File('${app.path}/contact_sheet/sheet.yaml').writeAsStringSync(
        'pages: [{id: home, label: Home, source: lib/home.dart, '
        'states: [{name: s, preview: lib/home.dart#home}]}]',
      );
      out.clear();
      expect(await cli(['changed', app.path]), 0);
      expect(out, ['lib/home.dart', 'lib/new.dart']);
      // By the pages the sheet names them for.
      out.clear();
      expect(await cli(['changed', '--by-page', app.path]), 0);
      expect(out, [
        'Home (home):',
        '  lib/home.dart',
        'On no page:',
        '  lib/new.dart',
      ]);
    },
  );

  test(
    'basis records what was not committed by its content: changed tells '
    'it once that changes; a basis git does not know, or none, is said',
    () async {
      await cli(['init', app.path]);
      File('${app.path}/lib/home.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// home\n');
      git(app.path, ['init', '-q']);
      git(app.path, ['add', '.']);
      git(app.path, ['commit', '-q', '-m', 'first']);
      // Written from the app as it was: a change not committed, and a file
      // not in git yet.
      File('${app.path}/lib/home.dart').writeAsStringSync('// draft\n');
      File('${app.path}/lib/new.dart').writeAsStringSync('// new\n');
      expect(await cli(['basis', app.path]), 0);
      final basis = File('${app.path}/contact_sheet/basis.json');
      expect((jsonDecode(basis.readAsStringSync()) as Map)['files'], {
        'lib/home.dart': hasLength(40),
        'lib/new.dart': hasLength(40),
      });
      expect(await cli(['changed', app.path]), 0);
      expect(out.last, 'Nothing changed since the sheet was written');
      // Committed as they were: nothing changed still.
      git(app.path, ['add', 'lib']);
      git(app.path, ['commit', '-q', '-m', 'second']);
      expect(await cli(['changed', app.path]), 0);
      expect(out.last, 'Nothing changed since the sheet was written');
      File('${app.path}/lib/new.dart').writeAsStringSync('// newer\n');
      out.clear();
      expect(await cli(['changed', app.path]), 0);
      expect(out, ['lib/new.dart']);

      // A commit git does not have (a history rewritten).
      basis.writeAsStringSync('{"commit": "${'0' * 40}", "files": {}}\n');
      expect(await cli(['changed', app.path]), 65);
      expect(
        err.last,
        'git does not have ${'0' * 40}: what changed since is not known',
      );
      // Not one (a merge conflict in it): no basis.
      basis.writeAsStringSync('<<<<<<< HEAD\n');
      expect(await cli(['changed', app.path]), 66);
      expect(err.last, startsWith('No basis yet'));
    },
  );

  test('export --strict fails when a state has no image; the map is in the '
      'sheet\'s locale or --locale\'s, else English, what the command tells '
      'in English', () async {
    final sheet = File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'pages: [{id: home, label: Home, '
        'states: [{name: s, preview: lib/home.dart#home}]}]',
      );
    expect(await cli(['export', app.path]), 0);
    // What could not be shot is what went wrong: on err.
    expect(err, ['Could not shoot Home (s): lib/home.dart does not exist']);
    expect(out.last, startsWith('Exported: '));
    expect(await cli(['export', '--strict', app.path]), 65);
    expect(err.last, '1 state has no image');
    String lang() => RegExp(r'<html lang="(\w+)">').firstMatch(
      File('${app.path}/contact_sheet/map/index.html').readAsStringSync(),
    )![1]!;
    expect(lang(), 'en');
    expect(await cli(['export', '--locale', 'ja', app.path]), 0);
    expect(lang(), 'ja');
    expect(out.last, startsWith('Exported: '));
    // Without --locale, English again, whatever the machine's language.
    expect(await cli(['export', app.path]), 0);
    expect(lang(), 'en');
    // The sheet's locale; the command in English.
    sheet.writeAsStringSync('locale: ja\n${sheet.readAsStringSync()}');
    expect(await cli(['export', app.path]), 0);
    expect(lang(), 'ja');
    expect(out.last, startsWith('Exported: '));
    expect(await cli(['export', '--locale', 'en', app.path]), 0);
    expect(lang(), 'en');
    expect(await cli(['export', '--strict', app.path]), 65);
    expect(err.last, '1 state has no image');
    // One the map is not drawn in: where it is said.
    sheet.writeAsStringSync(
      sheet.readAsStringSync().replaceFirst('locale: ja', 'locale: fr'),
    );
    expect(await cli(['export', app.path]), 65);
    expect(
      err.last,
      'contact_sheet/sheet.yaml, line 1, sheet.yaml.locale: fr is not a language the '
      'map is drawn in: en, ja',
    );
  });

  test('lint tells each hint with the key that checks it; the hints checked '
      'are not told, a key checked that is no hint is', () async {
    final sheet = File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
pages:
  - {id: home, label: Home, states: [{name: s, preview: lib/home.dart#home}]}
  - {id: lost, label: Lost, states: [{name: s, preview: lib/lost.dart#lost}]}
''');
    expect(await cli(['lint', app.path]), 0);
    expect(out, [
      ('Lost (lost): no arrow leads to it from the first page, and no deep '
          'link opens it'),
      '  looked at, and kept as it is: add "unreachable lost" to checked',
    ]);
    out.clear();
    sheet.writeAsStringSync(
      '${sheet.readAsStringSync()}checked: ["unreachable lost", gone]\n',
    );
    expect(await cli(['lint', app.path]), 0);
    expect(out, [
      'checked names "gone", which is no hint now: take it out of checked',
      'Hints in checked, not told: 1',
    ]);
  });

  test('export --pixel-ratio draws the previews at it; one that is no ratio '
      'is a wrong use', () async {
    File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'pages: [{id: home, label: Home, '
        'states: [{name: s, preview: lib/home.dart#home}]}]',
      );
    File('${app.path}/lib/home.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('// previews\n');
    expect(await cli(['export', app.path]), 0);
    expect(ratios.last, SheetExport.defaultPixelRatio);
    expect(await cli(['export', '--pixel-ratio', '1.5', app.path]), 0);
    expect(ratios.last, 1.5);
    for (final wrong in ['0', '-1', 'two', 'Infinity']) {
      ratios.clear();
      expect(await cli(['export', '--pixel-ratio', wrong, app.path]), 64);
      expect(err.reversed.elementAt(1), 'No pixel ratio: $wrong');
      expect(ratios, isEmpty);
    }
  });

  test('export --images writes the images there; one that cannot be a '
      'folder of the export is a wrong use', () async {
    File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'pages: [{id: home, label: Home, '
        'states: [{name: s, preview: lib/home.dart#home}]}]',
      );
    File('${app.path}/lib/home.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('// previews\n');
    expect(await cli(['export', '--images', 'static/shots', app.path]), 0);
    expect(
      Directory('${app.path}/contact_sheet/map/static/shots').existsSync(),
      isTrue,
    );
    expect(
      Directory('${app.path}/contact_sheet/map/images').existsSync(),
      isFalse,
    );
    for (final wrong in ['../up', '/abs', 'sheet.json', 'Index.html']) {
      ratios.clear();
      err.clear();
      expect(await cli(['export', '--images', wrong, app.path]), 64);
      expect(err.first, startsWith('Not a folder for the images: $wrong ('));
      // A wrong use: the usage after it.
      expect(err.last, contains('Usage: sheet export'));
      expect(ratios, isEmpty);
    }
    // No such page: a wrong use too.
    err.clear();
    expect(await cli(['export', '--only', 'typo', app.path]), 64);
    expect(err.first, contains('typo'));
    expect(err.last, contains('Usage: sheet export'));
    // A folder it cannot write in: said, not unexpected.
    final file = File('${app.path}/taken')..writeAsStringSync('');
    err.clear();
    expect(await cli(['export', '--out', file.path, app.path]), 74);
    expect(err.last, startsWith('Could not read or write '));
  });

  test('agent and manual take no arguments', () async {
    expect(await cli(['agent', 'foo']), 64);
    expect(out, isEmpty);
  });

  test('lint says when it finds nothing, and when only what checked '
      'names', () async {
    final sheet = File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'pages: [{id: a, label: A, states: [{name: s, preview: a.dart#a}]}]\n',
      );
    expect(await cli(['lint', app.path]), 0);
    expect(out, ['Nothing found in the sheet']);
    sheet.writeAsStringSync('''
pages:
  - {id: a, label: A, states: [{name: s, preview: a.dart#a}]}
  - {id: b, label: B, states: [{name: s, preview: b.dart#b}]}
checked: ["unreachable b"]
''');
    out.clear();
    expect(await cli(['lint', app.path]), 0);
    expect(out, ['Nothing found in the sheet but the hints in checked: 1']);
    expect(await cli(['lint', '--fail', app.path]), 0);
  });

  test('lint --fail fails while there is a hint; lint tells a source the app '
      'has no file of', () async {
    File('${app.path}/lib/home.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('// home\n');
    File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
pages:
  - {id: home, label: Home, source: lib/home.dart, states: [{name: s}]}
  - {id: cart, label: Cart, source: lib/cart.dart, states: [{name: s}]}
edges:
  - {from: home, to: cart, trigger: text:Cart}
''');
    expect(await cli(['lint', app.path]), 0);
    expect(await cli(['lint', '--fail', app.path]), 65);
    expect(
      out.last,
      '  looked at, and kept as it is: add "no-file lib/cart.dart" to checked',
    );
  });

  test('flutter pub get that fails is told with what it said; an error no '
      'command expects is said, where it came from with --verbose', () async {
    File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'pages: [{id: home, label: Home, '
        'states: [{name: s, preview: lib/home.dart#home}]}]',
      );
    File('${app.path}/lib/home.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('// previews\n');
    final failing = await runSheet(
      ['export', app.path],
      out: out.add,
      err: err.add,
      runner: _PubGetFails(),
      shoot: nothing,
    );
    expect(failing, 69);
    // All it said, then that it failed.
    expect(err, [
      'Resolving dependencies...',
      'Because shop depends on missing any, version solving failed.',
      'flutter pub get failed (exit code 1)',
    ]);

    Future<ShotRun> broken(
      String dir,
      ShotSubject subject, {
      ShotPlatform platform = ShotPlatform.ios,
      double pixelRatio = 2,
      void Function(ShotProgress event)? onProgress,
    }) => throw StateError('a bug');
    for (final verbose in [false, true]) {
      err.clear();
      final code = await runSheet(
        ['export', if (verbose) '--verbose', app.path],
        out: out.add,
        err: err.add,
        runner: Tools(),
        shoot: broken,
      );
      expect(code, 70);
      expect(err.first, 'Unexpected error: Bad state: a bug');
      // Where: this test, which shutter was.
      expect(err, hasLength(verbose ? 2 : 1));
      if (verbose) expect(err.last, contains('cli_test.dart'));
    }
  });

  test('export runs flutter pub get only where the packages are older than '
      'the pubspec', () async {
    File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'pages: [{id: home, label: Home, '
        'states: [{name: s, preview: lib/home.dart#home}]}]',
      );
    File('${app.path}/lib/home.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('// previews\n');
    final tools = Tools();
    Future<int> export() => runSheet(
      ['export', app.path],
      out: out.add,
      err: err.add,
      runner: tools,
      shoot: nothing,
    );
    expect(await export(), 0);
    expect(tools.commands, [
      ['flutter', 'pub', 'get', '@${p.normalize(p.absolute(app.path))}'],
    ]);
    // Got, after the pubspec last changed: not again.
    final config = File('${app.path}/.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{}');
    final pubspec = File('${app.path}/pubspec.yaml');
    pubspec.setLastModifiedSync(
      config.lastModifiedSync().subtract(const Duration(minutes: 1)),
    );
    tools.commands.clear();
    expect(await export(), 0);
    expect(tools.commands, isEmpty);
    // The pubspec changed since: again.
    pubspec.setLastModifiedSync(
      config.lastModifiedSync().add(const Duration(minutes: 1)),
    );
    expect(await export(), 0);
    expect(tools.commands, hasLength(1));
  });

  test('prune deletes the runs Contact Sheet left: the sheet package\'s, and '
      'in the app only those an export did not get to delete', () async {
    // A run shot to its end: one without a manifest is still being shot.
    Directory run(String dir, String id) {
      final run = Directory('$dir/.dart_tool/shutter/runs/$id')
        ..createSync(recursive: true);
      File('${run.path}/manifest.json').writeAsStringSync('{}');
      return run;
    }

    // The team's own run in the app, which is not Contact Sheet's.
    final team = run(app.path, '20260101T000000Z');
    expect(await cli(['prune', app.path]), 0);
    expect(out.last, 'Deleted shutter\'s runs Contact Sheet left: 0');
    expect(team.existsSync(), isTrue);

    await cli(['init', '--package', app.path]);
    final package = run('${app.path}/contact_sheet', '20260101T000000Z');
    // One an interrupted export made in the app, listed by it.
    final left = run(app.path, '20260102T000000Z');
    File('${app.path}/contact_sheet/.dart_tool/contact_sheet/runs')
      ..createSync(recursive: true)
      ..writeAsStringSync('${left.path}\n');
    expect(await cli(['prune', app.path]), 0);
    expect(out.last, 'Deleted shutter\'s runs Contact Sheet left: 2');
    expect(package.existsSync(), isFalse);
    expect(left.existsSync(), isFalse);
    expect(team.existsSync(), isTrue);

    // A shot cut short: its run has no manifest yet. The team's own run
    // still being shot, there before the export shot, is not Contact
    // Sheet's.
    final runs = '${app.path}/.dart_tool/shutter/runs';
    final teams = Directory('$runs/20260103T000000Z')
      ..createSync(recursive: true);
    ExportRuns(SheetRepo(app.path)).shooting(app.path);
    final half = Directory('$runs/20260104T000000Z')..createSync();
    final claim = File('$runs/.20260104T000000Z')..createSync();
    // An export after it, done, forgets only what it shot itself.
    ExportRuns(SheetRepo(app.path)).deleteAll();
    expect(half.existsSync(), isTrue);
    expect(await cli(['prune', app.path]), 0);
    expect(out.last, 'Deleted shutter\'s runs Contact Sheet left: 1');
    expect(half.existsSync(), isFalse);
    expect(claim.existsSync(), isFalse);
    expect(teams.existsSync(), isTrue);
    expect(team.existsSync(), isTrue);
  });
}
