import 'dart:io';

import 'package:contact_sheet/contact_sheet.dart';
import 'package:contact_sheet/src/runs.dart';
import 'package:path/path.dart' as p;
import 'package:shutter/shutter.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late Directory app;
  late List<String> out;
  late List<String> err;
  setUp(() {
    app = Directory.systemTemp.createTempSync('cli_');
    File('${app.path}/pubspec.yaml').writeAsStringSync('name: shop\n');
    out = [];
    err = [];
  });
  tearDown(() => app.deleteSync(recursive: true));

  // shutter, drawing nothing; the pixel ratios it is asked to draw at.
  final ratios = <double>[];
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

  Future<int> cli(List<String> args) =>
      runCli(args, out: out.add, err: err.add, runner: Tools(), shoot: nothing);

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

  test('init writes the sheet; with --package, the sheet package too, its '
      'shots kept out of git', () async {
    expect(await cli(['init', app.path]), 0);
    expect(out.single, 'Written: contact_sheet/sheet.yaml');
    expect(
      File('${app.path}/contact_sheet/pubspec.yaml').existsSync(),
      isFalse,
    );
    expect(File('${app.path}/.gitignore').existsSync(), isFalse);

    expect(await cli(['init', '--package', app.path]), 0);
    expect(
      out.last,
      'Written: contact_sheet/pubspec.yaml, contact_sheet/analysis_options.yaml, '
      'contact_sheet/lib/fakes/states.dart, .gitignore',
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
      'contact_sheet/sheet.yaml, sheet.yaml.locale: fr is not a language the '
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

  test('lint tells what the sheet itself shows may be missing', () async {
    File('${app.path}/contact_sheet/sheet.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'pages: [{id: a, label: A, states: [{name: s, preview: a.dart#a}]}, '
        '{id: b, label: B, states: [{name: s, preview: b.dart#b}]}]',
      );
    expect(await cli(['lint', app.path]), 0);
    expect(out, [
      ('B (b): no arrow leads to it from the first page, and no deep link '
          'opens it'),
      '  looked at, and kept as it is: add "unreachable b" to checked',
    ]);
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
    expect(await cli(['prune', app.path]), 0);
    expect(out.last, 'Deleted shutter\'s runs Contact Sheet left: 1');
    expect(half.existsSync(), isFalse);
    expect(claim.existsSync(), isFalse);
    expect(teams.existsSync(), isTrue);
    expect(team.existsSync(), isTrue);
  });
}
