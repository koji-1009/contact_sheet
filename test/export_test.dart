import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/contact_sheet.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:path/path.dart' as p;
import 'package:shutter/shutter.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Plays shutter's `shot` of the files asked, in the app (`home.dart`) or
/// the sheet package (`detail.dart`): the preview `#broken` comes out as an
/// error, one the sheet names in a file shutter finds none in (`#gone`) is
/// left out, and the others are drawn, each into a PNG of its own, in a run
/// directory of its own under [dir].
class _Shutter {
  _Shutter(this.dir, {this.failure, this.failAfter = 0});

  final String dir;
  final ShutterException? failure;

  /// How many shots succeed before [failure].
  final int failAfter;
  final asked = <(String, ShotSubject, ShotPlatform)>[];

  Future<ShotRun> shot(
    String projectDir,
    ShotSubject subject, {
    ShotPlatform platform = ShotPlatform.android,
    void Function(ShotProgress event)? onProgress,
  }) async {
    asked.add((projectDir, subject, platform));
    // Fails on the shot it is told to, after the ones before it.
    if (failure case final failure? when asked.length > failAfter) {
      throw failure;
    }
    onProgress?.call(const RenderStarted(1));
    // As shutter claims a run's id: `.<id>` beside it.
    File(p.join(dir, '.run${asked.length}')).createSync();
    final run = Directory(p.join(dir, 'run${asked.length}'))..createSync();
    final previews = [
      (file: 'lib/preview/home.dart', symbol: 'home', index: 0),
      (file: 'lib/preview/home.dart', symbol: 'home', index: 1),
      (file: 'lib/preview/detail.dart', symbol: 'detail', index: 0),
      (file: 'lib/preview/detail.dart', symbol: 'broken', index: 0),
    ];
    final files = (subject as PreviewFiles).files;
    final shots = <ShotResult>[];
    for (final (i, preview) in previews.indexed) {
      if (!files.contains(preview.file)) continue;
      final id = shotIdOf(
        SheetState(
          name: '',
          file: preview.file,
          symbol: preview.symbol,
          index: preview.index,
        ),
      );
      final broken = preview.symbol == 'broken';
      final png = File(p.join(run.path, '$id.png'))
        ..writeAsBytesSync([i, 1, 2]);
      shots.add(
        ShotResult(
          id: id,
          status: broken ? ShotStatus.error : ShotStatus.ok,
          name: preview.symbol,
          file: preview.file,
          line: 1,
          size: const LogicalSize(390, 844),
          png: broken ? null : png.path,
          error: broken ? 'Overflow by 12 pixels' : null,
          at: broken ? 'lib/detail_page.dart:20:5' : null,
        ),
      );
    }
    return ShotRun(id: 'run', dir: run.path, shots: shots);
  }
}

/// git as it is; no flutter on the machine.
class _NoFlutter extends Tools {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (executable == 'flutter') {
      throw const ProcessException('flutter', [], 'No such file or directory');
    }
    return await super.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  }
}

const _sheet = '''
conditions:
  - {name: Login, values: [Guest, Member], source: lib/auth.dart}
pages:
  - id: home
    label: ホーム
    source: lib/home.dart
    memo: The product list.
    links: [{label: Spec, url: 'https://example.com/spec'}]
    states:
      - {name: Guest, preview: lib/preview/home.dart#home, if: {Login: Guest}}
      - {name: Member, preview: lib/preview/home.dart#home@1, if: {Login: Member}}
  - id: detail
    label: 詳細
    source: lib/detail.dart
    states:
      - {name: Standard, preview: contact_sheet/lib/preview/detail.dart#detail}
      - {name: Broken, preview: contact_sheet/lib/preview/detail.dart#broken}
      - {name: Gone, preview: contact_sheet/lib/preview/detail.dart#gone, data: true}
edges:
  - {from: home, to: detail, trigger: key:p1, when: Guest}
  - {from: detail, to: home, trigger: back, kind: pop}
  - {from: detail, to: home, trigger: text:Delete, kind: pop}
  - {from: home, to: detail, trigger: text:Buy, then: {Member: Standard}, kind: redirect}
  - {from: detail, to: home, trigger: key:done, set: {Login: Member}, kind: go}
entries:
  - {to: detail, via: /products/:id}
''';

