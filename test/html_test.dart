// index.html as a browser runs it: the examples' sheets exported, and each
// view opened in headless Chrome. Its JavaScript is not run anywhere else.
// Without Chrome on the machine, skipped.
import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/src/export.dart' show SheetExport;
import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/repo.dart';
import 'package:contact_sheet/src/route.dart';
import 'package:contact_sheet/src/sheet.dart';
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
/// (nothing shot): what the HTML draws is the sheet. In [locale]'s words,
/// as `--locale` has it, into a folder of its own.
Future<(Sheet, String)> _export(
  String example,
  Directory dir, {
  String? locale,
}) async {
  final app = Directory(
    p.join(dir.path, locale == null ? example : '${example}_$locale'),
  )..createSync();
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
    locale: locale,
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

({String dom, List<String> errors}) _openOnce(
  String html,
  String hash, {
  List<String> flags = const [],
}) {
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
      ...flags,
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

/// What [probe] (a JavaScript expression of JSON's values) gives on [html]
/// opened at [hash], once the page has drawn itself: run by a script added
/// to a copy of it, next to it. With [width], the page in an iframe that
/// wide (headless Chrome's window is 500px at the least), as on a phone.
/// [flags] are Chrome's. [acts], scripts run one after the other before it,
/// each a while after the one before (a step in the history taking its
/// time). Null when the page gave nothing.
Object? _probe(
  String html,
  String hash,
  String probe, {
  int? width,
  List<String> flags = const [],
  List<String> acts = const [],
}) {
  final dir = p.dirname(html);
  final done = 2000 + 500 * acts.length;
  final page = File(p.join(dir, 'probe.html'))
    ..writeAsStringSync(
      File(html).readAsStringSync().replaceFirst(
        '</body>',
        '<script>${[for (final (i, act) in acts.indexed) 'setTimeout(() => { $act; }, ${1500 + 500 * i});'].join()}'
            'setTimeout(() => { const said = JSON.stringify($probe);'
            ' if (parent !== window) parent.postMessage(said, "*");'
            ' else document.body.dataset.probe = said; }, $done);</script>'
            '</body>',
      ),
    );
  var open = page.path;
  if (width != null) {
    open = p.join(dir, 'phone.html');
    File(open).writeAsStringSync(
      '<!doctype html><body style="margin:0">'
      '<iframe src="probe.html$hash" width="$width" height="844" '
      'style="border:0"></iframe><script>addEventListener("message", '
      '(e) => { document.body.dataset.probe = e.data; });</script></body>',
    );
  }
  for (var i = 0; i < 3; i++) {
    final (:dom, errors: _) = _openOnce(
      open,
      width == null ? hash : '',
      flags: flags,
    );
    final said = RegExp(r'data-probe="([^"]*)"').firstMatch(dom)?[1];
    if (said != null) {
      return jsonDecode(
        said
            .replaceAll('&quot;', '"')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&#39;', "'")
            .replaceAll('&amp;', '&'),
      );
    }
  }
  return null;
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
    // Its transitions as sentences, whatever is shown on the pages.
    expect(design, contains('<ul class="says">'));
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
    expect(none, contains('data-level="flow"'));
    final dev = _open(shopHtml, '?dev&show=actions#map/home', drawn: drawn).dom;
    expect(dev, isNot(contains('<body class="plain"')));
    expect(dev, contains('data-level="actions"'));
    // Named, its button pressed.
    expect(
      design,
      matches(RegExp(r'data-note="tag:Design" aria-pressed="true"')),
    );
    expect(design, matches(RegExp(r'data-note="memo" aria-pressed="false"')));
    // Each button with how many pages have it: every page has a design,
    // only home a memo.
    expect(
      design,
      matches(RegExp(r'data-note="tag:Design"[^>]*>Design <small>7</small>')),
    );
    expect(
      design,
      matches(RegExp(r'data-note="memo"[^>]*>Memo <small>1</small>')),
    );
  }, skip: _skip);

  test(
    'with values chosen, the map shows what the Dart router says the app '
    'shows, and a route starts with them',
    () {
      String held(Map<String, String> values) => [
        for (final MapEntry(:key, :value) in values.entries)
          'if=${Uri.encodeQueryComponent('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}')}',
      ].join('&');
      for (final (sheet, html, values) in [
        (shop, shopHtml, const {'Login': 'Guest'}),
        (shop, shopHtml, const {'Login': 'Signed in', 'Cart': 'Empty'}),
        (trips, tripsHtml, const {'Login': 'Guest'}),
        (trips, tripsHtml, const {'Login': 'Guest', 'Language': 'Français'}),
      ]) {
        final (:dom, :errors) = _open(html, '?${held(values)}#map');
        expect(errors, isEmpty, reason: '$values');
        final shown =
            Router(
              sheet.router.pages,
              sheet.router.edges,
              conditions: sheet.router.conditions,
              tabBars: sheet.router.tabBars,
              held: values,
            ).shown([
              for (final e in sheet.entries)
                (to: e.to, then: e.then, guard: e.guard, tab: e.tab),
            ]);
        final classes = {
          for (final m in RegExp(
            r'<div class="(node[^"]*)" data-id="([^"]+)"',
          ).allMatches(dom))
            m[2]!: m[1]!.split(' '),
        };
        expect(classes.keys, containsAll(sheet.pages.map((p) => p.id)));
        for (final page in sheet.pages) {
          expect(
            classes[page.id]!.contains('held-out'),
            !shown.states.containsKey(page.id),
            reason: '${page.id} under $values',
          );
        }
        // Each page shown in the first state the app shows it in, named
        // under it when that is not its first.
        for (final MapEntry(key: page, value: names) in shown.states.entries) {
          final first = sheet.pageOf(page)!.states.first.name;
          final small = first == names.first ? '' : names.first;
          expect(
            dom,
            matches(
              RegExp(
                'data-id="${RegExp.escape(page)}"[^>]*>.*?'
                '<small>${RegExp.escape(small)}</small>',
                dotAll: true,
              ),
            ),
            reason: '$page under $values',
          );
        }
        // Some page is gone, and some is not.
        expect(shown.states, isNotEmpty, reason: '$values');
        expect(shown.states.length, lessThan(sheet.pages.length));
        // Each value chosen, in its choice.
        for (final MapEntry(:key, :value) in values.entries) {
          final c = sheet.conditions.indexWhere((c) => c.name == key);
          final k = sheet.conditions[c].values.indexOf(value);
          expect(
            dom,
            matches(
              RegExp(
                'data-held="$c"[^>]*>.*?<option value="$k" selected',
                dotAll: true,
              ),
            ),
          );
        }
      }
      // Home to checkout: as a guest, through logging in; signed in, not.
      for (final (values, steps) in [
        (const {'Login': 'Guest'}, 3),
        (const {'Login': 'Signed in'}, 2),
      ]) {
        final (:dom, :errors) = _open(
          shopHtml,
          '?${held(values)}#route/home/checkout',
          drawn: (dom) => dom.contains('<div id="route" class="on">'),
        );
        expect(errors, isEmpty);
        expect(_routeSteps(dom), hasLength(steps), reason: '$values');
      }
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'every arrow and label on the map, as the browser draws them; the map '
    'opens with its arrows',
    () {
      const probe = '''(() => {
        const under = document.querySelector('#under');
        const W = +under.getAttribute('width'), H = +under.getAttribute('height');
        const off = (b) => b.x < -1 || b.y < -1 || b.x + b.width > W + 1 || b.y + b.height > H + 1;
        const labels = [...document.querySelectorAll('#over g > rect')].map((r) => r.getBBox()).filter((b) => b.width > 0);
        return {
          edges: document.querySelectorAll('#under path.edge').length,
          edgesOff: [...document.querySelectorAll('#under path.edge')].filter((p) => off(p.getBBox())).map((p) => p.dataset.i),
          labels: labels.length,
          labelsOff: labels.filter(off).length,
          level: document.querySelector('#map-view').dataset.level,
        };
      })()''';
      for (final html in [shopHtml, tripsHtml]) {
        final got = _probe(html, '?show=actions#map', probe)! as Map;
        expect(got['edges'], greaterThan(0), reason: html);
        expect(got['edgesOff'], isEmpty, reason: html);
        expect(got['labels'], greaterThan(0), reason: html);
        expect(got['labelsOff'], 0, reason: html);
        expect(got['level'], 'actions');
        // Nothing in the address: with the arrows.
        expect((_probe(html, '#map', probe)! as Map)['level'], 'flow');
      }
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'a step back keeps what is chosen, and the address says it; details '
    'closed leave the history as it was; links and labels are reached from '
    'the keyboard',
    () {
      const state = '''({
        search: location.search,
        hash: location.hash,
        level: document.querySelector('#map-view').dataset.level,
        length: history.length,
        details: document.querySelector('#detail').classList.contains('on'),
        view: document.body.dataset.view,
      })''';
      final back =
          _probe(
                shopHtml,
                '#map',
                state,
                acts: [
                  "location.hash = '#tree'",
                  "document.querySelector('#levels [data-level=pages]').click()",
                  'history.back()',
                ],
              )!
              as Map;
      expect(back['hash'], '#map', reason: '$back');
      expect(back['search'], '?show=pages', reason: '$back');
      expect(back['level'], 'pages');

      final closed =
          _probe(
                shopHtml,
                '#map',
                state,
                acts: [
                  "location.hash = '#map/home'",
                  "location.hash = '#page/home'",
                  "document.querySelector('#close').click()",
                ],
              )!
              as Map;
      expect(closed['details'], isFalse, reason: '$closed');
      expect(closed['hash'], '#map/home', reason: '$closed');
      // Back where it was opened from: a step back from there goes on to
      // what was before it, not to it again.
      final before =
          _probe(
                shopHtml,
                '#map',
                state,
                acts: [
                  "location.hash = '#map/home'",
                  "location.hash = '#page/home'",
                  "document.querySelector('#close').click()",
                  'history.back()',
                ],
              )!
              as Map;
      expect(before['hash'], '#map', reason: '$before');

      final keys =
          _probe(shopHtml, '#map/home', '''({
        links: [...document.querySelectorAll('a[data-go]')].every((a) => a.getAttribute('href')?.startsWith('#')),
        some: document.querySelectorAll('a[data-go]').length,
        labels: [...document.querySelectorAll('#over g.lbl')].every((g) => g.getAttribute('tabindex') === '0'),
      })''')!
              as Map;
      expect(keys['some'], greaterThan(0));
      expect(keys['links'], isTrue);
      expect(keys['labels'], isTrue);

      // On a phone, the route under the map's tools, which stay to be
      // tapped.
      final phone =
          _probe(shopHtml, '#route/home/cart', '''(() => {
        const r = document.querySelector('#route').getBoundingClientRect();
        const t = document.querySelector('.tools').getBoundingClientRect();
        return { routeTop: r.top, toolsBottom: t.bottom, shown: r.height > 0 };
      })()''', width: 390)!
              as Map;
      expect(phone['shown'], isTrue);
      expect(
        phone['routeTop']! as num,
        greaterThanOrEqualTo(phone['toolsBottom']! as num),
      );
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'dark as the browser is set; on a phone, one column, nothing wider '
    'than it',
    () {
      final dark = _probe(
        shopHtml,
        '#map',
        'getComputedStyle(document.body).backgroundColor',
        flags: ['--force-dark-mode', '--blink-settings=preferredColorScheme=0'],
      ) as String?;
      expect(dark, 'rgb(21, 23, 26)');
      // Light, whatever the machine is set to.
      final light = _probe(
        shopHtml,
        '#map',
        'getComputedStyle(document.body).backgroundColor',
        flags: ['--blink-settings=preferredColorScheme=1'],
      ) as String?;
      expect(light, 'rgb(246, 247, 249)');
      for (final html in [shopHtml, tripsHtml]) {
        for (final hash in ['#map/home', '#list', '#table', '#tree']) {
          final phone =
              _probe(
                    html,
                    hash.replaceFirst(
                      'home',
                      html == shopHtml ? 'home' : 'welcome',
                    ),
                    '''({
              phone: matchMedia('(max-width: 640px)').matches,
              wide: document.documentElement.scrollWidth,
              width: innerWidth,
              barOpen: getComputedStyle(document.querySelector('#bar-open')).display,
              card: document.querySelector('#card').getBoundingClientRect().width,
              past: (() => {
                const out = [];
                const walk = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
                for (let t = walk.nextNode(); t && out.length < 5; t = walk.nextNode()) {
                  const r = document.createRange();
                  r.selectNodeContents(t);
                  if ([...r.getClientRects()].some((b) => b.right > innerWidth + 0.5)) {
                    const e = t.parentElement;
                    out.push(e.tagName + '#' + e.id + '.' + e.className + ' ' + t.textContent.slice(0, 40));
                  }
                }
                return out;
              })(),
            })''',
                    width: 390,
                    flags: ['--allow-file-access-from-files'],
                  )!
                  as Map;
          expect(phone['phone'], isTrue, reason: '$html$hash');
          expect(phone['width'], 390, reason: '$html$hash');
          expect(
            phone['wide'],
            lessThanOrEqualTo(390),
            reason: '$html$hash: ${phone['past']}',
          );
          expect(phone['barOpen'], isNot('none'), reason: '$html$hash');
          expect(phone['card'], lessThanOrEqualTo(390), reason: '$html$hash');
        }
      }
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'in Japanese, as --locale says; a variant chosen by the address',
    () async {
      final (_, ja) = await _export('trips_app', dir, locale: 'ja');
      final (:dom, :errors) = _open(ja, '#map');
      expect(errors, isEmpty);
      expect(dom, contains('<html lang="ja"'));
      expect(dom, contains('>地図<'));
      expect(dom, contains('>流れ<'));
      final (notes, notesHtml) = await _export('notes_app', dir);
      for (final (i, variant) in notes.variants.indexed) {
        final hash = '?variant=${Uri.encodeQueryComponent(variant.name)}#map';
        expect(_open(notesHtml, hash).errors, isEmpty, reason: variant.name);
        expect(
          _probe(notesHtml, hash, "document.querySelector('#variant').value"),
          '$i',
          reason: variant.name,
        );
      }
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

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
