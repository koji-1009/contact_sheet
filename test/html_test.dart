// index.html as a browser runs it: the examples' sheets exported, and each
// view opened in headless Chrome. Its JavaScript is not run anywhere else.
// Without Chrome on the machine, skipped.
import 'dart:io';

import 'package:contact_sheet/contact_sheet.dart';
import 'package:path/path.dart' as p;
import 'package:shutter/shutter.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Chrome, where this machine has it: `CHROME_EXECUTABLE`, macOS's, or one
/// on the PATH.
final String? _chrome = () {
  final given = Platform.environment['CHROME_EXECUTABLE'];
  if (given != null && given.isNotEmpty) return given;
  const mac = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  if (File(mac).existsSync()) return mac;
  for (final name in [
    'google-chrome',
    'google-chrome-stable',
    'chromium',
    'chromium-browser',
  ]) {
    final found = Process.runSync('which', [name]);
    if (found.exitCode == 0) return '${found.stdout}'.trim();
  }
  return null;
}();

/// Skipped without Chrome, but on CI, where Chrome is to be had: failing.
final Object _skip = _chrome != null || Platform.environment['CI'] == 'true'
    ? false
    : 'no Chrome on this machine';

/// [example]'s sheet, exported into a new app of its own without images
/// (nothing shot): what the HTML draws is the sheet.
Future<(Sheet, String)> _export(String example, Directory dir) async {
  final app = Directory(p.join(dir.path, example))..createSync();
  File(p.join(app.path, 'pubspec.yaml')).writeAsStringSync('name: $example\n');
  final repo = SheetRepo(app.path);
  repo.sheetFile
    ..createSync(recursive: true)
    ..writeAsStringSync(
      File('example/$example/contact_sheet/sheet.yaml').readAsStringSync(),
    );
  Future<ShotRun> nothing(
    String dir,
    ShotSubject subject, {
    ShotPlatform platform = ShotPlatform.ios,
    double pixelRatio = 2,
    void Function(ShotProgress event)? onProgress,
  }) async => ShotRun(id: 'run', dir: dir, shots: const []);
  final (dir: out, missing: _) = await SheetExport(
    repo,
    runner: Tools(),
    shoot: nothing,
    m: Messages.of('en'),
  ).run();
  return (
    Sheet.parse(repo.sheetFile.readAsStringSync(), Messages.of('en')),
    p.join(out, 'index.html'),
  );
}

/// [html] opened at [hash]: the page as its script left it (without the
/// scripts, whose words would be found too), once [drawn] holds of it, and
/// what the script threw or logged as an error. Chrome on a busy machine can
/// give the page before the script has drawn it: opened again, three times
/// at most.
({String dom, List<String> errors}) _open(
  String html,
  String hash, {
  bool Function(String dom)? drawn,
}) {
  final ready = drawn ?? (dom) => dom.contains('class="node');
  late ({String dom, List<String> errors}) opened;
  for (var i = 0; i < 3; i++) {
    opened = _openOnce(html, hash);
    if (opened.errors.isNotEmpty || ready(opened.dom)) break;
  }
  return opened;
}

({String dom, List<String> errors}) _openOnce(String html, String hash) {
  final profile = Directory.systemTemp.createTempSync('chrome_');
  try {
    final result = Process.runSync(_chrome!, [
      '--headless',
      '--disable-gpu',
      '--no-sandbox',
      '--no-first-run',
      '--user-data-dir=${profile.path}',
      '--enable-logging=stderr',
      '--v=0',
      '--virtual-time-budget=10000',
      '--window-size=1280,900',
      '--dump-dom',
      '${Uri.file(html)}$hash',
    ]);
    return (
      dom: '${result.stdout}'.replaceAll(
        RegExp(r'<script\b.*?</script>', dotAll: true),
        '',
      ),
      errors: [
        for (final line in '${result.stderr}'.split('\n'))
          if (line.contains('CONSOLE') &&
              (line.contains('Uncaught') || line.contains('Error')))
            line,
      ],
    );
  } finally {
    profile.deleteSync(recursive: true);
  }
}

/// The route the page shows: its steps, each as it reads; null when it says
/// none leads there.
List<String>? _routeSteps(String dom) {
  final box = RegExp(
    r'<div id="route" class="on">(.*?)</div></section>',
    dotAll: true,
  ).firstMatch(dom)![1]!;
  if (box.contains('No transitions lead there.')) return null;
  return [
    for (final li in RegExp(r'<li>(.*?)</li>', dotAll: true).allMatches(box))
      li[1]!.replaceAll(RegExp('<[^>]+>'), ''),
  ];
}

