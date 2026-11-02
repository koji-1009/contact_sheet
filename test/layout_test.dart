import 'package:contact_sheet/contact_sheet.dart';
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
}
