import 'dart:math';

import 'package:contact_sheet/contact_sheet.dart';
import 'package:contact_sheet/src/layout.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:contact_sheet/src/svg.dart';
import 'package:test/test.dart';

/// A page [id] in [section], with one state.
String _page(String id, String section) =>
    '{id: $id, label: $id, section: $section, '
    'states: [{name: s, preview: lib/$id.dart#$id}]}';

void main() {
  final m = Messages.of('en');

  test('each section is an island of its own; the arrows from other '
      'sections into one page that say the same are drawn as one', () {
    final sheet = Sheet.parse('''
pages:
  - ${_page('home', 'Home')}
  - ${_page('a', 'A')}
  - ${_page('a2', 'A')}
  - ${_page('lost', 'A')}
  - ${_page('b', 'B')}
  - ${_page('c', 'C')}
edges:
  - {from: home, to: a, trigger: text:A}
  - {from: a, to: a2, trigger: text:Next}
  - {from: home, to: b, trigger: text:B}
  - {from: home, to: c, trigger: text:C}
  - {from: a2, to: home, trigger: text:Home, kind: go}
  - {from: b, to: home, trigger: text:Home, kind: go}
  - {from: c, to: home, trigger: text:Home, kind: go}
''', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    final layout = map.layout;
    final nodes = layout.nodes;
    // In its island, the flow left to right from where it comes in; a page
    // no arrow in it reaches, under the rest.
    expect(nodes['a2']!.left, greaterThan(nodes['a']!.left));
    expect(nodes['lost']!.top, greaterThan(nodes['a']!.bottom));
    expect(layout.sections.map((s) => s.name), ['Home', 'A', 'B', 'C']);
    // The three "Home" arrows from other sections, as one.
    expect(layout.bundles, hasLength(1));
    final bundle = layout.bundles.single;
    expect(bundle.to, 'home');
    expect(bundle.edges.map((e) => e.from), ['a2', 'b', 'c']);
    for (final edge in bundle.edges) {
      expect(layout.curveOf(edge), isNull);
    }
    final json = map.json(app: 'app');
    expect((json['bundles']! as List).single, containsPair('edges', [4, 5, 6]));
    expect(
      (json['bundles']! as List).single,
      containsPair('label', 'Home / go ×3'),
    );
    expect((json['edges']! as List)[4], containsPair('bundle', 0));
    // map.svg: the bundle's label for anyone, and each page a link into
    // index.html.
    final svg = exportSvg(map, (_) => null, plain: true);
    expect(svg, contains('class="blbl"'));
    expect(svg, contains('><tspan class="l-does">Home</tspan> ×3</text>'));
    expect(svg, contains('<a class="page-link" href="index.html#map/home">'));
  });

  test('an arrow between sections that would run across another island is a '
      'jump: a short arrow out, saying where it goes, and one in', () {
    // Five sections of three pages, the islands in rows: arrows from home
    // into the far ones, and between the first and the last.
    final pages = StringBuffer('pages:\n  - ${_page('home', 'Home')}\n');
    final edges = StringBuffer('edges:\n');
    for (final s in ['a', 'b', 'c', 'd', 'e']) {
      for (var i = 1; i <= 3; i++) {
        pages.writeln('  - ${_page('$s$i', s.toUpperCase())}');
      }
      edges
        ..writeln('  - {from: home, to: ${s}1, trigger: text:$s}')
        ..writeln('  - {from: ${s}1, to: ${s}2, trigger: text:${s}2}')
        ..writeln('  - {from: ${s}2, to: ${s}3, trigger: text:${s}3}');
    }
    edges
      ..writeln('  - {from: e3, to: a3, trigger: text:Far}')
      ..writeln('  - {from: a1, to: e2, trigger: text:Across}');
    final sheet = Sheet.parse('$pages$edges', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    final layout = map.layout;
    final islandOf = {
      for (final p in sheet.pages)
        p.id: layout.sections.firstWhere((s) => s.name == p.section).box,
    };
    expect(layout.jumps, isNotEmpty);
    for (final edge in sheet.edges) {
      final (a, b, c, d) = layout.curveOf(edge)!;
      if (layout.jumps.contains(edge)) {
        // Short, out of its page; in a bundle into the page it goes to,
        // which says where it comes from.
        expect(a.distanceTo(d), MapLayout.jumpLength);
        final bundle = layout.bundleWith(edge)!;
        expect(bundle.to, edge.to);
        if (bundle.edges.length == 1) {
          expect(map.bundleLabel(bundle), endsWith('← ${edge.from}'));
        }
        expect(map.drawnLabel(edge), endsWith('→ ${edge.to}'));
        // Its label after its arrow, off its page.
        final label = map.edgeLabels[edge]!;
        expect(label.left, greaterThanOrEqualTo(d.x));
        expect(label.overlap(layout.nodes[edge.from]!), 0);
        continue;
      }
      // Drawn whole: through where no island's pages are but its own two's.
      final ends = {islandOf[edge.from], islandOf[edge.to]};
      const above =
          MapLayout.islandPadding +
          MapLayout.sectionLabelHeight +
          MapLayout.marksHeight;
      for (var i = 1; i < 32; i++) {
        final p = MapLayout.bezier(a, b, c, d, i / 32);
        for (final s in layout.sections) {
          if (ends.contains(s.box)) continue;
          final pages = Box(
            s.box.left,
            s.box.top + above,
            s.box.width,
            s.box.height - above,
          );
          expect(
            pages.contains(p),
            isFalse,
            reason: '${edge.key} over ${s.name}',
          );
        }
      }
    }
    final json = map.json(app: 'app');
    final far = sheet.edges.indexWhere((e) => e.key == 'e3>a3 text:Far push');
    expect(layout.jumps, contains(sheet.edges[far]));
    expect((json['edges']! as List<Object?>)[far], containsPair('jump', true));
    // Its label says where it goes, for anyone too.
    const said =
        '<tspan class="l-does">Far</tspan><tspan class="l-to"> → a3</tspan>';
    expect(mapOver(map), contains('data-i="$far"'));
    expect(mapOver(map), contains(said));
    expect(mapOver(map, plain: true), contains(said));
  });

  test('a tab\'s first page has its bar under it, its own tab lit', () {
    final sheet = Sheet.parse('''
pages:
  - ${_page('feed', 'Tabs')}
  - ${_page('search', 'Tabs')}
  - ${_page('me', 'Tabs')}
tabs:
  - pages:
      - {page: feed, trigger: text:Feed}
      - {page: search, trigger: text:Search}
      - {page: me, trigger: text:Me}
''', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    final bars = RegExp(r'<g class="tabbar">(.*?)</g>')
        .allMatches(mapUnder(map))
        .map((b) => b[1]!)
        .toList();
    expect(bars, hasLength(3));
    for (final (i, bar) in bars.indexed) {
      final rects = RegExp('<rect[^>]*>').allMatches(bar).toList();
      expect(rects, hasLength(3));
      for (final (j, rect) in rects.indexed) {
        expect(rect[0]!.contains('class="on"'), i == j, reason: 'bar $i');
      }
    }
    // The first pages of one bar's tabs stand in one column.
    final nodes = map.layout.nodes;
    expect(nodes['search']!.left, nodes['feed']!.left);
    expect(nodes['me']!.left, nodes['feed']!.left);
  });

  test('arrows that go back are bundled apart from those that do not, and '
      'their bundle is dashed', () {
    final sheet = Sheet.parse('''
pages:
  - ${_page('home', 'Home')}
  - ${_page('a', 'A')}
  - ${_page('b', 'B')}
  - ${_page('c', 'C')}
  - ${_page('d', 'D')}
edges:
  - {from: home, to: a, trigger: text:A}
  - {from: home, to: b, trigger: text:B}
  - {from: home, to: c, trigger: text:C}
  - {from: a, to: home, trigger: text:Close, kind: pop}
  - {from: b, to: home, trigger: text:Close, kind: pop}
  - {from: c, to: home, trigger: text:Close, kind: pop}
  - {from: d, to: home, trigger: text:Close}
''', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    final bundle = map.layout.bundles.single;
    expect(bundle.edges.map((e) => e.from), ['a', 'b', 'c']);
    expect(
      exportSvg(map, (_) => null, plain: true),
      contains('<g class="bundle pop" data-i="0">'),
    );
  });

  test('the labels stay on the map, at its left too', () {
    // Deep links into pages nothing else leads to: all in the first
    // column, an arrow up it round the left past the page between.
    final sheet = Sheet.parse('''
pages:
  - ${_page('home', '')}
  - ${_page('x', '')}
  - ${_page('y', '')}
  - ${_page('z', '')}
edges:
  - {from: z, to: x, trigger: 'text:View all of the reviews', kind: replace}
entries:
  - {to: x, via: /a-rather-long-link/x}
  - {to: y, via: /y}
  - {to: z, via: /z}
''', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    // The map grows right and down to its labels.
    final (width, height) = map.canvas;
    for (final box in [
      ...map.edgeLabels.values,
      ...map.entryLabels.values,
      ...map.bundleLabels.values,
    ]) {
      expect(box.left, greaterThanOrEqualTo(0));
      expect(box.top, greaterThanOrEqualTo(0));
      expect(box.right, lessThanOrEqualTo(width));
      expect(box.bottom, lessThanOrEqualTo(height));
    }
    expect(width, greaterThan(map.layout.width));
  });

  test('a large app (150 pages in 10 sections, arrows across them): every '
      'arrow on the map, no column taller than it holds, few labels over one '
      'another', () {
    // A tree in each section, an arrow back from half the pages, and one in
    // three to anywhere: denser than an app, as a check of the worst.
    final random = Random(1);
    final b = StringBuffer('pages:\n');
    const n = 150, per = 15;
    for (var i = 0; i < n; i++) {
      b.writeln(
        '  - {id: p$i, label: Page $i, section: S${i ~/ per}, '
        'states: [{name: s, preview: lib/p$i.dart#p}]}',
      );
    }
    b.writeln('edges:');
    for (var i = 1; i < n; i++) {
      final s = i ~/ per;
      final parent = i % per == 0 ? 0 : s * per + random.nextInt(i % per);
      b.writeln('  - {from: p$parent, to: p$i, trigger: "text:Open $i"}');
      if (random.nextDouble() < 0.5) {
        b.writeln('  - {from: p$i, to: p$parent, trigger: back, kind: pop}');
      }
      if (random.nextDouble() < 0.3) {
        final j = random.nextInt(n);
        if (j != i) {
          b.writeln('  - {from: p$i, to: p$j, trigger: "text:Go $j"}');
        }
      }
    }
    final sheet = Sheet.parse('$b', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    final layout = map.layout;
    final (width, height) = map.canvas;
    // Every arrow on the map, all along it.
    for (final edge in sheet.edges) {
      final curve = layout.curveOf(edge);
      if (curve == null) continue;
      final (a, b, c, d) = curve;
      for (var i = 0; i <= 32; i++) {
        final p = MapLayout.bezier(a, b, c, d, i / 32);
        expect(p.x, inInclusiveRange(0, width), reason: edge.key);
        expect(p.y, inInclusiveRange(0, height), reason: edge.key);
      }
    }
    // No column of more pages than it holds, but the row under the rest.
    for (final s in layout.sections) {
      final inColumn = <double, int>{};
      for (final box in layout.nodes.values) {
        if (s.box.contains(box.center)) {
          inColumn[box.left] = (inColumn[box.left] ?? 0) + 1;
        }
      }
      expect(
        inColumn.values,
        everyElement(lessThanOrEqualTo(MapLayout.columnRows + 1)),
      );
    }
    // Few labels over one another, none over a page.
    final labels = [...map.edgeLabels.values, ...map.bundleLabels.values];
    var over = 0;
    for (var i = 0; i < labels.length; i++) {
      for (var j = i + 1; j < labels.length; j++) {
        if (labels[i].overlap(labels[j]) > 0) over++;
      }
    }
    final onPages = labels.where(
      (l) => layout.nodes.values.any((p) => l.overlap(p) > 0),
    );
    // As many as there are now, of 285: no more.
    expect(over, lessThanOrEqualTo(11));
    expect(onPages.length, lessThanOrEqualTo(2));
  });

  test('a label off its arrow has a line to it; one on it, none', () {
    const curve = (
      Point(0, 100),
      Point(50, 100),
      Point(150, 100),
      Point(200, 100),
    );
    // On it: none.
    expect(leaderOf(const Box(80, 92, 40, 17), curve), isEmpty);
    // Above it, past the room of a line: from the label's foot to the arrow.
    expect(
      leaderOf(const Box(80, 60, 40, 17), curve),
      '<path class="leader" d="M100,77 L100,100"/>',
    );
  });

  test('an arrow runs behind no page but its own two', () {
    // A flow of four columns, a second row under it, and arrows past the
    // columns between, forward and back, and from the row under.
    final sheet = Sheet.parse('''
pages:
  - ${_page('home', '')}
  - ${_page('a', '')}
  - ${_page('b', '')}
  - ${_page('c', '')}
  - ${_page('a2', '')}
  - ${_page('b2', '')}
edges:
  - {from: home, to: a, trigger: text:A}
  - {from: a, to: b, trigger: text:B}
  - {from: b, to: c, trigger: text:C}
  - {from: home, to: a2, trigger: text:A2}
  - {from: a2, to: b2, trigger: text:B2}
  - {from: home, to: c, trigger: text:Far}
  - {from: a2, to: c, trigger: text:Up}
  - {from: c, to: home, trigger: text:Home, kind: go}
  - {from: b2, to: home, trigger: text:Back, kind: go}
''', m);
    final layout = SheetMap(sheet, shots: const {}, m: m).layout;
    final nodes = layout.nodes;
    for (final edge in sheet.edges) {
      final (a, b, c, d) = layout.curveOf(edge)!;
      for (var i = 1; i < 64; i++) {
        final p = MapLayout.bezier(a, b, c, d, i / 64);
        for (final MapEntry(key: id, value: box) in nodes.entries) {
          if (id == edge.from || id == edge.to) continue;
          final behind =
              p.x > box.left &&
              p.x < box.right &&
              p.y > box.top &&
              p.y < box.bottom + MapLayout.labelHeight;
          expect(behind, isFalse, reason: '${edge.key} behind $id');
        }
      }
    }
  });
}
