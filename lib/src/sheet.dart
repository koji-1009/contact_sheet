import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/route.dart';
import 'package:yaml/yaml.dart';

/// The transition structure of an app, as its `contact_sheet/sheet.yaml`
/// gives it: its pages, the state each `@Preview` of the sheet package
/// starts a page in, and the transitions between them.
///
/// An AI agent writes it by reading the app's code; nothing in the app is
/// marked. Contact Sheet draws it as the map and does not check it against
/// the app.
class Sheet {
  Sheet({
    required this.pages,
    this.edges = const [],
    this.entries = const [],
    this.conditions = const [],
    this.tabBars = const [],
    this.dependencies = const [],
    this.variants = const [SheetVariant(name: '')],
  });

  /// Reads [yaml], the text of `sheet.yaml`. Throws a [SheetException],
  /// in [m]'s words, saying where it is wrong.
  factory Sheet.parse(String yaml, Messages m) => _Parser(m).sheet(yaml);

  final List<SheetPage> pages;

  /// The transitions between the app's pages.
  final List<SheetEdge> edges;

  /// The deep links into the app's pages.
  final List<SheetEntry> entries;

  /// What the app keeps across its pages, such as being logged in.
  final List<SheetCondition> conditions;

  /// The tab bars whose tabs each keep their own history (its `tabs`).
  final List<SheetTabBar> tabBars;

  /// The tab [page] is the first page of, if any.
  SheetTab? tabOf(String page) => _tabOf[page];

  late final Map<String, SheetTab> _tabOf = {
    for (final bar in tabBars)
      for (final tab in bar.tabs) tab.page: tab,
  };

  /// The bar [tab] is in.
  SheetTabBar barOf(SheetTab tab) =>
      tabBars.firstWhere((b) => b.tabs.contains(tab));

  /// What the pages read that their previews replace with fakes.
  final List<SheetDependency> dependencies;

  /// The ways every state is shot, the first the map's: one, unnamed, when
  /// the sheet names none.
  final List<SheetVariant> variants;

  /// The dependencies [page] names, in its order.
  List<SheetDependency> dependenciesOf(SheetPage page) => [
    for (final name in page.dependencies)
      ...dependencies.where((d) => d.name == name),
  ];

  late final Map<String, SheetPage> _byId = {for (final p in pages) p.id: p};

  /// The page of [id]; null when the sheet has none.
  SheetPage? pageOf(String id) => _byId[id];

  late final Map<SheetEdge, int> _edgeIndex = Map.identity()
    ..addAll({for (final (i, e) in edges.indexed) e: i});

  /// The states of [edge]'s `to` it can arrive in, by each state of its
  /// `from` it happens in, under any values of the conditions it happens
  /// while ([Router.arrivals]): the one its `then` says; else the state of
  /// `to` named as the one it leaves, as what is not changed stays (a full
  /// cart stays full), if the conditions after it allow it; else, not
  /// said, `to`'s first, `data` states and states of the conditions, those
  /// the conditions allow.
  Map<String, List<String>> arrivals(SheetEdge edge) =>
      router.arrivals(_edgeIndex[edge]!);

  /// The routes between its pages, as the app's navigator goes.
  late final Router router = Router(
    [
      for (final p in pages)
        RoutePage(p.id, tabs: p.tabs, [
          for (final s in p.states)
            RouteState(s.name, conditions: s.conditions, data: s.data),
        ]),
    ],
    [
      for (final e in edges)
        RouteEdge(
          from: e.from,
          to: e.to,
          move: RouteMove.of(e.kind.name),
          back: e.trigger?.isBack ?? false,
          under: e.under,
          when: e.when,
          guard: e.guard,
          sets: e.sets,
          then: e.then,
          thenBy: e.thenBy,
          tab: e.tab,
        ),
    ],
    conditions: [for (final c in conditions) RouteCondition(c.name, c.values)],
    tabBars: [
      for (final bar in tabBars)
        RouteTabBar([
          for (final tab in bar.tabs) RouteTab(tab.page, guard: tab.guard),
        ], retapFirst: bar.retapFirst),
    ],
  );

  /// The states of [entry]'s page it can open in: its `then`, or those
  /// nothing says under the values of the conditions it opens while.
  List<String> opening(SheetEntry entry) =>
      router.opening(entry.to, entry.then, entry.guard);
}

/// A tab bar whose tabs each keep their own history: go_router's
/// `StatefulShellRoute`, a `UITabBarController` of navigation controllers.
/// Switching tabs is not written as an edge: the bar does it, from every
/// page in its tabs.
class SheetTabBar {
  SheetTabBar(this.tabs, {this.retapFirst = false, this.source});