void main() {
  late Directory app;
  late SheetRepo repo;
  late Directory shots;
  setUp(() {
    app = Directory.systemTemp.createTempSync('export_');
    shots = Directory(p.join(app.path, 'shots'))..createSync();
    File(p.join(app.path, 'pubspec.yaml')).writeAsStringSync('name: shop\n');
    repo = SheetRepo(app.path);
    scaffoldSheet(repo);
    repo.sheetFile.writeAsStringSync(_sheet);
    // The preview files the sheet names, in the app and the sheet package.
    for (final file in [
      'lib/preview/home.dart',
      'contact_sheet/lib/preview/detail.dart',
    ]) {
      File(p.join(app.path, file))
        ..createSync(recursive: true)
        ..writeAsStringSync('// previews\n');
    }
  });
  tearDown(() => app.deleteSync(recursive: true));

  test('a shot id is shutter\'s, from the preview\'s file, function and '
      'annotation', () {
    // As shutter 1.3.0 named the example's shots.
    expect(
      shotIdOf(
        SheetState(name: '', file: 'lib/preview/home.dart', symbol: 'home'),
      ),
      'f9a3544cd4c627e5.0',
    );
    expect(
      shotIdOf(
        SheetState(
          name: '',
          file: 'lib/preview/home.dart',
          symbol: 'home',
          index: 1,
        ),
      ),
      '36e1185182ead692.0',
    );
  });

  test('shutter shoots the previews the sheet names, as iOS; the map is '
      'written as HTML, SVG and JSON', () async {
    final tools = Tools();
    final shutter = _Shutter(shots.path);
    final lines = <String>[];
    final (dir: out, :missing) = await SheetExport(
      repo,
      runner: tools,
      shoot: shutter.shot,
      m: Messages.of('en'),
      log: lines.add,
    ).run(p.join(app.path, 'share'));
    expect(out, p.join(app.path, 'share', 'shop_contact_sheet'));
    // Broken and Gone.
    expect(missing, 2);
    // The app's previews in the app, the sheet package's in it.
    expect(tools.commands, [
      ['flutter', 'pub', 'get', '@${repo.root}'],
      ['flutter', 'pub', 'get', '@${repo.sheetDir}'],
    ]);
    expect(shutter.asked, [
      (
        repo.root,
        const PreviewFiles(['lib/preview/home.dart']),
        ShotPlatform.ios,
      ),
      (
        repo.sheetDir,
        const PreviewFiles(['lib/preview/detail.dart']),
        ShotPlatform.ios,
      ),
    ]);
    // What shutter does, and the states without an image.
    expect(lines, contains('rendering'));
    expect(
      lines,
      contains(
        'Could not shoot 詳細 (Broken): '
        'lib/detail_page.dart:20:5: Overflow by 12 pixels',
      ),
    );
    expect(
      lines,
      contains(
        '詳細 (Gone) has no shot: shutter found no preview '
        'contact_sheet/lib/preview/detail.dart#gone',
      ),
    );

    final data = jsonDecode(
      File(p.join(out, 'sheet.json')).readAsStringSync(),
    ) as Map<String, Object?>;
    expect(data['schemaVersion'], 1);
    expect(data['app'], 'shop');
    expect(data.containsKey('basis'), isFalse);
    final pages = (data['pages']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(pages.map((p) => p['id']), ['home', 'detail']);
    expect(pages.first['memo'], 'The product list.');
    final states = (pages.last['states']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(states.map((s) => s['image']), [
      // Named apart from the app's, whose ids may be alike.
      'images/sheet-${shotIdOf(SheetState(name: '', file: 'contact_sheet/lib/preview/detail.dart', symbol: 'detail'))}.png',
      null,
      null,
    ]);
    expect(states[1]['error'], 'Overflow by 12 pixels');
    expect(states[2]['error'], isNull);
    final edges = (data['edges']! as List<Object?>)
        .cast<Map<String, Object?>>();
    // A pop's dashed line says it goes back: its label does not.
    expect(edges.map((e) => e['label']), [
      'p1 / Guest',
      'Back',
      'Delete',
      'Buy / redirect',
      'done / go',
    ]);
    expect(edges.first['curve'], hasLength(8));
    // Which transition each is, from one export to the next.
    expect(edges.map((e) => e['key']), [
      'home>detail key:p1 [Guest] push',
      'detail>home back pop',
      'detail>home text:Delete pop',
      'home>detail text:Buy redirect',
      'detail>home key:done go',
    ]);
    // Where each can arrive, from each state it happens in: what `then`
    // says; else the state of the name it leaves; else, as detail has none
    // of home's, its first and the states its data decides.
    expect(edges[3]['then'], {'Member': 'Standard'});
    expect(edges[3]['arrive'], {
      'Guest': ['Standard', 'Gone'],
      'Member': ['Standard'],
    });
    expect(edges[0]['arrive'], {
      'Guest': ['Standard', 'Gone'],
    });
    expect(states.map((s) => s['data']), [false, false, true]);
    // What the app keeps across its pages: home's states are of it, and
    // done, setting it, arrives in the state of its value.
    expect(data['conditions'], [
      {
        'name': 'Login',
        'values': ['Guest', 'Member'],
        'source': 'lib/auth.dart',
      },
    ]);
    expect(
      (pages.first['states']! as List<Object?>).map((s) => (s! as Map)['if']),
      [
        {'Login': 'Guest'},
        {'Login': 'Member'},
      ],
    );
    expect(edges[4]['set'], {'Login': 'Member'});
    expect(edges[4]['if'], <String, Object?>{});
    expect(edges[4]['arrive'], {
      'Standard': ['Member'],
      'Broken': ['Member'],
      'Gone': ['Member'],
    });
    final entries = (data['entries']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(entries.single['key'], 'detail</products/:id');
    expect(entries.single['then'], isNull);
    // For readers outside the code, without what only the code names, nor
    // how it keeps its pages: a redirect tells anyone something.
    expect(edges.map((e) => e['labelPlain']), [
      'Guest',
      'Back',
      'Delete',
      'Buy / redirect',
      null,
    ]);
    expect(edges.map((e) => e['labelCode']), ['p1', null, null, null, 'done']);
    expect(edges.map((e) => e['labelKind']), [null, null, null, null, 'go']);
    // The two arrows from home into detail come in at points of their own.
    List<num> end(Map<String, Object?> e) =>
        (e['curve']! as List<Object?>).cast<num>().sublist(6);
    expect(end(edges[0]), isNot(end(edges[3])));
    // The pages without a section make one island.
    final sections = (data['sections']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(sections.map((s) => s['name']), ['']);

    // The images that were drawn, and nothing else.
    expect(Directory(p.join(out, 'images')).listSync(), hasLength(3));
    final html = File(p.join(out, 'index.html')).readAsStringSync();
    expect(html, contains('<title>shop — Contact Sheet</title>'));
    expect(html, contains('"tabMap":"Map"'));
    // The map's drawing, as map.svg draws it, the code's names for
    // developers only, and never in a tooltip.
    expect(html, contains('<path class="edge" data-i="0"'));
    // What anyone reads, part by part: the state it needs, here.
    expect(
      html,
      contains(
        '<tspan class="dev">p1 / </tspan><tspan class="l-when">Guest</tspan>',
      ),
    );
    // What is done, and a redirect, each a part of its own.
    expect(
      html,
      contains(
        '<tspan class="l-does">Buy</tspan> / <tspan class="l-kind">redirect</tspan>',
      ),
    );
    // An arrow back's label says so, to be hidden with it.
    expect(html, contains('<g class="lbl pop" data-i="1">'));
    expect(html, contains('<title>ホーム → 詳細: Guest</title>'));
    // How the code keeps its pages, for developers too, one ' / ' apart.
    expect(
      html,
      contains(
        '<tspan class="dev">done</tspan><tspan class="dev"> / go</tspan>',
      ),
    );
    expect(html, contains('<title>詳細 → ホーム</title>'));
    final svg = File(p.join(out, 'map.svg')).readAsStringSync();
    expect(svg, startsWith('<svg xmlns="http://www.w3.org/2000/svg"'));
    expect(
      svg,
      contains('href="data:image/png;base64,${base64Encode([0, 1, 2])}"'),
    );
    expect(svg, contains('>ホーム</text>'));
    expect(svg, contains('>/products/:id</text>'));
    // map.svg for anyone: only what anyone reads, an arrow with nothing of
    // that unlabelled; map-dev.svg with what developers read too.
    expect(
      svg,
      contains(
        'text-anchor="middle"><tspan class="l-when">Guest</tspan></text>',
      ),
    );
    expect(svg, isNot(contains('class="dev"')));
    expect(svg, isNot(contains('data-i="4"><rect class="edge-bg"')));
    final dev = File(p.join(out, 'map-dev.svg')).readAsStringSync();
    expect(
      dev,
      contains(
        '<tspan class="dev">p1 / </tspan><tspan class="l-when">Guest</tspan>',
      ),
    );
    expect(dev, contains('<tspan class="dev">done</tspan>'));
    // Light or dark, as what shows it is set.
    expect(svg, contains('@media (prefers-color-scheme: dark)'));

    // The runs it made are gone once their images are in the map, with the
    // files shutter claimed their ids by.
    expect(shots.listSync(), isEmpty);
    expect(
      File(p.join(repo.sheetDir, '.dart_tool', 'contact_sheet', 'runs'))
          .existsSync(),
      isFalse,
    );
  });

  test('what the sheet says cannot end the JSON blocks of index.html, and '
      'reads back as it was', () async {
    const memo = 'See </script><script>alert(1)</script> and <!--<script>';
    repo.sheetFile.writeAsStringSync(
      _sheet.replaceFirst('memo: The product list.', "memo: '$memo'"),
    );
    final (dir: out, missing: _) = await SheetExport(
      repo,
      runner: Tools(),
      shoot: _Shutter(shots.path).shot,
      m: Messages.of('en'),
    ).run();
    final html = File(p.join(out, 'index.html')).readAsStringSync();
    final block = RegExp(
      r'<script id="sheet" type="application/json">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html)![1]!;
    expect(block, isNot(contains('<')));
    final data = jsonDecode(block) as Map<String, Object?>;
    expect(((data['pages']! as List).first as Map)['memo'], memo);
  });

  test('the pages whose files changed since the basis are marked', () async {
    File(p.join(app.path, 'lib', 'home.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('// home\n');
    File(p.join(app.path, 'lib', 'detail.dart')).writeAsStringSync('// d\n');
    git(app.path, ['init', '-q']);
    git(app.path, ['add', '.']);
    git(app.path, ['commit', '-q', '-m', 'first']);
    final tools = Tools();
    writeBasis(repo, (await currentBasis(tools, repo))!);
    File(p.join(app.path, 'lib', 'home.dart')).writeAsStringSync('// new\n');
    // Code the sheet names for no page (a page it does not have yet), and
    // what is not a page's: a preview the sheet names, a file out of lib/.
    File(p.join(app.path, 'lib', 'new_page.dart')).writeAsStringSync('//\n');
    File(p.join(app.path, 'lib', 'preview', 'home.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('//\n');
    File(p.join(app.path, 'notes.txt')).writeAsStringSync('\n');

    final (dir: out, missing: _) = await SheetExport(
      repo,
      runner: tools,
      shoot: _Shutter(shots.path).shot,
      m: Messages.of('en'),
    ).run();
    // By default, with the sheet.
    expect(out, p.join(app.path, 'contact_sheet', 'map'));
    final data = jsonDecode(
      File(p.join(out, 'sheet.json')).readAsStringSync(),
    ) as Map<String, Object?>;
    expect(data['basis'], containsPair('found', true));
    expect(data['basis'], containsPair('unmapped', ['lib/new_page.dart']));
    // Which app it was drawn from: the commit it is at, on its branch.
    final release = data['release']! as Map<String, Object?>;
    expect(release['commit'], (data['basis']! as Map)['commit']);
    expect(release['branch'], isNotNull);
    final pages = (data['pages']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(pages.first['sheetChanged'], ['lib/home.dart']);
    expect(pages.last['sheetChanged'], isEmpty);
  });

  test('each variant is shot: as its platform draws it, and as the Preview '
      'it names among those an annotation gives', () async {
    repo.sheetFile.writeAsStringSync('''
variants:
  - {name: iPhone}
  - {name: Android, platform: android}
  - {name: Desktop, preview: Desktop}
pages:
  - id: home
    label: Home
    states:
      - {name: Guest, preview: lib/preview/home.dart#home}
      - {name: Wide, preview: lib/preview/home.dart#home@0.1}
''');
    // A MultiPreview of two sizes on `home`, as either platform.
    final base = staticIdOf(
      SheetState(name: '', file: 'lib/preview/home.dart', symbol: 'home'),
    );
    final asked = <ShotPlatform>[];
    Future<ShotRun> shoot(
      String dir,
      ShotSubject subject, {
      ShotPlatform platform = ShotPlatform.android,
      void Function(ShotProgress event)? onProgress,
    }) async {
      asked.add(platform);
      final run = Directory(p.join(shots.path, 'run-${platform.name}'))
        ..createSync();
      return ShotRun(
        id: 'run',
        dir: run.path,
        shots: [
          for (final (k, name, size) in const [
            (0, 'Phone', LogicalSize(390, 844)),
            (1, 'Desktop', LogicalSize(1280, 800)),
          ])
            ShotResult(
              id: '$base.$k',
              status: ShotStatus.ok,
              name: name,
              size: size,
              png: (File(
                p.join(run.path, '$base.$k.png'),
              )..writeAsBytesSync([k, platform.index])).path,
            ),
        ],
      );
    }

    final (dir: out, :missing) = await SheetExport(
      repo,
      runner: Tools(),
      shoot: shoot,
      m: Messages.of('en'),
    ).run();
    // Once as each platform the variants are drawn as.
    expect(asked, [ShotPlatform.ios, ShotPlatform.android]);
    expect(missing, 0);
    final data = jsonDecode(
      File(p.join(out, 'sheet.json')).readAsStringSync(),
    ) as Map<String, Object?>;
    expect((data['variants']! as List).map((v) => (v as Map)['name']), [
      'iPhone',
      'Android',
      'Desktop',
    ]);
    final [guest, wide] =
        ((data['pages']! as List).single as Map)['states'] as List<Object?>;
    List<Object?> images(Object? state) => [
      for (final v in (state! as Map)['variants'] as List) (v as Map)['image'],
    ];
    expect(images(guest), [
      'images/$base.0.png',
      'images/android-$base.0.png',
      // The Desktop Preview the annotation gives besides.
      'images/$base.1.png',
    ]);
    expect(
      ((guest! as Map)['variants'] as List)[2],
      containsPair('width', 1280),
    );
    // The second Preview of the MultiPreview, named as shutter ids it.
    expect((wide! as Map)['preview'], 'lib/preview/home.dart#home@0.1');
    expect(images(wide).first, 'images/$base.1.png');
    expect(Directory(p.join(out, 'images')).listSync(), hasLength(4));
    // The HTML can switch between them.
    final html = File(p.join(out, 'index.html')).readAsStringSync();
    expect(html, contains('id="variant-pick"'));
    // Laid out in each: Android as the iPhone, the Desktop's screen at the
    // iPhone's scale, larger, with the map's drawing of its own.
    final maps = jsonDecode(
      RegExp(r'<script id="maps" type="application/json">(.*?)</script>')
          .firstMatch(html)![1]!,
    ) as Map<String, Object?>;
    expect(maps['variants'], [0, 0, 1]);
    final [first, desktop] = maps['drawings']! as List<Object?>;
    expect(first, isNull);
    final at = desktop! as Map<String, Object?>;
    expect((at['pages']! as Map)['home'], {
      'x': isA<num>(),
      'y': isA<num>(),
      'width': 315.1,
      'height': 196.9,
    });
    expect(
      (((at['tree']! as Map)['pages'] as List).single as Map)['width'],
      315.1,
    );
    expect(at['under'], contains('<marker id="arrow-sheet"'));
    expect((data['pages']! as List).single, containsPair('width', 96));
  });

  test('with only some pages, only theirs are shot; the others keep the '
      'images the map has', () async {
    final first = await SheetExport(
      repo,
      runner: Tools(),
      shoot: _Shutter(shots.path).shot,
      m: Messages.of('en'),
    ).run();
    final detail = File(
      p.join(
        first.dir,
        'images',
        'sheet-${shotIdOf(SheetState(name: '', file: 'contact_sheet/lib/preview/detail.dart', symbol: 'detail'))}.png',
      ),
    );
    expect(detail.existsSync(), isTrue);
    final shutter = _Shutter(shots.path);
    final lines = <String>[];
    final again = await SheetExport(
      repo,
      runner: Tools(),
      shoot: shutter.shot,
      m: Messages.of('en'),
      log: lines.add,
    ).run(null, {'home'});
    expect(shutter.asked.map((a) => a.$2), [
      const PreviewFiles(['lib/preview/home.dart']),
    ]);
    expect(lines, contains('Images kept from the map before: 1'));
    expect(detail.existsSync(), isTrue);
    expect(again.missing, 2);
    // What the map before says of a state it could not shoot stays, and one
    // it has nothing of is told as not shot.
    const notShot =
        '詳細 (Gone) has no image: not shot, as --only leaves it out, and the '
        'map before has none';
    expect(
      lines,
      containsAll([
        'Could not shoot 詳細 (Broken): Overflow by 12 pixels',
        notShot,
      ]),
    );
    final data = jsonDecode(
      File(p.join(again.dir, 'sheet.json')).readAsStringSync(),
    ) as Map<String, Object?>;
    final states =
        ((data['pages']! as List).last as Map<String, Object?>)['states']!
            as List;
    expect((states[1] as Map)['error'], 'Overflow by 12 pixels');
    await expectLater(
      SheetExport(repo, m: Messages.of('en')).run(null, {'nowhere'}),
      throwsA(isA<ExportException>().having((e) => e.exitCode, 'exitCode', 64)),
    );
  });

  test('with only some pages, the others keep each variant\'s image, one '
      'shot two variants\' too', () async {
    // The Desktop variant names the second Preview, which the second state
    // names too: one shot, a variant's and a state's.
    repo.sheetFile.writeAsStringSync('''
variants:
  - {name: Desktop, preview: Desktop}
  - {name: Phone}
pages:
  - id: a
    label: A
    states: [{name: s, preview: contact_sheet/lib/preview/detail.dart#detail}]
  - id: b
    label: B
    states:
      - {name: s, preview: lib/preview/home.dart#home}
      - {name: wide, preview: lib/preview/home.dart#home@0.1}
''');
    final base = staticIdOf(
      SheetState(name: '', file: 'lib/preview/home.dart', symbol: 'home'),
    );
    Future<ShotRun> shoot(
      String dir,
      ShotSubject subject, {
      ShotPlatform platform = ShotPlatform.android,
      void Function(ShotProgress event)? onProgress,
    }) async {
      final run = Directory(p.join(dir, 'run'))..createSync(recursive: true);
      final files = (subject as PreviewFiles).files;
      return ShotRun(
        id: 'run',
        dir: run.path,
        shots: [
          if (files.contains('lib/preview/home.dart'))
            for (final (k, name) in const [(0, 'Phone'), (1, 'Desktop')])
              ShotResult(
                id: '$base.$k',
                status: ShotStatus.ok,
                name: name,
                size: const LogicalSize(390, 844),
                png: (File(
                  p.join(run.path, '$base.$k.png'),
                )..writeAsBytesSync([k])).path,
              ),
          if (files.contains('lib/preview/detail.dart'))
            ShotResult(
              id: shotIdOf(
                SheetState(
                  name: '',
                  file: 'lib/preview/detail.dart',
                  symbol: 'detail',
                ),
              ),
              status: ShotStatus.ok,
              name: 'detail',
              size: const LogicalSize(390, 844),
              png: (File(
                p.join(run.path, 'detail.png'),
              )..writeAsBytesSync([9])).path,
            ),
        ],
      );
    }

    List<Object?> images(String out) {
      final data = jsonDecode(
        File(p.join(out, 'sheet.json')).readAsStringSync(),
      ) as Map<String, Object?>;
      final b = (data['pages']! as List).last as Map<String, Object?>;
      return [
        for (final s in b['states']! as List)
          for (final v in (s as Map)['variants'] as List) (v as Map)['image'],
      ];
    }

    final all = await SheetExport(
      repo,
      runner: Tools(),
      shoot: shoot,
      m: Messages.of('en'),
    ).run();
    final before = images(all.dir);
    expect(before, everyElement(isNotNull));
    final some = await SheetExport(
      repo,
      runner: Tools(),
      shoot: shoot,
      m: Messages.of('en'),
    ).run(null, {'a'});
    expect(images(some.dir), before);
    // A's detail has no Desktop Preview: missing either way.
    expect(some.missing, all.missing);
  });

  test(
    'a sheet that is wrong, or shutter that cannot shoot, is told',
    () async {
      repo.sheetFile.writeAsStringSync('pages: [{id: a}]');
      final export = SheetExport(
        repo,
        runner: Tools(),
        shoot: _Shutter(shots.path).shot,
        m: Messages.of('en'),
      );
      await expectLater(
        export.run(app.path),
        throwsA(
          isA<ExportException>().having(
            (e) => e.message,
            'message',
            startsWith('contact_sheet/sheet.yaml, pages[0]'),
          ),
        ),
      );
      repo.sheetFile.writeAsStringSync(_sheet);
      final failing = SheetExport(
        repo,
        runner: Tools(),
        shoot: _Shutter(
          shots.path,
          failure: ShutterException.unavailable('no Flutter SDK'),
        ).shot,
        m: Messages.of('en'),
      );
      await expectLater(
        failing.run(app.path),
        throwsA(
          isA<ExportException>().having(
            (e) => e.message,
            'message',
            'shutter could not shoot: no Flutter SDK',
          ),
        ),
      );
    },
  );

  test('a preview file shutter cannot take is told of its states; the rest '
      'are shot', () async {
    repo.sheetFile.writeAsStringSync('''
pages:
  - id: home
    label: Home
    states:
      - {name: Guest, preview: lib/preview/home.dart#home}
      - {name: None, preview: lib/preview/none.dart#none}
      - {name: Gone, preview: lib/preview/gone.dart#gone}
      - {name: Out, preview: test/home.dart#home}
''');
    File(p.join(app.path, 'lib', 'preview', 'none.dart')).writeAsStringSync('');
    final asked = <List<String>>[];
    final shutter = _Shutter(shots.path);
    Future<ShotRun> shoot(
      String dir,
      ShotSubject subject, {
      ShotPlatform platform = ShotPlatform.android,
      void Function(ShotProgress event)? onProgress,
    }) {
      final files = (subject as PreviewFiles).files;
      asked.add(files);
      // As shutter stops a run for a file with no @Preview.
      if (files.contains('lib/preview/none.dart')) {
        throw ShutterException.noInput(
          'lib/preview/none.dart has no @Preview.',
        );
      }
      return shutter.shot(dir, subject, platform: platform);
    }

    final lines = <String>[];
    final (dir: out, :missing) = await SheetExport(
      repo,
      runner: Tools(),
      shoot: shoot,
      m: Messages.of('en'),
      log: lines.add,
    ).run();
    // Those it would stop for, never asked; the one it stops for, alone.
    expect(asked, [
      ['lib/preview/home.dart', 'lib/preview/none.dart'],
      ['lib/preview/home.dart'],
      ['lib/preview/none.dart'],
    ]);
    expect(missing, 3);
    const notInLib =
        'test/home.dart is not under lib/, where shutter takes previews from';
    expect(lines.where((l) => l.startsWith('Could not shoot')), [
      'Could not shoot Home (None): lib/preview/none.dart has no @Preview.',
      'Could not shoot Home (Gone): lib/preview/gone.dart does not exist',
      'Could not shoot Home (Out): $notInLib',
    ]);
    final data = jsonDecode(
      File(p.join(out, 'sheet.json')).readAsStringSync(),
    ) as Map<String, Object?>;
    final page = (data['pages']! as List).single as Map<String, Object?>;
    final states = page['states']! as List;
    expect(states.map((s) => (s as Map)['error']), [
      null,
      'lib/preview/none.dart has no @Preview.',
      'lib/preview/gone.dart does not exist',
      notInLib,
    ]);
    expect((states.first as Map)['image'], isNotNull);
  });

  test('two pages whose first states share an image each hold it in the '
      'SVGs', () async {
    repo.sheetFile.writeAsStringSync('''
pages:
  - {id: a, label: A, states: [{name: s, preview: lib/preview/home.dart#home}]}
  - {id: b, label: B, states: [{name: s, preview: lib/preview/home.dart#home}]}
''');
    final (dir: out, :missing) = await SheetExport(
      repo,
      runner: Tools(),
      shoot: _Shutter(shots.path).shot,
      m: Messages.of('en'),
    ).run();
    expect(missing, 0);
    expect(Directory(p.join(out, 'images')).listSync(), hasLength(1));
    for (final name in ['map.svg', 'map-dev.svg']) {
      final svg = File(p.join(out, name)).readAsStringSync();
      expect('data:image/png;base64,'.allMatches(svg), hasLength(2));
    }
  });

  test('no flutter to run is told as unavailable, not as unexpected', () async {
    await expectLater(
      SheetExport(
        repo,
        runner: _NoFlutter(),
        shoot: _Shutter(shots.path).shot,
        m: Messages.of('en'),
      ).run(),
      throwsA(
        isA<ExportException>()
            .having((e) => e.exitCode, 'exitCode', 69)
            .having((e) => e.message, 'message', contains('FLUTTER_ROOT')),
      ),
    );
  });

  test('an export that fails after a shot deletes that run too', () async {
    final shutter = _Shutter(
      shots.path,
      failure: const ShutterException('the sheet package cannot render'),
      failAfter: 1,
    );
    await expectLater(
      SheetExport(
        repo,
        runner: Tools(),
        shoot: shutter.shot,
        m: Messages.of('en'),
      ).run(),
      throwsA(isA<ExportException>()),
    );
    // The app's was shot, then the sheet package's failed.
    expect(shutter.asked, hasLength(2));
    expect(shots.listSync(), isEmpty);
  });
}
