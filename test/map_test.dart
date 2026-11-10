import 'package:contact_sheet/src/map.dart';
import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/sheet.dart';
import 'package:test/test.dart';

void main() {
  final m = Messages.of('en');

  test('sheet.json: an edge written twice is keyed apart, a page\'s '
      'dependencies are there in full, a state\'s params and tags', () {
    final sheet = Sheet.parse('''
dependencies:
  - {name: Auth, target: authProvider, source: lib/auth.dart}
pages:
  - id: home
    label: Home
    dependencies: [Auth]
    path: /items/:id
    params: {id: i1}
    states:
      - {name: s, preview: lib/home.dart#home, params: {id: i2}}
  - {id: cart, label: Cart, states: [{name: s, preview: lib/cart.dart#cart}]}
edges:
  - {from: home, to: cart, trigger: text:Cart}
  - {from: home, to: cart, trigger: text:Cart}
''', m);
    final json = SheetMap(sheet, shots: const {}, m: m).json(app: 'app');
    final edges = (json['edges']! as List).cast<Map<String, Object?>>();
    expect(edges.map((e) => e['key']), [
      'home>cart text:Cart push',
      'home>cart text:Cart push #2',
    ]);
    final home = (json['pages']! as List).first as Map<String, Object?>;
    expect(home['dependencies'], [
      {'name': 'Auth', 'target': 'authProvider', 'source': 'lib/auth.dart'},
    ]);
    expect(home['params'], {'id': 'i1'});
    final state = (home['states']! as List).single as Map<String, Object?>;
    expect(state['params'], {'id': 'i2'});
    expect(state['tags'], isEmpty);
  });

  test('a tab named in the code only is its page\'s name on its branch', () {
    final sheet = Sheet.parse('''
pages:
  - {id: feed, label: Feed, states: [{name: s, preview: lib/feed.dart#feed}]}
  - {id: me, label: My page, states: [{name: s, preview: lib/me.dart#me}]}
tabs:
  - pages:
      - {page: feed, trigger: text:Feed}
      - {page: me, trigger: key:tab_me}
''', m);
    final map = SheetMap(sheet, shots: const {}, m: m);
    expect(map.treeLabel(map.tree.link['me']!), 'My page');
  });
}