  /// Its tabs, in the bar's order.
  final List<SheetTab> tabs;

  /// Whether tapping the tab shown again goes back to its first page
  /// (`retap: first`); else it does nothing (`stay`).
  final bool retapFirst;

  /// Where the app declares it, relative to the app.
  final String? source;
}

/// A tab of a [SheetTabBar]: its first page, what switches to it, and the
/// values of the conditions it can be switched to while.
class SheetTab {
  SheetTab(this.page, this.trigger, {this.guard = const {}});

  final String page;
  final Trigger trigger;
  final Map<String, List<String>> guard;
}

/// What the app keeps across its pages, which a page between may not show:
/// being logged in, what is in the cart.
class SheetCondition {
  SheetCondition(this.name, this.values, {this.source});

  /// How the sheet calls it, such as `ログイン`.
  final String name;

  /// Its values; the first is what the app launches with.
  final List<String> values;

  /// Where the app keeps it, relative to the app.
  final String? source;
}

/// A page of the app: a node on the map.
class SheetPage {
  SheetPage({
    required this.id,
    required this.label,
    required this.states,
    this.section = '',
    this.widget,
    this.source,
    this.path,
    this.route,
    this.memo,
    this.links = const [],
    this.dependencies = const [],
    this.tabs = const [],
  });

  /// The tabs it is shown in (its `tab`), by their first pages: pushed from
  /// a page of one of them, it goes on that tab's history; none, over the
  /// whole bar.
  final List<String> tabs;

  /// A stable id, such as `product_detail`.
  final String id;

  /// The name shown on the map, such as `商品詳細`.
  final String label;

  /// A heading the pages are grouped under, such as `購入フロー`.
  final String section;

  /// The page widget's class, such as `ProductDetailPage`.
  final String? widget;

  /// The file of the page widget, relative to the app.
  final String? source;

  /// The route's path, parameters included: `/products/:id`.
  final String? path;

  /// The typed route class (go_router_builder's `GoRouteData`, say).
  final String? route;

  /// The states the page starts in, each a `@Preview`; the first is the one
  /// on the map.
  final List<SheetState> states;

  /// What a reader of the map should know of the page.
  final String? memo;

  /// Where more about the page is: its design, its spec, an issue.
  final List<SheetLink> links;

  /// The names of the [Sheet.dependencies] the page reads.
  final List<String> dependencies;
}

/// A link from a page to more about it.
class SheetLink {
  SheetLink(this.label, this.url);

  final String label;

  /// An `https:` (or `http:`, `mailto:`) URL; the HTML links no other kind.
  final String url;
}

/// Something pages read that their previews replace: a repository, an API
/// client. For reference: shown, not checked.
class SheetDependency {
  SheetDependency(this.name, {this.target, this.source});

  /// How the sheet calls it, such as `AuthRepository`.
  final String name;

  /// What the previews override: a provider, a type.
  final String? target;

  /// Where the app declares it, relative to the app.
  final String? source;
}

/// A way every state is shot: as a platform draws it (`ios` or `android`),
/// and, with [preview], as the `Preview` of that name the state's annotation
/// gives besides (a `MultiPreview` of sizes: `Desktop`) instead of its own.
class SheetVariant {
  const SheetVariant({
    required this.name,
    this.platform = VariantPlatform.ios,
    this.preview,
  });

  /// What the HTML calls it, such as `Android`; empty for the one variant of
  /// a sheet that names none.
  final String name;
  final VariantPlatform platform;

  /// The name of the `Preview` each state is in this variant, among those
  /// its annotation gives; null for the one the state names.
  final String? preview;
}

/// The platform a variant is drawn as.
enum VariantPlatform { ios, android }

/// A page started in one state: one `@Preview` of the sheet package.
class SheetState {
  SheetState({
    required this.name,
    required this.file,
    required this.symbol,
    this.index = 0,
    this.runtime = 0,
    this.uses = const {},
    this.data = false,
    this.conditions = const {},
  });

  /// Whether how the page starts in it is up to what it loads (empty,
  /// loading, an error), not to the arrow it comes by: an arrow that says
  /// no state may arrive in it, as in the page's first.
  final bool data;

  /// The values of the conditions it is the page's look in (its `if`),
  /// one each: in it, the app has them. Arriving where nothing says which
  /// state, the page shows the one the conditions' values are; a state
  /// without any shows under any.
  final Map<String, String> conditions;

  /// Whether it can be shown while the conditions have values [guard]
  /// allows: none of its own is one [guard] leaves out.
  bool allowedBy(Map<String, List<String>> guard) =>
      conditions.entries.every((e) => guard[e.key]?.contains(e.value) ?? true);

  /// The state, such as `未ログイン`, one of its page's own; [SheetEdge.when]
  /// and [SheetEdge.then] name it.
  final String name;

