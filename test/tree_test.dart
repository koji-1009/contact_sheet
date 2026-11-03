import 'package:contact_sheet/contact_sheet.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:test/test.dart';

/// A page [id], with one state.
String _page(String id) =>
    '{id: $id, label: $id, states: [{name: s, preview: lib/$id.dart#$id}]}';

void main() {
  final m = Messages.of('en');

  test('each page is under the page the fewest steps from the start first '
      'reach it from; a page nothing reaches roots a tree of its own', () {
    final sheet = Sheet.parse('''
pages:
  - ${_page('home')}
  - ${_page('list')}
  - ${_page('detail')}
  - ${_page('login')}
  - ${_page('deep')}
edges:
  - {from: home, to: list, trigger: text:List}
  - {from: list, to: detail, trigger: text:Open}
  - {from: home, to: detail, trigger: text:Featured}
  - {from: detail, to: home, trigger: back, kind: pop}
  - {from: '*', to: login, trigger: other:Session ends}
  - {from: detail, to: detail, trigger: text:Next}
entries:
  - {to: deep, via: /deep}
''', m);
    final tree = SheetMap(sheet, shots: const {}, m: m).tree;
    // The shortest way from the start wins, not the first written.
    expect(tree.parent, {
      'home': null,
      'list': 'home',
      'detail': 'home',
      // From every page is no branch: nothing else reaches it.
      'login': null,
      'deep': null,
    });
    expect(tree.depth['detail'], 1);
    expect(tree.link['detail']!.edge!.trigger.toString(), 'text:Featured');
    expect(tree.outside, ['login', 'deep']);
    // Top to bottom: a child below its parent, siblings side by side, the
    // trees after the app's to its right.
    final n = tree.nodes;
    expect(n['list']!.top, greaterThan(n['home']!.bottom));
    expect(n['list']!.top, n['detail']!.top);
    expect(n['list']!.right, lessThan(n['detail']!.left));
    expect(n['login']!.left, greaterThan(n['detail']!.right));
    // Each branch ends on top of its page, its words above it.
    expect(tree.lines['detail']!.last.y, n['detail']!.top);
    expect(tree.labels['detail']!.bottom, lessThanOrEqualTo(n['detail']!.top));
  });

  test("a tab bar's tabs are each under the tab the start is in", () {
    final sheet = Sheet.parse('''
pages:
  - ${_page('feed')}
  - ${_page('search')}
  - ${_page('post')}
edges:
  - {from: feed, to: post, trigger: other:Tap a post}
tabs:
  - pages:
      - {page: feed, trigger: text:Feed}
      - {page: search, trigger: text:Search}
''', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    expect(map.tree.parent, {'feed': null, 'search': 'feed', 'post': 'feed'});
    expect(map.tree.link['search']!.tab!.page, 'search');
    expect(map.treeLabel(map.tree.link['search']!), 'Search');
    final json = map.json(app: 'app')['tree']! as Map<String, Object?>;
    final pages = (json['pages']! as List).cast<Map<String, Object?>>();
    expect(pages[1], containsPair('tab', 'search'));
    expect(pages[2], containsPair('edge', 0));
  });
}
