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
    expect(svg, contains('>Home ×3</text>'));
    expect(svg, contains('<a class="page-link" href="index.html#map/home">'));
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