  /// The preview's file, relative to the app, its function, and the
  /// annotation's place among those on it: the app's own preview
  /// (`lib/features/home_preview.dart`), or the sheet package's
  /// (`contact_sheet/lib/preview/home.dart`).
  final String file;
  final String symbol;
  final int index;

  /// Of the `Preview`s the annotation gives (a `MultiPreview` gives several),
  /// which: shutter's runtime part of the shot id.
  final int runtime;

  /// The fake each dependency is in, by name: `{AuthRepository: ゲスト}`.
  final Map<String, String> uses;

  /// How the sheet names the preview: `lib/preview/home.dart#home@1`, or
  /// `#home@0.2` for the third `Preview` of a `MultiPreview`.
  String get preview =>
      '$file#$symbol${runtime != 0
          ? '@$index.$runtime'
          : index != 0
          ? '@$index'
          : ''}';

  /// The sheet package's directory, in the app.
  static const sheetPackage = 'contact_sheet';

  /// Whether the preview is the sheet package's, shot there, rather than
  /// the app's, shot in the app.
  bool get inSheetPackage => file.startsWith('$sheetPackage/');

  /// The preview's file in the project it is shot in: what shutter names
  /// its shot by.
  String get projectFile =>
      inSheetPackage ? file.substring(sheetPackage.length + 1) : file;
}

/// How a transition moves, as the app's code does it.
enum NavigationKind { push, go, replace, pop, redirect }

/// A transition: from [from], doing [trigger], the app shows [to].
///
/// Where it arrives is [Sheet.arrivals]': [then], [thenBy], the state of
/// [to] named as the one it leaves, or those the conditions choose.
class SheetEdge {
  SheetEdge({
    required this.from,
    required this.to,
    this.trigger,
    this.when = const [],
    this.guard = const {},
    this.sets = const {},
    this.then,
    this.thenBy = const {},
    this.kind = NavigationKind.push,
    this.source,
    this.item = 0,
    this.under = false,
    this.anywhere = false,
    this.tab,
  });

  /// For a `go` to a page in several tabs: which tab it opens it in, by its
  /// first page.
  final String? tab;

  /// Whether it is a pop back to the page under it, whichever (its `to` left
  /// out): one such edge to each page [from] can be put over, each taken
  /// only when that page is under it.
  final bool under;

  /// Whether its item is from every page (`from: '*'`): drawn once, from
  /// outside.
  final bool anywhere;

  /// Page ids.
  final String from;
  final String to;

  /// What the user does on [from]; null when nothing does (the router).
  final Trigger? trigger;

  /// The states of [from] it happens in; empty in every state.
  final List<String> when;

  /// The values of the conditions it happens while (its `if`), by
  /// condition; a condition it does not name, any.
  final Map<String, List<String>> guard;

  /// The values it gives the conditions (its `set`). A [then] naming a
  /// state of conditions gives theirs too.
  final Map<String, String> sets;

  /// The state of [to] it arrives in, from any state of [from]; null when
  /// the sheet does not say one for all.
  final String? then;

  /// The state of [to] it arrives in, by the state of [from] it leaves:
  /// `then` written as a map. Empty when [then] is one state, or none.
  final Map<String, String> thenBy;

  final NavigationKind kind;

  /// Where the app's code does it, relative to the app.
  final String? source;

  /// Its place in the sheet's `edges`: an item whose `from` lists several
  /// pages is an edge from each, all at the item's place.
  final int item;

  /// Which transition it is, the same from one export to the next while
  /// what it is stays: its pages, trigger, states, conditions and kind, not
  /// where it arrives (`home>cart label:Cart push`, `cart>checkout
  /// text:Buy [Full] {Login=Member} push`).
  String get key => [
    '$from>$to',
    ?trigger?.toString(),
    if (when.isNotEmpty) '[${(when.toList()..sort()).join(',')}]',
    if (guard.isNotEmpty) guardKey(guard),
    kind.name,
  ].join(' ');
}

/// [guard] as a key says it: `{Login=Member,Cart=Full|Empty}`, in order.
String guardKey(Map<String, List<String>> guard) =>
    '{${[for (final c in guard.keys.toList()..sort()) '$c=${(guard[c]!.toList()..sort()).join('|')}'].join(',')}}';

/// A deep link into [to], from outside the app.
class SheetEntry {
  SheetEntry({
    required this.to,
    required this.via,
    this.then,
    this.guard = const {},
    this.source,
    this.tab,
  });

  final String to;

  /// For a page in several tabs: which tab it opens it in.
  final String? tab;

  /// The link, as the app takes it: `/products/:id`.
  final String via;