void main() {
  late Directory dir;
  late Sheet shop;
  late String shopHtml;
  late Sheet trips;
  late String tripsHtml;
  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('html_');
    (shop, shopHtml) = await _export('shop_app', dir);
    (trips, tripsHtml) = await _export('trips_app', dir);
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  test(
    'each view opens without an error, every page on the map and the list',
    () {
      for (final (sheet, html) in [(shop, shopHtml), (trips, tripsHtml)]) {
        final first = sheet.pages.first.id;
        for (final hash in [
          '',
          '#map/$first',
          '#tree/$first',
          '#list/$first',
          '#table',
          '#page/$first',
        ]) {
          final (:dom, :errors) = _open(html, hash);
          expect(errors, isEmpty, reason: '$html$hash');
          for (final page in sheet.pages) {
            expect(dom, contains('id="row-${page.id}"'), reason: hash);
            expect(dom, contains('data-id="${page.id}"'), reason: hash);
          }
        }
      }
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('what the address says is shown, and only that; a state chosen shows '
      'its own tags, its page\'s others', () {
    bool drawn(String dom) => dom.contains('id="card-notes"');
    const all = '?with=tag:Spec&with=tag:Design&with=tag:Web';
    final (:dom, :errors) = _open(
      shopHtml,
      '$all#map/home/Signed%20in',
      drawn: drawn,
    );
    expect(errors, isEmpty);
    String cardOf(String dom) => RegExp(
      r'<div id="card-notes">(.*?)</div>',
      dotAll: true,
    ).firstMatch(dom)![1]!;
    // The marks above the page.
    String marksOf(String dom) => RegExp(
      r'data-id="home".*?<div class="marks[^"]*"[^>]*>(.*?)</div>',
      dotAll: true,
    ).firstMatch(dom)![1]!;
    final card = cardOf(dom);
    expect(card, contains('https://example.com/designs/home_signed_in'));
    expect(card, isNot(contains('https://example.com/designs/home"')));
    expect(card, contains('https://example.com/specs/home'));
    expect(card, contains('https://shop.example.com/'));
    // The first state shows the page's.
    final page = _open(shopHtml, '$all#map/home', drawn: drawn).dom;
    expect(cardOf(page), contains('https://example.com/designs/home"'));
    // Only those named, on the card and above the page: no memo, no
    // sentences, no other tag.
    final design = _open(
      shopHtml,
      '?with=tag:Design#map/home',
      drawn: drawn,
    ).dom;
    expect(cardOf(design), contains('https://example.com/designs/home"'));
    expect(cardOf(design), isNot(contains('https://example.com/specs/home')));
    expect(cardOf(design), isNot(contains('class="memo"')));
    expect(cardOf(design), isNot(contains('class="says"')));
    expect(marksOf(design), contains('>Design<'));
    expect(marksOf(design), isNot(contains('Spec')));
    expect(marksOf(design), isNot(contains('ⓘ')));
    // Nothing named: nothing shown, no button pressed.
    final none = _open(shopHtml, '#map/home', drawn: drawn).dom;
    expect(cardOf(none), isEmpty);
    expect(marksOf(none), isEmpty);
    expect(
      none,
      isNot(matches(RegExp(r'data-note="[^"]*" aria-pressed="true"'))),
    );
    expect(
      none,
      matches(RegExp(r'<div id="map-view"[^>]*class="[^"]*no-back')),
    );
    // For developers, and how much the map shows: as the address says too.
    expect(none, contains('<body class="plain"'));
    expect(none, contains('data-level="actions"'));
    final dev = _open(shopHtml, '?dev&show=pages#map/home', drawn: drawn).dom;
    expect(dev, isNot(contains('<body class="plain"')));
    expect(dev, contains('data-level="pages"'));
    // Named, its button pressed.
    expect(
      design,
      matches(RegExp(r'data-note="tag:Design" aria-pressed="true"')),
    );
    expect(design, matches(RegExp(r'data-note="memo" aria-pressed="false"')));
  }, skip: _skip);

  test(
    'the route the page shows is the one the Dart route finds',
    () {
      for (final (from, state, to, values) in [
        ('explore', null, 'voucher', const <String, String>{}),
        ('conversation', null, 'trips', const <String, String>{}),
        ('hotel', null, 'payment', const <String, String>{}),
        ('welcome', null, 'licenses', const <String, String>{}),
        ('language', 'English', 'settings', const {'Language': '日本語'}),
        ('settings', null, 'welcome', const {'Login': 'Signed in'}),
      ]) {
        final hash = [
          '#route',
          from,
          ?state,
          to,
          for (final MapEntry(:key, :value) in values.entries) '$key=$value',
        ].map(Uri.encodeComponent).join('/').replaceFirst('%23', '#');
        final (:dom, :errors) = _open(
          tripsHtml,
          hash,
          drawn: (dom) => dom.contains('<div id="route" class="on">'),
        );
        expect(errors, isEmpty, reason: hash);
        final route = trips.router.route(from, state, to, values);
        final shown = _routeSteps(dom);
        expect(shown?.length, route.steps?.length, reason: hash);
        if (route.steps case final steps?) {
          // Each step leads to the page the Dart route's does.
          for (final (i, step) in steps.indexed) {
            expect(
              shown![i],
              contains(trips.pageOf(step.to.page)!.label),
              reason: '$hash, step $i',
            );
          }
        }
      }
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