  /// The state of [to] it opens in; null when the sheet does not say.
  final String? then;

  /// The values of the conditions it opens [to] while (its `if`); a
  /// condition it does not name, any: a link may come to the app at any
  /// time.
  final Map<String, List<String>> guard;

  /// Where the app's code takes it in, relative to the app.
  final String? source;

  /// Which deep link it is: `product_detail</products/:id`, and its
  /// conditions.
  String get key =>
      ['$to<$via', if (guard.isNotEmpty) guardKey(guard)].join(' ');
}

/// How a [Trigger] names what the user does.
enum TriggerKind { text, key, label, type, back, other }

/// What the user does on a page, written as shutter names a target:
/// `text:購入する`, `key:buy`, `label:カート`, `type:CartItemTile`; `back`;
/// or `other:<what>` for anything else (a swipe, a timer).
class Trigger {
  Trigger._(this.kind, this.what);

  final TriggerKind kind;

  /// The target, or what is done; empty for `back`.
  final String what;

  bool get isBack => kind == TriggerKind.back;

  /// Whether it is named only in the code (a key, a widget class): nothing
  /// on the screen says it, so it means nothing to a reader outside the
  /// code.
  bool get namedInCode => kind == TriggerKind.key || kind == TriggerKind.type;

  /// [value] as a trigger; null when it is none of the forms.
  static Trigger? parse(String value) {
    if (value == 'back') return Trigger._(TriggerKind.back, '');
    final colon = value.indexOf(':');
    if (colon <= 0) return null;
    final kind = TriggerKind.values.asNameMap()[value.substring(0, colon)];
    final what = value.substring(colon + 1);
    if (kind == null || kind == TriggerKind.back || what.isEmpty) return null;
    return Trigger._(kind, what);
  }

  @override
  String toString() => isBack ? 'back' : '${kind.name}:$what';
}

/// An item of `edges` as written: [from] null for `*`, [to] null for a pop
/// back to the page under it; [edge] makes its edge from one page to one.
class _EdgeItem {
  _EdgeItem({
    required this.item,
    required this.from,
    required this.to,
    required this.kind,
    required this.edge,
  });

  final int item;
  final List<String>? from;
  final String? to;
  final NavigationKind kind;
  final SheetEdge Function(String from, String to) edge;
}

/// What is wrong with `sheet.yaml`, and where.
class SheetException implements Exception {
  SheetException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _Parser {
  _Parser(this.m);

  final Messages m;

  Never _fail(String where, String problem) =>
      throw SheetException(m.sheetInvalid(where, problem));

  Sheet sheet(String text) {
    final Object? yaml;
    try {
      yaml = loadYaml(text);
    } on YamlException catch (e) {
      throw SheetException(m.sheetNotYaml(e.message));
    }
    final root = _map(yaml ?? YamlMap(), 'sheet.yaml', const {
      'conditions',
      'tabs',
      'pages',
      'edges',
      'entries',
      'dependencies',
      'variants',
    });
    final dependencies = [
      for (final (i, d) in _list(root, 'dependencies', 'sheet.yaml').indexed)
        _dependency(d, 'dependencies[$i]'),
    ];
    final names = {for (final d in dependencies) d.name};
    final conditions = [
      for (final (i, c) in _list(root, 'conditions', 'sheet.yaml').indexed)
        _condition(c, 'conditions[$i]'),
    ];
    final byName = <String, SheetCondition>{};
    for (final (i, c) in conditions.indexed) {
      if (byName.putIfAbsent(c.name, () => c) != c) {
        _fail('conditions[$i]', m.sheetDuplicateCondition(c.name));
      }
    }
    // Each condition named, and each value one of its.
    void known(Map<String, Iterable<String>> values, String where) {
      for (final MapEntry(key: name, value: given) in values.entries) {
        final c =
            byName[name] ??
            _fail('$where.$name', m.sheetUnknownCondition(name));
        for (final value in given) {
          if (!c.values.contains(value)) {
            _fail('$where.$name', m.sheetUnknownValue(value, name));
          }
        }
      }
    }

    Map<String, List<String>> one(Map<String, String> values) => {
      for (final MapEntry(:key, :value) in values.entries) key: [value],
    };

    final pages = [
      for (final (i, p) in _list(root, 'pages', 'sheet.yaml').indexed)
        _page(p, 'pages[$i]', names),
    ];
    for (final (i, page) in pages.indexed) {
      for (final (j, state) in page.states.indexed) {
        known(one(state.conditions), 'pages[$i].states[$j].if');
      }
    }
    final byId = <String, SheetPage>{};
    for (final (i, page) in pages.indexed) {
      if (byId.putIfAbsent(page.id, () => page) != page) {
        _fail('pages[$i]', m.sheetDuplicatePage(page.id));
      }
    }
    SheetPage page(String id, String where) =>
        byId[id] ?? _fail(where, m.sheetUnknownPage(id));

    bool has(SheetPage page, String state) =>
        page.states.any((s) => s.name == state);

    final tabBars = [
      for (final (i, t) in _list(root, 'tabs', 'sheet.yaml').indexed)
        _tabBar(t, 'tabs[$i]'),
    ];
    // Each page the first of one tab, of one bar.
    final roots = <String>{};
    for (final (i, bar) in tabBars.indexed) {
      for (final (j, tab) in bar.tabs.indexed) {
        final where = 'tabs[$i].pages[$j]';
        page(tab.page, '$where.page');
        if (!roots.add(tab.page)) {
          _fail(where, m.sheetListedTwice(tab.page));
        }
        known(tab.guard, '$where.if');
      }
    }
    for (final (i, p) in pages.indexed) {
      for (final tab in p.tabs) {
        if (roots.contains(p.id)) _fail('pages[$i].tab', m.sheetTabInTab);
        if (!roots.contains(tab)) _fail('pages[$i].tab', m.sheetNotATab(tab));
      }
    }
    // Whether [page] is shown in the tab [tab] is the first page of.
    bool inTab(String page, String tab) =>
        page == tab || byId[page]!.tabs.contains(tab);
    final items = [
      for (final (i, e) in _list(root, 'edges', 'sheet.yaml').indexed)
        _edges(e, 'edges[$i]', i),
    ];
    // `from: '*'`: from every page but its `to`.
    List<String> fromOf(_EdgeItem item) =>
        item.from ??
        [
          for (final p in pages)
            if (p.id != item.to) p.id,
        ];
    for (final item in items) {
      for (final id in fromOf(item)) {
        page(id, 'edges[${item.item}].from');
      }
      if (item.to case final to?) page(to, 'edges[${item.item}].to');
    }
    // The pages each page can be put over: from each push or redirect into
    // it; those the page it takes the place of can be put over (and that
    // page, where a tab's page puts it over the bar instead); for a pop to
    // it, those the pages under the page popped can be put over.
    final over = <String, Set<String>>{};
    var grew = true;
    while (grew) {
      grew = false;
      for (final item in items) {
        final to = item.to;
        if (to == null) continue;
        for (final from in fromOf(item)) {
          final tabs = [if (roots.contains(from)) from, ...byId[from]!.tabs];
          final overBar = tabs.isNotEmpty && !tabs.any((t) => inTab(to, t));
          final under = switch (item.kind) {
            NavigationKind.push || NavigationKind.redirect => {from},
            NavigationKind.replace => {if (overBar) from, ...?over[from]},
            NavigationKind.pop => {
              for (final b in over[from] ?? const <String>{}) ...?over[b],
            },
            _ => const <String>{},
          };
          final known = over[to] ??= {};
          for (final id in under) {
            if (known.add(id)) grew = true;
          }
        }
      }
    }
    final edges = [
      for (final item in items)
        for (final from in fromOf(item))
          if (item.to case final to?)
            item.edge(from, to)
          else ...[
            if (over[from] == null || over[from]!.isEmpty)
              _fail('edges[${item.item}].to', m.sheetNothingUnder(from)),
            // A pop back to the page under it: to each it can be over.
            for (final p in pages)
              if (over[from]!.contains(p.id)) item.edge(from, p.id),
          ],
    ];
    for (final edge in edges) {
      final where = 'edges[${edge.item}]';
      final from = page(edge.from, '$where.from');
      final to = page(edge.to, '$where.to');
      for (final when in edge.when) {
        if (!has(from, when)) {
          _fail('$where.when', m.sheetUnknownState(when, from.id));
        }
      }
      final then = edge.then;
      if (then != null && !has(to, then)) {
        _fail('$where.then', m.sheetUnknownState(then, to.id));
      }
      for (final MapEntry(key: state, value: then) in edge.thenBy.entries) {
        if (!has(from, state)) {
          _fail('$where.then', m.sheetUnknownState(state, from.id));
        }
        if (edge.when.isNotEmpty && !edge.when.contains(state)) {
          _fail('$where.then', m.sheetThenNotWhen(state));
        }
        if (!has(to, then)) {
          _fail('$where.then', m.sheetUnknownState(then, to.id));
        }
      }
      known(edge.guard, '$where.if');
      known(one(edge.sets), '$where.set');
      // A then naming a state of conditions gives their values: not others
      // than set gives.
      for (final name in [?then, ...edge.thenBy.values]) {
        final state = to.states.firstWhere((s) => s.name == name);
        for (final MapEntry(:key, :value) in state.conditions.entries) {
          if (edge.sets[key] case final set? when set != value) {
            _fail('$where.then', m.sheetThenAgainstSet(name));
          }
        }
      }
      final leaving = edge.when.isEmpty
          ? from.states
          : from.states.where((s) => edge.when.contains(s.name));
      if (!leaving.any((s) => s.allowedBy(edge.guard))) {
        _fail('$where.if', m.sheetIfAgainstWhen);
      }
      if (edge.tab case final tab?) {
        if (edge.kind != NavigationKind.go) {
          _fail('$where.tab', m.sheetTabNotGo);
        }
        if (!inTab(to.id, tab)) {
          _fail('$where.tab', m.sheetTabNotOf(tab, to.id));
        }
      }
    }
    final entries = [
      for (final (i, e) in _list(root, 'entries', 'sheet.yaml').indexed)
        _entry(e, 'entries[$i]'),
    ];
    for (final (i, entry) in entries.indexed) {
      final to = page(entry.to, 'entries[$i].to');
      final then = entry.then;
      if (then != null && !has(to, then)) {
        _fail('entries[$i].then', m.sheetUnknownState(then, to.id));
      }
      known(entry.guard, 'entries[$i].if');
      if (entry.tab case final tab? when !inTab(to.id, tab)) {
        _fail('entries[$i].tab', m.sheetTabNotOf(tab, to.id));
      }
    }
    final variants = [
      for (final (i, v) in _list(root, 'variants', 'sheet.yaml').indexed)
        _variant(v, 'variants[$i]'),
    ];
    final variantNames = <String>{};
    for (final (i, v) in variants.indexed) {
      if (!variantNames.add(v.name)) {
        _fail('variants[$i]', m.sheetDuplicateVariant(v.name));
      }
    }
    return Sheet(
      pages: pages,
      edges: edges,
      entries: entries,
      conditions: conditions,
      tabBars: tabBars,
      dependencies: dependencies,
      variants: variants.isEmpty ? const [SheetVariant(name: '')] : variants,
    );
  }

  SheetCondition _condition(Object? yaml, String where) {
    final map = _map(yaml, where, const {'name', 'values', 'source'});
    final values = _strings(map, 'values', where);
    if (values.isEmpty) _fail('$where.values', m.sheetNoValues);
    final seen = <String>{};
    for (final (i, v) in values.indexed) {
      if (!seen.add(v)) _fail('$where.values[$i]', m.sheetListedTwice(v));
    }
    return SheetCondition(
      _required(map, 'name', where),
      values,
      source: _optional(map, 'source', where),
    );
  }

  /// `key: {condition: value}`: one value each.
  Map<String, String> _values(YamlMap map, String key, String where) =>
      switch (map[key]) {
        null => const {},
        final YamlMap values => {
          for (final MapEntry(key: c, value: v) in values.entries)
            '$c': v is String || v is num
                ? '$v'
                : _fail('$where.$key.$c', m.sheetNotText),
        },
        _ => _fail('$where.$key', m.sheetNotMap),
      };

  /// `if: {condition: value}` or `{condition: [value, ...]}`: the values
  /// it allows.
  Map<String, List<String>> _guard(YamlMap map, String where) =>
      switch (map['if']) {
        null => const {},
        final YamlMap values => {
          for (final MapEntry(key: c, value: v) in values.entries)
            '$c': switch (v) {
              final String s => [s],
              final num n => ['$n'],
              final YamlList list when list.isNotEmpty => [
                for (final (i, x) in list.indexed)
                  x is String || x is num
                      ? '$x'
                      : _fail('$where.if.$c[$i]', m.sheetNotText),
              ],
              final YamlList _ => _fail('$where.if.$c', m.sheetNoValues),
              _ => _fail('$where.if.$c', m.sheetNotText),
            },
        },
        _ => _fail('$where.if', m.sheetNotMap),
      };

  SheetVariant _variant(Object? yaml, String where) {
    final map = _map(yaml, where, const {'name', 'platform', 'preview'});
    final platform = _optional(map, 'platform', where);
    return SheetVariant(
      name: _required(map, 'name', where),
      platform: platform == null
          ? VariantPlatform.ios
          : VariantPlatform.values.asNameMap()[platform] ??
                _fail('$where.platform', m.sheetBadPlatform(platform)),
      preview: _optional(map, 'preview', where),
    );
  }

  SheetPage _page(Object? yaml, String where, Set<String> dependencyNames) {
    final map = _map(yaml, where, const {
      'id',
      'label',
      'section',
      'widget',
      'source',
      'path',
      'route',
      'dependencies',
      'memo',
      'links',
      'states',
      'tab',
    });
    final states = [
      for (final (i, s) in _list(map, 'states', where).indexed)
        _state(s, '$where.states[$i]'),
    ];
    if (states.isEmpty) _fail('$where.states', m.sheetNoStates);
    // A state is named by `when` and `then`: two of one name are one.
    final stateNames = <String>{};
    for (final (i, s) in states.indexed) {
      if (!stateNames.add(s.name)) {
        _fail('$where.states[$i]', m.sheetDuplicateState(s.name));
      }
    }
    final dependencies = _strings(map, 'dependencies', where);
    for (final name in dependencies) {
      if (!dependencyNames.contains(name)) {
        _fail('$where.dependencies', m.sheetUnknownDependency(name));
      }
    }
    return SheetPage(
      id: _required(map, 'id', where),
      label: _required(map, 'label', where),
      section: _optional(map, 'section', where) ?? '',
      widget: _optional(map, 'widget', where),
      source: _optional(map, 'source', where),
      path: _optional(map, 'path', where),
      route: _optional(map, 'route', where),
      memo: _optional(map, 'memo', where),
      links: [
        for (final (i, l) in _list(map, 'links', where).indexed)
          _link(l, '$where.links[$i]'),
      ],
      dependencies: dependencies,
      states: states,
      tabs: map['tab'] is YamlList
          ? _strings(map, 'tab', where)
          : [?_optional(map, 'tab', where)],
    );
  }

  SheetLink _link(Object? yaml, String where) {
    final map = _map(yaml, where, const {'label', 'url'});
    return SheetLink(
      _required(map, 'label', where),
      _required(map, 'url', where),
    );
  }

  /// `<file>#<symbol>[@<n>[.<k>]]`: the symbol as shutter names it (`fn`,
  /// `Class.method`, `Class.new`, `Class.named`), the annotation's place,
  /// and which of the `Preview`s it gives.
  static final _preview = RegExp(
    r'^([^#@]+\.dart)#([A-Za-z_$][\w$]*(?:\.[A-Za-z_$][\w$]*)?)'
    r'(?:@(\d+)(?:\.(\d+))?)?$',
  );

  SheetState _state(Object? yaml, String where) {
    final map = _map(yaml, where, const {
      'name',
      'preview',
      'uses',
      'data',
      'if',
    });
    final preview = _required(map, 'preview', where);
    final match = _preview.firstMatch(preview);
    if (match == null) _fail('$where.preview', m.sheetBadPreview(preview));
    // Written as shutter names it, which its shot's id is of: `/` apart,
    // nothing to resolve.
    final file = match[1]!;
    if (file.contains(r'\') ||
        file.split('/').any((s) => s.isEmpty || s == '.' || s == '..')) {
      _fail('$where.preview', m.sheetPreviewPath(file));
    }
    final uses = map['uses'];
    if (uses != null && uses is! YamlMap) {
      _fail('$where.uses', m.sheetNotMap);
    }
    final data = map['data'] ?? false;
    if (data is! bool) _fail('$where.data', m.sheetNotBool);
    return SheetState(
      name: _required(map, 'name', where),
      file: file,
      symbol: match[2]!,
      index: int.parse(match[3] ?? '0'),
      runtime: int.parse(match[4] ?? '0'),
      uses: {
        if (uses is YamlMap)
          for (final MapEntry(:key, :value) in uses.entries) '$key': '$value',
      },
      data: data,
      conditions: _values(map, 'if', where),
    );
  }

  /// The item [item] of `edges`, before it is an edge from each page its
  /// `from` names (every page, for `*`), to its `to` (each page it can be
  /// put over, for a pop without one).
  _EdgeItem _edges(Object? yaml, String where, int item) {
    final map = _map(yaml, where, const {
      'from',
      'to',
      'trigger',
      'when',
      'if',
      'set',
      'then',
      'kind',
      'tab',
      'source',
    });
    final trigger = _optional(map, 'trigger', where);
    final kind = _optional(map, 'kind', where);
    // One page, a list of them (the same transition from each), or `*`.
    final anywhere = map['from'] == '*';
    final from = anywhere
        ? null
        : map['from'] is YamlList
        ? _strings(map, 'from', where)
        : [_required(map, 'from', where)];
    if (from != null && from.isEmpty) _fail(where, m.sheetMissing('from'));
    final listed = <String>{};
    for (final (j, id) in (from ?? const <String>[]).indexed) {
      if (!listed.add(id)) _fail('$where.from[$j]', m.sheetListedTwice(id));
    }
    // One state, or one by the state it leaves.
    final thenMap = map['then'];
    final thenBy = <String, String>{
      if (thenMap is YamlMap)
        for (final MapEntry(:key, :value) in thenMap.entries)
          '$key': value is String || value is num
              ? '$value'
              : _fail('$where.then.$key', m.sheetNotText),
    };
    final then = thenMap is YamlMap ? null : _optional(map, 'then', where);
    // One state, or a list of them.
    final when = map['when'] is YamlList
        ? _strings(map, 'when', where)
        : [?_optional(map, 'when', where)];
    final trig = trigger == null
        ? null
        : Trigger.parse(trigger) ??
              _fail('$where.trigger', m.sheetBadTrigger(trigger));
    final how = kind == null
        ? NavigationKind.push
        : NavigationKind.values.asNameMap()[kind] ??
              _fail('$where.kind', m.sheetBadKind(kind));
    // A pop may leave `to` out: back to the page under it, whichever.
    final to = how == NavigationKind.pop && !anywhere
        ? _optional(map, 'to', where)
        : _required(map, 'to', where);
    if (anywhere && when.isNotEmpty) _fail('$where.when', m.sheetWhenAnywhere);
    final source = _optional(map, 'source', where);
    final guard = _guard(map, where);
    final sets = _values(map, 'set', where);
    final tab = _optional(map, 'tab', where);
    return _EdgeItem(
      item: item,
      from: from,
      to: to,
      kind: how,
      edge: (f, t) => SheetEdge(
        from: f,
        to: t,
        trigger: trig,
        when: when,
        guard: guard,
        sets: sets,
        then: then,
        thenBy: thenBy,
        kind: how,
        source: source,
        item: item,
        under: to == null,
        anywhere: anywhere,
        tab: tab,
      ),
    );
  }

  SheetEntry _entry(Object? yaml, String where) {
    final map = _map(yaml, where, const {
      'to',
      'via',
      'then',
      'if',
      'tab',
      'source',
    });
    return SheetEntry(
      to: _required(map, 'to', where),
      via: _required(map, 'via', where),
      then: _optional(map, 'then', where),
      guard: _guard(map, where),
      source: _optional(map, 'source', where),
      tab: _optional(map, 'tab', where),
    );
  }

  SheetTabBar _tabBar(Object? yaml, String where) {
    final map = _map(yaml, where, const {'pages', 'retap', 'source'});
    final items = _list(map, 'pages', where);
    if (items.isEmpty) _fail(where, m.sheetMissing('pages'));
    final retap = _optional(map, 'retap', where);
    return SheetTabBar(
      [
        for (final (i, item) in items.indexed)
          () {
            final at = '$where.pages[$i]';
            final tab = _map(item, at, const {'page', 'trigger', 'if'});
            final trigger = _required(tab, 'trigger', at);
            return SheetTab(
              _required(tab, 'page', at),
              Trigger.parse(trigger) ??
                  _fail('$at.trigger', m.sheetBadTrigger(trigger)),
              guard: _guard(tab, at),
            );
          }(),
      ],
      retapFirst: switch (retap) {
        null || 'stay' => false,
        'first' => true,
        _ => _fail('$where.retap', m.sheetBadRetap(retap)),
      },
      source: _optional(map, 'source', where),
    );
  }

  SheetDependency _dependency(Object? yaml, String where) {
    final map = _map(yaml, where, const {'name', 'target', 'source'});
    return SheetDependency(
      _required(map, 'name', where),
      target: _optional(map, 'target', where),
      source: _optional(map, 'source', where),
    );
  }

  /// [yaml] as a map of [fields] only: a key misspelt, or put where it does
  /// not go, is told rather than left out unread.
  YamlMap _map(Object? yaml, String where, Set<String> fields) {
    if (yaml is! YamlMap) _fail(where, m.sheetNotMap);
    for (final key in yaml.keys) {
      if (!fields.contains('$key')) {
        _fail('$where.$key', m.sheetUnknownField('$key', fields.join(', ')));
      }
    }
    return yaml;
  }

  List<Object?> _list(YamlMap map, String key, String where) =>
      switch (map[key]) {
        null => const [],
        final YamlList list => list,
        _ => _fail('$where.$key', m.sheetNotList),
      };

  List<String> _strings(YamlMap map, String key, String where) => [
    for (final (i, v) in _list(map, key, where).indexed)
      if (v is String || v is num)
        '$v'
      else
        _fail('$where.$key[$i]', m.sheetNotText),
  ];

  String _required(YamlMap map, String key, String where) =>
      _optional(map, key, where) ?? _fail(where, m.sheetMissing(key));

  /// A scalar as text: `/` and `1.0` are written without quotes.
  String? _optional(YamlMap map, String key, String where) =>
      switch (map[key]) {
        null => null,
        final String s => s,
        final num n => '$n',
        final bool b => '$b',
        _ => _fail('$where.$key', m.sheetNotText),
      };
}
