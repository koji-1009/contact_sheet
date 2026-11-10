/// The route between two pages, as the app's navigator goes.
///
/// The history is a stack of frames, a page in one of its states, the top
/// the one shown; beside it, the values of the conditions the app keeps
/// across its pages (logged in or not), one for the whole app: a pop does
/// not bring an older value back. A push (or a redirect) puts a page on the
/// stack, a replace takes the top's place, a go starts it again; a pop, or
/// the back of any page pushed, takes the top off, and the page under it
/// shows in the state of the name the top was in (full above, full below),
/// unless a written pop says its own, or the conditions now say another. The
/// back is every page's, but where the sheet writes what the back does
/// there (goes elsewhere, asks first). A pop back to the page under it,
/// whichever, is written as one to each page it can be over, each taken
/// only over its own. A transition happens in the states its `when` names,
/// while the conditions have the values its `if` names, and may change them
/// (`set`, or the conditions of the state its `then` names).
///
/// Where a transition arrives is a function of the state it leaves and the
/// conditions: the state its `then` names; else the state of `to` of the
/// name it leaves, if the conditions after it allow it; else those of `to`
/// nothing chooses but the conditions or what it loads ([RouteState]): its
/// first, its `data` states, and its states of the conditions, all those
/// the conditions after it allow. None: the page has no look then, and the
/// transition does not happen.
///
/// A tab bar whose tabs each keep their own history ([RouteTabBar]) is a
/// shell at the bottom of the stack: the tab shown, and each tab's history,
/// which a push from a page in a tab to a page shown in it adds to, and a
/// switch to another tab (any time the bar is shown) leaves as it is, to be
/// found again. A tab left with more than [Router.tabDepth] pages is not
/// followed: its history is kept as one of the states, finite, so that the
/// route stays exact within the bound (with two histories kept and the
/// conditions shared, whether a page can be reached at all could not be
/// decided); a page pushed past it, in the tab shown, goes on the stack,
/// from where the bar is not switched. Where none is found within it, it is
/// searched for once more within [Router.tabDepth] pages more. [Route.bounded]
/// tells a route a switch from deeper might have made shorter, or found, and
/// [Route.atLeast] the fewest steps that one would take.
///
/// The fewest steps are a shortest path in this pushdown system, its stack
/// the frames and its control the conditions' values and the shell, exact,
/// with no bound on the stack (a shortest route can need a page twice on
/// it): each frame entered under each value of the conditions is
/// summarised once, when the search first enters it, the fewest steps from
/// it to each frame and value at its level through the pages pushed and
/// popped above it, in one Dijkstra over all levels (Knuth's: a step out of
/// a pushed page costs more than the steps it is made of); the route is
/// then searched from a stack over those summaries, the shell's moves among
/// them, by A*: the bound below the steps left is the fewest moves to the
/// page in what the app shows with the histories not followed (as
/// [Router.shown] has it), each step of the search one of those moves. The
/// shell is never pushed: no summary holds it.
///
/// Some conditions can be held at a value ([Router.held]): the app launches
/// with them, and nothing that would change them happens. What the app shows
/// so ([Router.shown]) is what the map shows to whoever chose those values:
/// what a guest sees, never signed in.
///
/// It reads no file and draws nothing: `index.html` runs it compiled to
/// JavaScript (`tool/route_js.dart`), from `sheet.json`.
library;

/// What a transition does to the history.
enum RouteMove {
  /// Puts its page over the one shown: a push, a redirect.
  push,

  /// Takes the place of the one shown.
  replace,

  /// Starts the history again with its page: a go.
  reset,

  /// Takes the one shown off: a pop.
  pop;

  /// The move of a transition's kind, as the sheet names it.
  static RouteMove of(String kind) => switch (kind) {
    'replace' => replace,
    'go' => reset,
    'pop' => pop,
    _ => push,
  };
}

/// What the app keeps across its pages (logged in or not), and its values:
/// the first is what the app launches with.
class RouteCondition {
  const RouteCondition(this.name, this.values);

  final String name;
  final List<String> values;
}

/// A state of a page.
class RouteState {
  const RouteState(this.name, {this.conditions = const {}, this.data = false});

  final String name;

  /// The conditions' values it is the page's look in; none, in any.
  final Map<String, String> conditions;

  /// Whether what the page loads decides it, not the transition.
  final bool data;
}

/// A page, and its states in order: the first is how it starts.
class RoutePage {
  const RoutePage(this.id, this.states, {this.tabs = const [], this.parent});

  final String id;
  final List<RouteState> states;

  /// The tabs it is shown in, by their first pages; none, over the bar.
  final List<String> tabs;

  /// The page its route is nested under: with nothing under it (after a go,
  /// a deep link, the launch), its back goes there, as go_router builds the
  /// pages of a location's path under it.
  final String? parent;
}

/// A tab bar whose tabs each keep their own history.
class RouteTabBar {
  const RouteTabBar(this.tabs, {this.retapFirst = false});

  final List<RouteTab> tabs;

  /// Whether tapping the tab shown again goes back to its first page.
  final bool retapFirst;
}

/// A tab: its first page, and the values of the conditions it can be
/// switched to while.
class RouteTab {
  const RouteTab(this.page, {this.guard = const {}});

  final String page;
  final Map<String, List<String>> guard;
}

/// A transition, as the route reads it.
class RouteEdge {
  const RouteEdge({
    required this.from,
    required this.to,
    required this.move,
    this.back = false,
    this.under = false,
    this.when = const [],
    this.guard = const {},
    this.sets = const {},
    this.then,
    this.thenBy = const {},
    this.tab,
  });

  /// Page ids.
  final String from;
  final String to;
  final RouteMove move;

  /// Whether it is done by the back: written, it takes the place of the
  /// back of the page it is from (a pop that goes elsewhere than the page
  /// under it, a confirmation shown first).
  final bool back;

  /// Whether it is a pop back to the page under it, taken only when that
  /// page is [to]: the sheet writes one for each page it can be over.
  final bool under;

  /// The states of [from] it happens in; empty in every state.
  final List<String> when;

  /// The values of the conditions it happens while (its `if`), by
  /// condition; a condition not named, any.
  final Map<String, List<String>> guard;

  /// The values it gives the conditions (its `set`).
  final Map<String, String> sets;

  /// The state of [to] it arrives in: one, or one by the state it leaves.
  final String? then;
  final Map<String, String> thenBy;

  /// For a go to a page in several tabs: the tab it opens it in, by its
  /// first page.
  final String? tab;

  bool can(String state) => when.isEmpty || when.contains(state);
}

/// A page in a state.
typedef RouteFrame = ({String page, String state});

/// A deep link: its page, the state it opens in (null: as nothing says),
/// the values of the conditions it opens while (none named: any), and the
/// tab it opens the page in, by its first page.
typedef RouteEntry = ({
  String to,
  String? then,
  Map<String, List<String>> guard,
  String? tab,
});

/// What the app shows while some conditions keep their values
/// ([Router.held]): each page it reaches, by id, with the states it reaches
/// it in, in the pages' order; the edges that happen, and the deep links
/// that open, by their places.
class RouteShown {
  const RouteShown(this.states, this.edges, this.entries);

  final Map<String, List<String>> states;
  final List<int> edges;
  final List<int> entries;

  Map<String, Object?> toJson() => {
    'states': states,
    'edges': edges,
    'entries': entries,
  };
}

/// A step of a route: [edge] done (its place in the edges), or, without
/// one, what [move] says (`back`, `switch` to another tab, `retap` the tab
/// shown), from [from], showing [to], giving the conditions the values in
/// [sets]; [tab], the tab shown after it (by its first page), if one is.
class RouteStep {
  const RouteStep(
    this.edge, {
    required this.from,
    required this.to,
    this.sets = const {},
    this.move = 'edge',
    this.tab,
  });

  final int? edge;
  final RouteFrame from;
  final RouteFrame to;

  /// The conditions it changed, and their values after it.
  final Map<String, String> sets;

  /// `edge`, `back`, `switch` or `retap`.
  final String move;
  final String? tab;

  Map<String, Object?> toJson() => {
    'edge': edge,
    'move': move,
    'from': _frameJson(from),
    'to': _frameJson(to),
    'set': sets,
    'tab': tab,
  };
}

/// A route: the history it starts with ([start], its top last), the
/// conditions' values then ([valuation]), and its steps; null when there
/// is none. In a tab bar, [start] is the tab shown's history (its first
/// [inTab] frames) and what is over it; [active], that tab, by its first
/// page; [tabs], the other tabs' histories, as left.
class Route {
  const Route(
    this.start,
    this.steps, {
    this.valuation = const {},
    this.active,
    this.inTab = 0,
    this.pastBound = 0,
    this.tabs = const [],
    this.bounded = false,
    this.atLeast,
    this.searched = true,
  });

  final List<RouteFrame> start;

  /// Of [start]'s frames over the tab shown's first [inTab], how many are
  /// in its history past [Router.tabDepth] (the rest are over the bar).
  final int pastBound;

  /// Whether the search, and that of the start's history, went to the end
  /// ([Router.searchLimit]): if not, the app may have a route, or a shorter
  /// one, than this.
  final bool searched;
  final Map<String, String> valuation;
  final List<RouteStep>? steps;
  final String? active;
  final int inTab;
  final List<({String page, List<RouteFrame> frames})> tabs;

  /// Whether a switch from a tab left deeper than [Router.tabDepth], which
  /// is not followed, might have made it shorter (or found one).
  final bool bounded;

  /// Where none is found but one might be past the bound ([bounded]): the
  /// fewest steps that one would take, as the search, gone to the end
  /// within the bound, proves; null otherwise, and where the start alone
  /// is past the bound and the search proves no fewer.
  final int? atLeast;

  Map<String, Object?> toJson() => {
    'start': [for (final f in start) _frameJson(f)],
    'valuation': valuation,
    'active': active,
    'inTab': inTab,
    'pastBound': pastBound,
    'tabs': [
      for (final t in tabs)
        {
          'page': t.page,
          'frames': [for (final f in t.frames) _frameJson(f)],
        },
    ],
    'bounded': bounded,
    'atLeast': atLeast,
    'searched': searched,
    'steps': steps == null ? null : [for (final s in steps!) s.toJson()],
  };
}

List<Map<String, Object?>> _maps(Object? list) =>
    ((list as List<Object?>?) ?? const []).cast<Map<String, Object?>>();

Map<String, String> _strings(Object? map) =>
    ((map as Map<String, Object?>?) ?? const {}).cast<String, String>();

Map<String, List<String>> _lists(Object? map) => {
  for (final MapEntry(:key, :value)
      in ((map as Map<String, Object?>?) ?? const {}).entries)
    key: (value! as List<Object?>).cast<String>(),
};

Map<String, String> _frameJson(RouteFrame f) => {
  'page': f.page,
  'state': f.state,
};

/// A condition's value, as the router keeps it: their places.
typedef _Value = (int, int);

/// Numbers, as a key: equal when they are, in order.
class _Ints {
  _Ints(this.values) : hashCode = Object.hashAll(values);

  final List<int> values;

  @override
  final int hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _Ints || other.hashCode != hashCode) return false;
    final a = values, b = other.values;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The shell of a tab bar: the tab shown (its place among all bars' tabs),
/// each of the bar's tabs' history (canonical frames, empty for one not
/// opened yet), and the conditions' values.
class _Shell {
  _Shell(this.bar, this.active, this.stacks, this.g);

  final int bar;
  final int active;
  final List<List<int>> stacks;
  final int g;
}

/// What a transition does to the history, from where the page shown is
/// ([Router._effect]): the one place each move's effect is told, which the
/// search, its summaries and what the app shows ([_Unfollowed]) each read,
/// each switching over all of them.
enum _Effect {
  /// Its page goes over the one shown, in the same tab's history if that
  /// is in one.
  push,

  /// Its page goes over the bar, the tab's page kept under it: from a tab's
  /// history, a page not shown in that tab, pushed or in its place.
  overBar,

  /// Its page takes the place of the one shown.
  replace,

  /// Its page starts the history again ([Router._startAt]).
  reset,

  /// The page shown is taken off: what is under it says where it lands
  /// ([Router._landOn]), else [Router._alone].
  pop,
}

/// Where a page with nothing under it goes by a pop or its back
/// ([Router._alone]): [node] alone in the tab's history it was in, where it
/// [stays] in it; else [node] as all the history (a frame, or a shell).
typedef _Alone = ({int node, bool stays});

/// The routes between the pages of a sheet.
///
/// A node is a frame under one valuation of the conditions (their values,
/// one each, numbered in mixed radix: the launch's is 0); only those whose
/// state the valuation allows are ever reached. A page shown in a tab has a
/// frame for each such tab besides, for its history past [tabDepth]; and a
/// shell is a node of its own, numbered after the frames' as it is met.
class Router {
  Router(
    this.pages,
    this.edges, {
    this.conditions = const [],
    this.tabBars = const [],
    this.tabDepth = 3,
    this.searchLimit = 20000,
    this.held = const {},
  }) {
    var count = 1;
    for (final (i, c) in conditions.indexed) {
      _conditions[c.name] = i;
      _strides.add(count);
      count *= c.values.length;
    }
    _valuations = count;
    for (final (b, bar) in tabBars.indexed) {
      final ids = <int>[];
      for (final (i, tab) in bar.tabs.indexed) {
        _rootTab[tab.page] = _tabRoots.length;
        ids.add(_tabRoots.length);
        _tabRoots.add(tab.page);
        _tabBar.add(b);
        _tabPos.add(i);
        _tabGuards.add(_guard(tab.guard));
      }
      _barTabs.add(ids);
    }
    for (final p in pages) {
      _inTabs[p.id] = [for (final t in p.tabs) ?_rootTab[t]];
    }
    for (final p in pages) {
      final frames = _pageFrames[p.id] = [];
      for (final (i, s) in p.states.indexed) {
        (_ids[p.id] ??= {})[s.name] = _frames.length;
        frames.add(_frames.length);
        _addFrame((page: p.id, state: s.name), null, _frames.length);
        _requires.add(_values(s.conditions));
        _decided.add(i == 0 || s.data || s.conditions.isNotEmpty);
      }
    }
    // A page's frames in each tab it is shown in, past the bound; a page a
    // pop lands on in place of the page under it takes that page's place in
    // its tab's history, whichever tab, so it has a frame in each.
    final landed = {
      for (final e in edges)
        if (e.move == RouteMove.pop && !e.under) e.to,
    };
    final canonical = _frames.length;
    for (var f = 0; f < canonical; f++) {
      final page = _frames[f].page;
      final tabs = {
        ?_rootTab[page],
        ..._inTabs[page]!,
        if (landed.contains(page))
          for (var t = 0; t < _tabRoots.length; t++) t,
      };
      for (final t in tabs) {
        _deep[(f, t)] = _frames.length;
        _addFrame(_frames[f], t, f);
        _requires.add(_requires[f]);
        _decided.add(_decided[f]);
      }
    }
    for (final (i, e) in edges.indexed) {
      (_byFrom[e.from] ??= []).add(i);
      _sets.add(_values(e.sets));
      _guards.add(_guard(e.guard));
    }
  }

  /// [json], `sheet.json`: its conditions, tab bars, pages and edges; the
  /// conditions' values [held].
  factory Router.fromJson(
    Map<String, Object?> json, {
    Map<String, String> held = const {},
  }) => Router(
    held: held,
    [
      for (final p in _maps(json['pages']))
        RoutePage(
          p['id']! as String,
          [
            for (final s in _maps(p['states']))
              RouteState(
                s['name']! as String,
                conditions: _strings(s['if']),
                data: s['data'] == true,
              ),
          ],
          tabs: ((p['tab'] as List<Object?>?) ?? const []).cast<String>(),
          parent: p['parent'] as String?,
        ),
    ],
    [
      for (final e in _maps(json['edges']))
        RouteEdge(
          from: e['from']! as String,
          to: e['to']! as String,
          move: RouteMove.of(e['kind']! as String),
          back: e['trigger'] == 'back',
          under: e['under'] == true,
          when: (e['when']! as List<Object?>).cast<String>(),
          guard: _lists(e['if']),
          sets: _strings(e['set']),
          then: e['then'] is String ? e['then']! as String : null,
          thenBy: e['then'] is Map ? _strings(e['then']) : const {},
          tab: e['tab'] as String?,
        ),
    ],
    conditions: [
      for (final c in _maps(json['conditions']))
        RouteCondition(
          c['name']! as String,
          (c['values']! as List<Object?>).cast<String>(),
        ),
    ],
    tabBars: [
      for (final b in _maps(json['tabs']))
        RouteTabBar([
          for (final t in _maps(b['pages']))
            RouteTab(t['page']! as String, guard: _lists(t['if'])),
        ], retapFirst: b['retap'] == 'first'),
    ],
  );

  /// The deep links of [json], `sheet.json`.
  static List<RouteEntry> entriesFromJson(Map<String, Object?> json) => [
    for (final e in _maps(json['entries']))
      (
        to: e['to']! as String,
        then: e['then'] as String?,
        guard: _lists(e['if']),
        tab: e['tab'] as String?,
      ),
  ];

  final List<RoutePage> pages;
  final List<RouteEdge> edges;
  final List<RouteCondition> conditions;
  final List<RouteTabBar> tabBars;

  /// The most pages of a tab's history kept when another tab is shown.
  final int tabDepth;

  /// The most nodes a search takes before it stops short. With tab bars
  /// whose tabs keep their histories, and conditions all of them share,
  /// the histories that can be are as many as the tabs' histories
  /// multiplied together: telling that a page cannot be reached, which
  /// takes all of them, can be past any time an open page has, though a
  /// route found is found long before. Past it, [Route.searched] is false.
  final int searchLimit;

  /// The conditions' values held, by condition: the app launches with them,
  /// and nothing that would change them happens (a transition setting
  /// another, a state of another arrived in). None: every value can be.
  final Map<String, String> held;

  late final List<_Value> _held = _values(held);

  /// The values the app launches with: each condition's first, but those
  /// held.
  late final int _first = _apply(_held, 0);

  /// Whether [node]'s values are those held.
  bool _keeps(int node) => _holds(_held, _gOf(node));

  final _conditions = <String, int>{};
  final _strides = <int>[];
  late final int _valuations;

  /// The tabs of all bars, in order: each one's first page, bar, place in
  /// its bar, and the values it can be switched to while; each bar's tabs;
  /// the tab a page is the first of; the tabs a page is shown in.
  final _tabRoots = <String>[];
  final _tabBar = <int>[];
  final _tabPos = <int>[];
  final _tabGuards = <List<(int, Set<int>)>>[];
  final _barTabs = <List<int>>[];
  final _rootTab = <String?, int>{};
  final _inTabs = <String, List<int>>{};

  /// Every frame (a page in a state, in a tab past the bound or not): its
  /// page and state, its tab (null for the page's own, canonical, frame),
  /// and its canonical frame; a canonical frame's in each tab.
  final _frames = <RouteFrame>[];
  final _frameTab = <int?>[];
  final _canon = <int>[];
  final _deep = <(int, int), int>{};
  final _ids = <String, Map<String, int>>{};
  final _pageFrames = <String, List<int>>{};

  void _addFrame(RouteFrame frame, int? tab, int canon) {
    _frames.add(frame);
    _frameTab.add(tab);
    _canon.add(canon);
  }

  /// For each frame: the conditions' values its state requires; whether
  /// something but the transition chooses it (unsaid: the page's first, a
  /// `data` state, a state of the conditions).
  final _requires = <List<_Value>>[];
  final _decided = <bool>[];

  /// For each edge: the values it gives, and those it happens while.
  final _sets = <List<_Value>>[];
  final _guards = <List<(int, Set<int>)>>[];
  final _byFrom = <String, List<int>>{};

  /// The shells met, and their numbers by what they hold.
  final _shells = <_Shell>[];
  final _shellIds = <_Ints, int>{};

  int? _frame(String page, String state) => _ids[page]?[state];

  int _node(int frame, int g) => frame * _valuations + g;
  int get _nodeCount => _frames.length * _valuations;
  bool _isShell(int node) => node >= _nodeCount;
  _Shell _shellAt(int node) => _shells[node - _nodeCount];

  /// The frame [node] shows (a shell, the tab shown's top), and its values.
  int _frameOf(int node) {
    if (!_isShell(node)) return node ~/ _valuations;
    final s = _shellAt(node);
    return s.stacks[_tabPos[s.active]].last;
  }

  int _gOf(int node) => _isShell(node) ? _shellAt(node).g : node % _valuations;

  /// [node] as the canonical frame it shows, under its values.
  int _plain(int node) => _node(_canon[_frameOf(node)], _gOf(node));

  /// The tabs' histories met, each once, numbered: a shell is told by the
  /// numbers of its histories, and a history a shell keeps from the one it
  /// came from is not read again.
  final _histories = <List<int>>[];
  final _historyIds = <_Ints, int>{};
  final _historyOf = Map<List<int>, int>.identity();

  int _history(List<int> history) =>
      _historyOf[history] ??= _historyIds[_Ints(history)] ??= () {
        _histories.add(history);
        return _histories.length - 1;
      }();

  /// The shell of [bar] showing [active], with [stacks], under [g].
  int _shell(int bar, int active, List<List<int>> stacks, int g) {
    final ids = [for (final s in stacks) _history(s)];
    return _shellIds[_Ints([bar, active, g, ...ids])] ??= () {
      _shells.add(
        _Shell(bar, active, [for (final id in ids) _histories[id]], g),
      );
      return _nodeCount + _shells.length - 1;
    }();
  }

  /// [s] with the tab shown's history [stack], under [g], showing [active]
  /// (the same tab, unless said).
  int _withStack(_Shell s, List<int> stack, int g, {int? active}) {
    final t = active ?? s.active;
    return _shell(s.bar, t, [
      for (final (i, h) in s.stacks.indexed) i == _tabPos[t] ? stack : h,
    ], g);
  }

  /// A new shell showing the tab [t], its history [frame] alone.
  int _newShell(int t, int frame, int g) => _shell(_tabBar[t], t, [
    for (final u in _barTabs[_tabBar[t]]) u == t ? [frame] : const <int>[],
  ], g);

  /// Whether [page] is shown in the tab [t]: its first page, or one in it.
  bool _inTab(String page, int t) =>
      _rootTab[page] == t || _inTabs[page]!.contains(t);

  /// The tab a go or a deep link opens [page] in, naming the tab [named]
  /// (its `tab`) or not, while [active] is shown; null when the page is in
  /// none.
  int? _goTab(String page, int? active, String? named) {
    final t = _rootTab[named] ?? _rootTab[page];
    if (t != null) return t;
    final tabs = _inTabs[page]!;
    if (tabs.isEmpty) return null;
    return active != null && tabs.contains(active) ? active : tabs.first;
  }

  /// Where a go, or the app's launch, or a deep link, puts [node] (of a
  /// canonical frame) as all the history, from [ctx] (the shell at the
  /// bottom, or -1), naming the tab [named] or not: in its tab (keeping the
  /// other tabs' histories when the shell is the same bar's), or alone.
  int _startAt(int node, int ctx, {String? named}) {
    final f = _frameOf(node);
    final shell = ctx < 0 ? null : _shellAt(ctx);
    final t = _goTab(_frames[f].page, shell?.active, named);
    if (t == null) return node;
    if (shell != null && shell.bar == _tabBar[t]) {
      return _withStack(shell, [f], _gOf(node), active: t);
    }
    return _newShell(t, f, _gOf(node));
  }

  int _value(int g, int c) => g ~/ _strides[c] % conditions[c].values.length;

  List<_Value> _values(Map<String, String> values) => [
    for (final MapEntry(:key, :value) in values.entries)
      if (_conditions[key] case final c?)
        if (conditions[c].values.indexOf(value) case final v when v >= 0)
          (c, v),
  ];

  List<(int, Set<int>)> _guard(Map<String, List<String>> guard) => [
    for (final MapEntry(:key, :value) in guard.entries)
      if (_conditions[key] case final c?)
        (c, {for (final v in value) conditions[c].values.indexOf(v)}),
  ];

  int _apply(List<_Value> values, int g) {
    for (final (c, v) in values) {
      g += (v - _value(g, c)) * _strides[c];
    }
    return g;
  }

  bool _holds(List<_Value> values, int g) =>
      values.every((cv) => _value(g, cv.$1) == cv.$2);

  bool _guarded(List<(int, Set<int>)> guard, int g) =>
      guard.every((cv) => cv.$2.contains(_value(g, cv.$1)));

  Map<String, String> _named(int g) => {
    for (final (c, condition) in conditions.indexed)
      condition.name: condition.values[_value(g, c)],
  };

  /// The values [after] has that [before] has not.
  Map<String, String> _changed(int before, int after) => {
    for (final (c, condition) in conditions.indexed)
      if (_value(before, c) != _value(after, c))
        condition.name: condition.values[_value(after, c)],
  };

  /// The nodes [page] can show in under [g] where nothing says which.
  List<int> _unsaid(String page, int g) =>
      (_unsaidCache[page] ??= List.filled(_valuations, null))[g] ??= [
        for (final f in _pageFrames[page] ?? const <int>[])
          if (_decided[f] && _holds(_requires[f], g)) _node(f, g),
      ];

  final _unsaidCache = <String, List<List<int>?>>{};

  late final List<List<int>?> _outCache = List.filled(_nodeCount, null);
  late final List<List<int?>?> _popCache = List.filled(_nodeCount, null);

  /// The edges that can happen at [node].
  List<int> _outs(int node) {
    if (_isShell(node)) return _outs(_plain(node));
    return _outCache[node] ??= () {
      final f = _frameOf(node);
      final g = _gOf(node);
      return [
        for (final i in _byFrom[_frames[f].page] ?? const <int>[])
          if (edges[i].can(_frames[f].state) && _guarded(_guards[i], g)) i,
      ];
    }();
  }

  /// What takes [node] off the stack: its back (null), where nothing written
  /// is done by the back there, and its written pops. Its back first, so
  /// that of routes as short a back is taken over an action (deleting).
  List<int?> _pops(int node) {
    if (_isShell(node)) return _pops(_plain(node));
    return _popCache[node] ??= () {
      final out = _outs(node);
      return [
        if (!out.any((i) => edges[i].back)) null,
        for (final i in out)
          if (edges[i].move == RouteMove.pop) i,
      ];
    }();
  }

  /// The nodes, of canonical frames, the edge [i] arrives at from [node]:
  /// none where it would change the values held. Each once: they are of the
  /// state it leaves and the values, the canonical node's.
  List<int> _arrive(int i, int node) =>
      _arriveCache[i * _canonCount + _plain(node)] ??= [
        for (final n in _arriving(i, node))
          if (_keeps(n)) n,
      ];

  final _arriveCache = <int, List<int>>{};

  List<int> _arriving(int i, int node) {
    final e = edges[i];
    final state = _frames[_frameOf(node)].state;
    final g = _apply(_sets[i], _gOf(node));
    final then = e.thenBy[state] ?? e.then;
    if (then != null) {
      final t = _frame(e.to, then);
      return [if (t != null) _node(t, _apply(_requires[t], g))];
    }
    final kept = _frame(e.to, state);
    if (kept != null && _holds(_requires[kept], g)) return [_node(kept, g)];
    return _unsaid(e.to, g);
  }

  /// What the transition [move], arriving at [h], does from a page in the
  /// tab [tab]'s history (null: in none, over a bar or out of one).
  _Effect _effect(RouteMove move, int? tab, int h) => switch (move) {
    RouteMove.reset => _Effect.reset,
    RouteMove.pop => _Effect.pop,
    _ when tab != null && !_inTab(_frames[_frameOf(h)].page, tab) =>
      _Effect.overBar,
    RouteMove.push => _Effect.push,
    RouteMove.replace => _Effect.replace,
  };

  /// [h], of a canonical frame, put in the tab [tab]'s history past the
  /// bound, as a push or a replace by a page shown in it puts it there from
  /// a page in it; null, where it is.
  int _put(int h, int? tab) =>
      tab == null ? h : _node(_deep[(_frameOf(h), tab)]!, _gOf(h));

  /// The nodes that take [below]'s place (its frame read; the conditions
  /// are the top's) when [top] is taken off by the pop [j] (null: the
  /// back). Under a shell, its tab shown's top is what is landed on. Each
  /// once: a summary is left again onto the same frames many times.
  List<int> _land(int below, int top, int? j) {
    // A frame's are of its frame alone: the values are the top's.
    final b = _isShell(below) ? below : _frameOf(below);
    final key = (b * _nodeCount + top) * (edges.length + 1) + (j ?? -1) + 1;
    return _landCache[key] ??= _landed(below, top, j);
  }

  final _landCache = <int, List<int>>{};

  List<int> _landed(int below, int top, int? j) {
    if (_isShell(below)) {
      final s = _shellAt(below);
      final stack = s.stacks[_tabPos[s.active]];
      return [
        for (final l in _landOn(stack.last, top, j))
          _withStack(s, [
            ...stack.take(stack.length - 1),
            _frameOf(l),
          ], _gOf(l)),
      ];
    }
    // In a tab's history past the bound, whatever the page (as within the
    // bound): each page a pop lands on has a frame in each tab.
    final t = _frameTab[_frameOf(below)];
    return [
      for (final l in _landOn(_frameOf(below), top, j))
        t == null ? l : _node(_deep[(_frameOf(l), t)] ?? _frameOf(l), _gOf(l)),
    ];
  }

  /// The nodes, of canonical frames, landed on in place of the frame
  /// [under] when [top] is taken off by [j]: none where it would change the
  /// values held.
  List<int> _landOn(int under, int top, int? j) => [
    for (final n in _landing(under, top, j))
      if (_keeps(n)) n,
  ];

  List<int> _landing(int under, int top, int? j) {
    final own = _canon[under];
    final page = _frames[own].page;
    final state = _frames[_frameOf(top)].state;
    var g = _gOf(top);
    if (j != null) {
      final e = edges[j];
      // A pop to another page than the one under it: the sheet's word; a
      // pop back to the page under it, written for another, not here.
      if (e.to != page) return e.under ? const [] : _arrive(j, top);
      g = _apply(_sets[j], g);
      final then = e.thenBy[state] ?? e.then;
      final t = then == null ? null : _frame(page, then);
      if (t != null) return [_node(t, _apply(_requires[t], g))];
    }
    final kept = _frame(page, state);
    if (kept != null && _holds(_requires[kept], g)) return [_node(kept, g)];
    if (_holds(_requires[own], g)) return [_node(own, g)];
    return _unsaid(page, g);
  }

  /// The page each page's route is nested under, where it has one.
  late final Map<String, String> _parents = {
    for (final p in pages) p.id: ?p.parent,
  };

  /// The nodes, of canonical frames, the back of [node] arrives at with
  /// nothing under it: its page's parent, in the state of the name it left
  /// if the conditions allow it, else as nothing says; none without a
  /// parent, or where something written is done by its back.
  List<int> _toParent(int node) {
    final parent = _parents[_frames[_frameOf(node)].page];
    if (parent == null || !_pops(node).contains(null)) return const [];
    final g = _gOf(node);
    final kept = _frame(parent, _frames[_frameOf(node)].state);
    if (kept != null && _holds(_requires[kept], g)) return [_node(kept, g)];
    return _unsaid(parent, g);
  }

  /// Where [top], with nothing under it, goes by its pop [j] (null: its
  /// back), from the tab [tab]'s history (null: from none): a written pop
  /// where it names; the back, and a pop back to the page under it written
  /// for the page's parent, to that parent, as go_router builds it under
  /// it (the pop's `then` and `set` its own). Alone in that tab's history
  /// where its page is shown in the tab; else a pop's page out of any bar,
  /// and the parent as a go from nowhere puts it.
  List<_Alone> _alone(int top, int? j, int? tab) {
    bool stays(int h) => tab != null && _inTab(_frames[_frameOf(h)].page, tab);
    final List<int> parent;
    if (j == null) {
      parent = _toParent(top);
    } else if (!edges[j].under) {
      return [for (final h in _arrive(j, top)) (node: h, stays: stays(h))];
    } else if (edges[j].to == _parents[_frames[_frameOf(top)].page]) {
      parent = _arrive(j, top);
    } else {
      return const [];
    }
    return [
      for (final h in parent)
        stays(h)
            ? (node: h, stays: true)
            : (node: _startAt(h, -1), stays: false),
    ];
  }

  /// The nodes the tab [t] shows first under [g]: its first page, as
  /// nothing says.
  List<int> _tabFirst(int t, int g) => _unsaid(_tabRoots[t], g);

  /// The nodes a switch to the tab [t] lands on under [g], the tab left at
  /// [frame] (null: not opened yet, its first page): that page, in its
  /// state if [g] allows it, else as nothing says.
  List<int> _switchTo(int t, int? frame, int g) {
    if (frame == null) return _tabFirst(t, g);
    if (_holds(_requires[frame], g)) return [_node(frame, g)];
    return _unsaid(_frames[frame].page, g);
  }

  /// Whether tapping the tab [t] shown again, under [g], goes back to its
  /// first page: the bar says so, the conditions let the tab be switched
  /// to, and [top] is not that page with nothing under it in the tab
  /// ([alone]).
  bool _retaps(int t, int g, {required int top, required bool alone}) =>
      tabBars[_tabBar[t]].retapFirst &&
      _guarded(_tabGuards[t], g) &&
      (!alone || _frames[_frameOf(top)].page != _tabRoots[t]);

  /// Where the app launches: its first page, in the first state its first
  /// values (and those held) allow, in its tab if it is in one.
  int get _launch {
    final first = pages.first;
    final unsaid = _unsaid(first.id, _first);
    final f = _pageFrames[first.id]!.first;
    return _startAt(
      unsaid.isNotEmpty ? unsaid.first : _node(f, _apply(_requires[f], _first)),
      -1,
    );
  }

  /// The canonical nodes: the canonical frames come first.
  late final int _canonCount =
      _pageFrames.values.fold(0, (s, f) => s + f.length) * _valuations;

  /// What the app shows with the histories not followed ([_Unfollowed]),
  /// its moves kept, from each stack searched from that has nothing under
  /// it (the launch, a page alone): the bound the search is pruned by.
  late final _Unfollowed _bound = _Unfollowed(this, recording: true);

  /// The bound's distances to each page, and the [_Unfollowed.version]
  /// they are of.
  final _towardPage = <String, (int, List<int>)>{};

  /// A bound below the steps from a search's node (its top, and the shell
  /// at the bottom, or -1) to one [done] holds of, as the search from
  /// [stack] ([alone]: a stack with nothing under it, which the bound then
  /// starts from too) reaches them: the fewest moves of [_bound] to one;
  /// -1 where none leads. Every step of the search is one of its moves, so
  /// that no step lowers it by more than its own (pinned by [boundBroken]),
  /// and it holds whatever the tabs' bound. [to], the page [done] is of.
  int Function(int node, int shell) _toward(
    List<int> stack,
    bool Function(int node) done, {
    bool alone = false,
    String? to,
  }) {
    final bound = _bound;
    if (alone) bound.addStarts(stack);
    final List<int> dist;
    final known = to == null ? null : _towardPage[to];
    if (known != null && known.$1 == bound.version) {
      dist = known.$2;
    } else {
      dist = bound.distances(done);
      if (to != null) _towardPage[to] = (bound.version, dist);
    }
    return (node, shell) {
      final id = bound.find(node, shell);
      return id == null ? 0 : dist[id];
    };
  }

  /// The levels the search enters, summarised as first needed.
  late final _Summaries _summaries = _Summaries(this);

  /// The search from [stack] (its top last) and from each of [alone] (a
  /// node with nothing under it): over (the top, how many of the stack's
  /// frames are under it, and the shell at the bottom or -1), and over the
  /// levels pushed above it that are not left again ([_pushedLevel]). It
  /// stops at the first node [done] holds of ([ties]: once it has taken
  /// every node [done] holds of in as few steps), and gives what it
  /// reached, each with what it was reached from and by, those nodes, the
  /// fewest steps a route through a page past a tab's bound would take at
  /// least (the steps to it and the bound from it: `deep`), and whether it
  /// stopped short, at [searchLimit] nodes taken. Each step it relaxes is
  /// told to [onStep] (the steps it takes).
  ({Map<_At, (_At?, _Hop?)> seen, List<_At> ends, int? deep, bool short})
  _explore(
    List<int> stack,
    bool Function(int node) done, {
    List<int> alone = const [],
    int Function(int node, int shell)? toward,
    bool limited = true,
    int? below,
    bool ties = false,
    void Function(_At from, int steps, _At to)? onStep,
  }) {
    // A*: the fewest steps so far and, from [toward], a bound below those
    // left, which no step lowers by more than its own (so a node is first
    // taken at its fewest); a node from which none leads is not taken.
    int bound(int top, int shell) => toward == null ? 0 : toward(top, shell);
    final heap = _Heap<(int, _At, _At?, _Hop?)>();
    final seen = <_At, (_At?, _Hop?)>{};
    // The fewest steps a node is in the heap with: one no fewer is not
    // pushed again; with [ties], one as few is, if it has more frames.
    final best = <_At, int>{};
    // With [ties]: what each node in the heap is reached from and by, and
    // the frames on the stack then. A node is reached the same way past it
    // whatever is under its level, so the most frames at a node are the
    // most at the end. Of those as near, the nearer is taken first, so a
    // node is taken after every way to it in as few steps.
    final via = <_At, (_At, _Hop, int)>{};
    int framesBy(_At from, _Hop how) =>
        _flat(_replay(stack, [..._path(seen, from), ..._open(how)]).$1).length;
    int? deep;
    // Whether [stack]'s first k frames hold one past a tab's bound.
    final pastUnder = [false];
    for (final n in stack) {
      pastUnder.add(pastUnder.last || _frameTab[_frameOf(n)] != null);
    }
    // Whether the tab shown's history goes on past the bound at [top],
    // [under] of the stack's frames under it: [top] is in it, or is over a
    // frame that is.
    bool past(int top, int under) =>
        _frameTab[_frameOf(top)] != null ||
        under == _abovePast ||
        (under > 0 && pastUnder[under]);
    // The steps to the node being taken.
    var taken = 0;
    void relax(int d, int top, int under, int shell, _At from, _Hop how) {
      if (_isShell(top)) shell = top;
      final next = (top: top, under: under, shell: shell);
      onStep?.call(from, d - taken, next);
      final left = bound(top, shell);
      // None leads on, or none in fewer than [below] steps.
      if (left < 0 || (below != null && d + left >= below)) return;
      // Past a tab's bound: a switch from here, which is not followed,
      // might lead on in no fewer steps than the bound says.
      if (_frameTab[_frameOf(top)] != null &&
          (deep == null || d + left < deep!)) {
        deep = d + left;
      }
      if (seen.containsKey(next)) return;
      final b = best[next];
      if (b != null && (b < d || (b == d && !ties))) return;
      if (ties) {
        final frames = framesBy(from, how);
        if (b == d && frames <= via[next]!.$3) return;
        via[next] = (from, how, frames);
      }
      best[next] = d;
      heap.push(d + left, (d, next, from, how), tie: d);
    }

    if (stack.isNotEmpty) {
      final bottom = _isShell(stack.first) ? stack.first : -1;
      final left = bound(stack.last, bottom);
      if (stack.any((n) => _frameTab[_frameOf(n)] != null) && left >= 0) {
        deep = left;
      }
      if (left >= 0) {
        heap.push(left, (
          0,
          (top: stack.last, under: stack.length - 1, shell: bottom),
          null,
          null,
        ));
      }
    }
    for (final node in alone) {
      final shell = _isShell(node) ? node : -1;
      final left = bound(node, shell);
      if (left < 0) continue;
      heap.push(left, (0, (top: node, under: 0, shell: shell), null, null));
    }
    final ends = <_At>[];
    // The steps to the first node [done] holds of.
    int? fewest;
    while (heap.isNotEmpty) {
      final (key, (d, at, from, how)) = heap.pop();
      // Each node [done] holds of in as few steps as the first is taken by
      // now: the bound is no more than the steps left.
      if (fewest != null && key > fewest) break;
      if (seen.containsKey(at)) continue;
      final (byFrom, byHow, _) = via[at] ?? (from, how, 0);
      seen[at] = from == null ? (null, null) : (byFrom, byHow);
      final (:top, :under, :shell) = at;
      if (done(top)) {
        ends.add(at);
        if (!ties) break;
        fewest = d;
        continue;
      }
      if (limited && seen.length >= searchLimit) {
        return (seen: seen, ends: ends, deep: deep, short: ends.isEmpty);
      }
      taken = d;
      if (_isShell(top)) {
        _shellMoves(d, at, relax);
        continue;
      }
      final g = _gOf(top);
      final tab = _frameTab[_frameOf(top)];
      final isPast = past(top, under);
      for (final i in _outs(top)) {
        final e = edges[i];
        for (final h in _arrive(i, top)) {
          switch (_effect(e.move, tab, h)) {
            case _Effect.pop:
              continue;
            case _Effect.reset:
              // Past the bound, the tab shown is not left by a go to another
              // tab of its bar, from a page in its history or over it: that
              // history would have to be kept.
              final to = _startAt(h, shell, named: e.tab);
              if (isPast &&
                  _isShell(to) &&
                  _shellAt(to).bar == _shellAt(shell).bar &&
                  _shellAt(to).active != _shellAt(shell).active) {
                continue;
              }
              // Out of the bar, its histories are gone.
              relax(d + 1, to, 0, -1, at, _Step(_Op.reset, i, to));
            case _Effect.replace:
              final to = _put(h, tab);
              relax(d + 1, to, under, shell, at, _Step(_Op.replace, i, to));
            case _Effect.push:
              _push(d, at, i, _put(h, tab), relax, past: isPast);
            case _Effect.overBar:
              _push(d, at, i, h, relax, past: isPast);
          }
        }
      }
      // Past the bound in the tab shown, tapping it again.
      if (tab != null && shell >= 0) {
        final s = _shellAt(shell);
        if (tab == s.active && _retaps(tab, g, top: top, alone: false)) {
          for (final x in _tabFirst(tab, g)) {
            final to = _withStack(s, [_frameOf(x)], _gOf(x));
            relax(
              d + 1,
              to,
              0,
              shell,
              at,
              _Step(_Op.reset, null, to, _Do.retap),
            );
          }
        }
      }
      if (under > 0) {
        for (final j in _pops(top)) {
          for (final l in _land(stack[under - 1], top, j)) {
            relax(d + 1, l, under - 1, shell, at, _Step(_Op.pop, j, l));
          }
        }
      } else if (under == 0) {
        // Nothing under it, out of any bar.
        for (final j in _pops(top)) {
          for (final (:node, stays: _) in _alone(top, j, null)) {
            relax(
              d + 1,
              node,
              0,
              -1,
              at,
              j == null
                  ? _Step(_Op.reset, null, node, _Do.back)
                  : _Step(_Op.pop, j, node),
            );
          }
        }
      }
    }
    return (seen: seen, ends: ends, deep: deep, short: false);
  }

  /// From [at] after [d]: the push by [i] of [h], and each summary of it
  /// left again; [past]: from a page in a tab's history past the bound, or
  /// over one.
  void _push(int d, _At at, int i, int h, _Relax relax, {bool past = false}) {
    final (:top, :under, :shell) = at;
    relax(
      d + 1,
      h,
      past ? _abovePast : _pushedLevel,
      shell,
      at,
      _Step(_Op.push, i, h),
    );
    for (final MapEntry(key: left, value: steps)
        in _summaries.dist(h).entries) {
      for (final j in _pops(left)) {
        for (final l in _land(top, left, j)) {
          relax(d + steps + 2, l, under, shell, at, _Summary(i, h, left, j, l));
        }
      }
    }
  }

  /// The moves of the shell [at] shows (its tab's top): what the page does,
  /// in the tab's history within the bound, its back, a switch to another
  /// tab, and tapping it again.
  void _shellMoves(int d, _At at, _Relax relax) {
    final shell = at.top;
    final s = _shellAt(shell);
    final tab = s.active;
    final history = s.stacks[_tabPos[tab]];
    final g = s.g;
    void become(int to, int? edge, [_Do does = _Do.edge]) =>
        relax(d + 1, to, 0, shell, at, _Step(_Op.replace, edge, to, does));
    for (final i in _outs(shell)) {
      final e = edges[i];
      for (final h in _arrive(i, shell)) {
        switch (_effect(e.move, tab, h)) {
          case _Effect.pop:
            continue;
          case _Effect.reset:
            final to = _startAt(h, shell, named: e.tab);
            relax(d + 1, to, 0, -1, at, _Step(_Op.reset, i, to));
          case _Effect.overBar:
            _push(d, at, i, h, relax);
          case _Effect.replace:
            become(
              _withStack(s, [
                ...history.take(history.length - 1),
                _frameOf(h),
              ], _gOf(h)),
              i,
            );
          case _Effect.push when history.length < _depth:
            become(_withStack(s, [...history, _frameOf(h)], _gOf(h)), i);
          case _Effect.push:
            _push(d, at, i, _put(h, tab), relax);
        }
      }
    }
    for (final j in _pops(shell)) {
      final does = j == null ? _Do.back : _Do.edge;
      if (history.length >= 2) {
        for (final l in _landOn(history[history.length - 2], shell, j)) {
          become(
            _withStack(s, [
              ...history.take(history.length - 2),
              _frameOf(l),
            ], _gOf(l)),
            j,
            does,
          );
        }
        continue;
      }
      // Nothing under the tab's page: in the tab if its page is in it.
      for (final (:node, :stays) in _alone(shell, j, tab)) {
        if (stays) {
          become(_withStack(s, [_frameOf(node)], _gOf(node)), j, does);
        } else {
          relax(d + 1, node, 0, -1, at, _Step(_Op.reset, j, node, does));
        }
      }
    }
    for (final t in _barTabs[s.bar]) {
      if (t == tab || !_guarded(_tabGuards[t], g)) continue;
      final left = s.stacks[_tabPos[t]];
      for (final x in _switchTo(t, left.isEmpty ? null : left.last, g)) {
        become(
          _withStack(
            s,
            [if (left.isNotEmpty) ...left.take(left.length - 1), _frameOf(x)],
            g,
            active: t,
          ),
          null,
          _Do.tab,
        );
      }
    }
    if (_retaps(tab, g, top: shell, alone: history.length == 1)) {
      for (final x in _tabFirst(tab, g)) {
        become(_withStack(s, [_frameOf(x)], g), null, _Do.retap);
      }
    }
  }

  /// The fewest steps from [stack] (its top last) to a node [done] holds
  /// of; null when none reaches one; the fewest steps a route through a page
  /// past a tab's bound would take at least (none found: one might be past
  /// it); whether
  /// the search stopped short; the stack searched from; and, none found but
  /// one might be, the fewest steps that one would take. [alone] and [to]
  /// as [_toward] has them; [fullest]: of the routes of the fewest steps,
  /// the one that ends with the most frames on the stack (a page reached
  /// over the pages it is pushed from, its back theirs, rather than gone
  /// to), whatever order the search takes them in; else the first.
  ///
  /// None found within the bound, but one might be past it: it is searched
  /// for once more, the bound raised by [tabDepth] over the deepest history
  /// at the start, or over [tabDepth] where that is less. A route found is the fewest of all: when a switch past
  /// the bound might have been shorter, it is searched again among routes
  /// of fewer steps, with the bound raised to the deepest history at the
  /// start and the steps found (none of fewer steps puts more pages in a
  /// tab than that); each from [stack] with the pages past the bound in the
  /// tab shown taken into it, the stack searched from given too.
  ({List<_Step>? steps, int? deep, bool short, List<int> stack, int? atLeast})
  _search(
    List<int> stack,
    bool Function(int node) done, {
    bool alone = false,
    String? to,
    bool fullest = false,
  }) {
    final toward = _toward(stack, done, alone: alone, to: to);
    final deepest = _deepest(stack);
    final base = deepest > tabDepth ? deepest : tabDepth;
    // The steps of the route found from [from], as [fullest] says.
    List<_Step> pathOf(
      ({Map<_At, (_At?, _Hop?)> seen, List<_At> ends, int? deep, bool short})
      found,
      List<int> from,
    ) {
      List<_Step>? best;
      var most = -1;
      for (final end in found.ends) {
        final steps = _path(found.seen, end);
        final frames = _flat(_replay(from, steps).$1).length;
        if (frames > most) (best, most) = (steps, frames);
      }
      return best!;
    }

    var found = _explore(stack, done, toward: toward, ties: fullest);
    var searched = stack;
    if (found.ends.isEmpty) {
      final deep = found.deep;
      // Stopped short; or none at all, past the bound neither.
      if (found.short || deep == null) {
        return (
          steps: null,
          deep: deep,
          short: found.short,
          stack: stack,
          atLeast: null,
        );
      }
      final atLeast = _atLeast(deep, deepest);
      _depth = base + tabDepth;
      try {
        searched = _deepen(stack);
        found = _explore(searched, done, toward: toward, ties: fullest);
        if (found.ends.isEmpty) {
          // Still none: what this search proves, if it went to the end; if
          // it found none past its bound either, there is none at all.
          final deeper = found.deep;
          if (found.short) {
            return (
              steps: null,
              deep: deep,
              short: false,
              stack: stack,
              atLeast: atLeast,
            );
          }
          final more = deeper == null ? 0 : _atLeast(deeper, deepest);
          return (
            steps: null,
            deep: deeper,
            short: false,
            stack: stack,
            atLeast: deeper == null ? null : (more > atLeast ? more : atLeast),
          );
        }
      } finally {
        _depth = tabDepth;
      }
    }
    final steps = pathOf(found, searched);
    if (found.deep == null || found.deep! >= steps.length) {
      return (
        steps: steps,
        deep: null,
        short: false,
        stack: searched,
        atLeast: null,
      );
    }
    _depth = base + steps.length;
    try {
      final deeper = _deepen(stack);
      final again = _explore(
        deeper,
        done,
        toward: toward,
        below: steps.length,
        ties: fullest,
      );
      if (again.ends.isNotEmpty) {
        return (
          steps: pathOf(again, deeper),
          deep: null,
          short: false,
          stack: deeper,
          atLeast: null,
        );
      }
      return (
        steps: steps,
        deep: null,
        short: again.short,
        stack: searched,
        atLeast: null,
      );
    } finally {
      _depth = tabDepth;
    }
  }

  /// The fewest steps a route past the bound [_depth] takes, the search
  /// within it from a stack whose deepest history holds [deepest] pages
  /// having gone to the end with none found and said [deep]: no fewer than
  /// that (a step it does not follow is from a page past the bound, which
  /// it says leads on in no fewer); nor than the pushes that put a page
  /// past the bound, each a step, and the step from there.
  int _atLeast(int deep, int deepest) {
    final pushes = _depth + 2 - deepest;
    return deep > pushes ? deep : pushes;
  }

  /// The steps to [end] in [seen].
  List<_Step> _path(Map<_At, (_At?, _Hop?)> seen, _At end) {
    final steps = <_Step>[];
    for (var at = end; seen[at]!.$1 != null; at = seen[at]!.$1!) {
      steps.insertAll(0, _open(seen[at]!.$2!));
    }
    return steps;
  }

  /// The most pages any tab's history in [stack] holds: the tab shown's
  /// counted with those past the bound over the shell.
  int _deepest(List<int> stack) {
    if (stack.isEmpty || !_isShell(stack.first)) return 0;
    final s = _shellAt(stack.first);
    var most = 0;
    for (final history in s.stacks) {
      if (history.length > most) most = history.length;
    }
    final shown =
        s.stacks[_tabPos[s.active]].length +
        stack
            .skip(1)
            .takeWhile((n) => _frameTab[_frameOf(n)] == s.active)
            .length;
    return shown > most ? shown : most;
  }

  /// [stack] with the frames over its shell in the tab shown's history
  /// past the bound taken into that history, as far as [_depth] allows.
  List<int> _deepen(List<int> stack) {
    if (stack.length < 2 || !_isShell(stack.first)) return stack;
    final s = _shellAt(stack.first);
    final history = [...s.stacks[_tabPos[s.active]]];
    var i = 1;
    while (i < stack.length &&
        history.length < _depth &&
        _frameTab[_frameOf(stack[i])] == s.active) {
      history.add(_canon[_frameOf(stack[i])]);
      i++;
    }
    if (i == 1) return stack;
    return [_withStack(s, history, _gOf(stack.last)), ...stack.skip(i)];
  }

  /// The bound a search keeps tabs' histories within: [tabDepth], raised
  /// while a route is searched again.
  late int _depth = tabDepth;

  /// A summary opened into its push, the steps above it, and its pop.
  List<_Step> _open(_Hop hop) => switch (hop) {
    final _Step step => [step],
    final _Summary s => [
      _Step(_Op.push, s.edge, s.entered),
      ..._within(s.entered, s.left),
      _Step(_Op.pop, s.pop, s.landed!),
    ],
  };

  /// The steps at the level [level] entered from it to [node].
  List<_Step> _within(int level, int node) {
    final out = <_Step>[];
    for (var at = node; at != level;) {
      final via = _summaries.via(level, at)!;
      final summary = via.summary;
      out.insertAll(
        0,
        summary == null
            ? [_Step(_Op.replace, via.edge, at)]
            : _open(summary.landing(at)),
      );
      at = via.from;
    }
    return out;
  }

  /// [stack] after [steps], and the stack before each.
  (List<int>, List<List<int>>) _replay(List<int> stack, List<_Step> steps) {
    final s = [...stack];
    final before = <List<int>>[];
    for (final step in steps) {
      before.add([...s]);
      switch (step.op) {
        case _Op.push:
          s.add(step.node);
        case _Op.replace:
          s.last = step.node;
        case _Op.reset:
          s
            ..clear()
            ..add(step.node);
        case _Op.pop:
          s.removeLast();
          if (s.isEmpty) {
            s.add(step.node);
          } else {
            s.last = step.node;
          }
      }
    }
    return (s, before);
  }

  /// The history a route from [from] starts with: the stack the fewest steps
  /// from the app's launch reach it with, in [state] when it has one of
  /// that name, under the conditions' values [chosen] names; a page the
  /// launch does not reach so, alone (in its tab, if it is in one), under
  /// the launch's values but those [chosen] and its state name. With it,
  /// whether the search stopped short, whether a switch from past a tab's
  /// bound might have reached it, and whether it is alone. Of the stacks
  /// the fewest steps reach it with, the one with the most frames.
  _Start _start(String from, String? state, Map<String, String> chosen) =>
      _starts[[
        from,
        '$state',
        for (final (c, v) in _values(chosen)) '$c=$v',
      ].join('\u0000')] ??= _startOf(
        from,
        state,
        chosen,
      );

  /// The starts found, by page, state and values: one for every route from
  /// them.
  final _starts = <String, _Start>{};

  _Start _startOf(String from, String? state, Map<String, String> chosen) {
    final named = state == null ? null : _frame(from, state);
    // The state's own values win over those chosen.
    final want = [
      for (final v in _values(chosen))
        if (named == null || !_requires[named].any((r) => r.$1 == v.$1)) v,
    ];
    final found = _search([_launch], alone: true, fullest: true, (n) {
      final f = _canon[_frameOf(n)];
      return _frames[f].page == from &&
          (named == null || f == named) &&
          _holds(want, _gOf(n));
    });
    if (found.steps case final steps?) {
      return (
        stack: _replay(found.stack, steps).$1,
        short: false,
        bounded: false,
        alone: false,
      );
    }
    // Not reached within the bound: alone, unless a switch from past it
    // might have reached it.
    final bounded = found.deep != null;
    final g = _apply(want, _first);
    _Start alone(int node) => (
      stack: [_startAt(node, -1)],
      short: found.short,
      bounded: bounded,
      alone: true,
    );
    if (named != null) return alone(_node(named, _apply(_requires[named], g)));
    final unsaid = _unsaid(from, g);
    if (unsaid.isNotEmpty) return alone(unsaid.first);
    final f = _pageFrames[from]!.first;
    return alone(_node(f, _apply(_requires[f], g)));
  }

  /// The frames [stack] holds, bottom first: a shell's tab shown's history.
  List<RouteFrame> _flat(List<int> stack) => [
    for (final n in stack)
      if (_isShell(n))
        for (final f in _shellAt(n).stacks[_tabPos[_shellAt(n).active]])
          _frames[f]
      else
        _frames[_frameOf(n)],
  ];

  /// The tab shown at the top of [stack], by its first page, if one is.
  String? _shownTab(List<int> stack) {
    final top = stack.last;
    if (_isShell(top)) return _tabRoots[_shellAt(top).active];
    final t = _frameTab[_frameOf(top)];
    return t == null ? null : _tabRoots[t];
  }

  /// The fewest steps from [from] (in [state], under the conditions' values
  /// [valuation] names, else as the app's launch reaches it) to [to].
  Route route(
    String from,
    String? state,
    String to, [
    Map<String, String> valuation = const {},
  ]) {
    final started = _start(from, state, valuation);
    final found = from == to
        ? (
            steps: <_Step>[],
            deep: null,
            short: false,
            stack: started.stack,
            atLeast: null,
          )
        : _search(
            started.stack,
            alone: started.alone,
            to: to,
            (n) => _frames[_frameOf(n)].page == to,
          );
    final (:steps, :deep, :short, :stack, :atLeast) = found;
    final searched = !short && !started.short;
    final shell = _isShell(stack.first) ? _shellAt(stack.first) : null;
    final start = _flat(stack);
    final values = _named(_gOf(stack.last));
    final active = shell == null ? null : _tabRoots[shell.active];
    final inTab = shell?.stacks[_tabPos[shell.active]].length ?? 0;
    final pastBound = shell == null
        ? 0
        : stack
              .skip(1)
              .takeWhile((n) => _frameTab[_frameOf(n)] == shell.active)
              .length;
    final tabs = [
      if (shell != null)
        for (final t in _barTabs[shell.bar])
          if (t != shell.active && shell.stacks[_tabPos[t]].isNotEmpty)
            (
              page: _tabRoots[t],
              frames: [for (final f in shell.stacks[_tabPos[t]]) _frames[f]],
            ),
    ];
    // Past a tab's bound, a switch might have made it shorter, or have
    // reached the start some other way.
    final bounded =
        started.bounded ||
        (deep != null && (steps == null || deep < steps.length));
    if (steps == null) {
      return Route(
        start,
        null,
        valuation: values,
        active: active,
        inTab: inTab,
        pastBound: pastBound,
        tabs: tabs,
        bounded: bounded,
        atLeast: atLeast,
        searched: searched,
      );
    }
    final (end, before) = _replay(stack, steps);
    final after = [...before.skip(1), end];
    return Route(
      start,
      valuation: values,
      active: active,
      inTab: inTab,
      pastBound: pastBound,
      tabs: tabs,
      bounded: bounded,
      searched: searched,
      [
        for (final (n, s) in steps.indexed)
          RouteStep(
            s.edge,
            from: _frames[_frameOf(before[n].last)],
            to: _frames[_frameOf(after[n].last)],
            sets: _changed(_gOf(before[n].last), _gOf(after[n].last)),
            move: switch (s.does) {
              _Do.tab => 'switch',
              _Do.retap => 'retap',
              _ when s.edge == null => 'back',
              _ => 'edge',
            },
            tab: _shownTab(after[n]),
          ),
      ],
    );
  }

  /// For the tests: whether the bound the search is pruned by ([_toward])
  /// holds on the search from [from] (in [state]) as [route] starts it, as
  /// far as [searchLimit] nodes, unpruned. It holds when each node the
  /// search reaches has a node in [_bound]; and, for each page, the bound to
  /// it is 0 where the page is, and no step the search takes lowers it by
  /// more than the step's own (none from a node it says none leads on from
  /// to one it says some does). Then the search, pruned by it, takes each
  /// node at its fewest, and drops none a route goes through. What fails,
  /// said; empty when it holds.
  List<String> boundBroken(String from, String? state) {
    final started = _start(from, state, const {});
    final stack = started.stack;
    final towards = [
      for (final p in pages)
        (
          page: p.id,
          bound: _toward(
            stack,
            (n) => _frames[_frameOf(n)].page == p.id,
            alone: started.alone,
            to: p.id,
          ),
        ),
    ];
    final broken = <String>[];
    String said(_At at) {
      final f = _frames[_frameOf(at.top)];
      final tab = _frameTab[_frameOf(at.top)];
      final where = _isShell(at.top)
          ? 'in tab ${_tabRoots[_shellAt(at.top).active]}'
          : tab != null
          ? 'in tab ${_tabRoots[tab]} past the bound'
          : at.shell >= 0
          ? 'over the bar'
          : 'in no bar';
      return '${f.page}:${f.state} ${_named(_gOf(at.top))} $where '
          '(${at.under})';
    }

    void check(_At at) {
      if (_bound.find(at.top, at.shell) == null) {
        broken.add('no node for ${said(at)}');
      }
      final page = _frames[_frameOf(at.top)].page;
      for (final t in towards) {
        if (t.page == page && t.bound(at.top, at.shell) != 0) {
          broken.add('to ${t.page}: not 0 at ${said(at)}');
        }
      }
    }

    final bottom = _isShell(stack.first) ? stack.first : -1;
    check((top: stack.last, under: stack.length - 1, shell: bottom));
    _explore(
      stack,
      (_) => false,
      onStep: (from, steps, to) {
        check(to);
        for (final t in towards) {
          final before = t.bound(from.top, from.shell);
          final after = t.bound(to.top, to.shell);
          if (after >= 0 && (before < 0 || before > steps + after)) {
            broken.add(
              'to ${t.page}: ${said(from)} at $before, by $steps step(s) '
              'to ${said(to)} at $after',
            );
          }
        }
      },
    );
    return broken;
  }

  /// The states of the edge [i]'s `to` it can arrive in, by the state of
  /// its `from` it leaves (those its `when` names, else all), under any
  /// values of the conditions it can happen while; empty for a state no
  /// such values allow.
  ///
  /// A pop back to the page under it lands as the route does: in the state
  /// that page can be in under it, unless the pop or the conditions say
  /// another; a pop that names its page may land elsewhere too.
  Map<String, List<String>> arrivals(int i) {
    final e = edges[i];
    return {
      for (final f in _pageFrames[e.from] ?? const <int>[])
        if (e.can(_frames[f].state))
          _frames[f].state: _states([
            for (var g = 0; g < _valuations; g++)
              if (_holds(_requires[f], g) && _guarded(_guards[i], g))
                ..._lands(i, _node(f, g)),
          ]),
    };
  }

  /// The nodes, of canonical frames, the edge [i] can arrive at from
  /// [node]: a pop back to the page under it on each page it can be over
  /// that is its own, and, naming its page, where it goes.
  List<int> _lands(int i, int node) {
    final e = edges[i];
    if (e.move != RouteMove.pop) return _arrive(i, node);
    return [
      for (final u in _overFrames[e.from] ?? const <int>{})
        if (_frames[u].page == e.to) ..._landOn(u, node, i),
      // Naming its page; or back to its parent, built under it.
      if (!e.under || e.to == _parents[e.from]) ..._arrive(i, node),
    ];
  }

  /// The pages [page] can be put over, as the sheet has them: a pop back to
  /// the page under it, written from [page], goes to each. Its parent among
  /// them: go_router builds it under the page, gone to or opened by a deep
  /// link.
  Set<String> under(String page) => {
    for (final f in _overFrames[page] ?? const <int>{}) _frames[f].page,
    ?_parents[page],
  };

  /// Whether the edge [e], a replace, can put its page over the bar instead
  /// of in its `from`'s place, its `from` kept under it: from a tab's page,
  /// a page not shown in one of its tabs (in that tab, as [_effect] has it).
  bool _replacesOverBar(RouteEdge e) {
    final tabs = [?_rootTab[e.from], ..._inTabs[e.from]!];
    return tabs.any((t) => !_inTab(e.to, t));
  }

  /// The frames each page can be put over, by the rule the sheet draws a
  /// pop back to the page under it by: those a push to it is from (in the
  /// states it happens in); those the page it takes the place of can be
  /// put over (and that page, where a tab's page puts it over the bar
  /// instead, [_replacesOverBar]); for a pop to it, those the pages under
  /// the page popped can be put over.
  late final Map<String, Set<int>> _overFrames = () {
    final over = <String, Set<int>>{};
    List<int> leaving(RouteEdge e) => [
      for (final f in _pageFrames[e.from] ?? const <int>[])
        if (e.can(_frames[f].state)) f,
    ];
    for (var grew = true; grew;) {
      grew = false;
      for (final e in edges) {
        final under = switch (e.move) {
          RouteMove.push => {...leaving(e)},
          RouteMove.replace => {
            if (_replacesOverBar(e)) ...leaving(e),
            ...?over[e.from],
          },
          RouteMove.pop when !e.under => {
            for (final b in over[e.from] ?? const <int>{})
              ...?over[_frames[b].page],
          },
          _ => const <int>{},
        };
        final known = over[e.to] ??= {};
        for (final f in under) {
          if (known.add(f)) grew = true;
        }
      }
    }
    return over;
  }();

  /// The states [page] can open in from outside the app (a deep link): the
  /// one [then] names, else those nothing says under any values the
  /// [guard] allows.
  List<String> opening(
    String page,
    String? then,
    Map<String, List<String>> guard,
  ) {
    if (then != null) return [then];
    final allowed = _guard(guard);
    return _states([
      for (var g = 0; g < _valuations; g++)
        if (_guarded(allowed, g)) ..._unsaid(page, g),
    ]);
  }

  /// The states of [nodes], once each, in their pages' order.
  List<String> _states(List<int> nodes) => [
    for (final f in {for (final n in nodes) _frameOf(n)}.toList()..sort())
      _frames[f].state,
  ];

  /// The edges that can happen on some history: from the app's launch, or
  /// from a deep link into [entries]' pages.
  Set<int> happening(List<RouteEntry> entries) => {
    for (final n in _reached(_origins(entries).starts)) ..._outs(n),
  };

  /// What the app shows while the conditions keep the values [held] names:
  /// the pages, in their states, it reaches from its launch (with those
  /// values) or from a deep link into [entries]' pages that opens while
  /// they are so; the edges that happen between them, arriving without
  /// changing those values; and those deep links.
  ///
  /// The histories are not followed ([_Unfollowed]): a back takes back the
  /// transition that put the page there, a switch to a tab finds it as it
  /// was left (each tab, on its own, where it can be left under the values
  /// meanwhile), so neither shows a page not shown already, only its state
  /// as the values then give. An edge happens from a node it can happen at,
  /// where it arrives; a pop, where it lands.
  RouteShown shown(List<RouteEntry> entries) {
    final (:starts, :opened) = _origins(entries);
    final unfollowed = _Unfollowed(this)..addStarts(starts);
    final reached = {...unfollowed.nodeOf};
    final found = {for (final n in reached) _canon[_frameOf(n)]};
    final frames = found.toList()..sort();
    final states = <String, List<String>>{};
    for (final f in frames) {
      (states[_frames[f].page] ??= []).add(_frames[f].state);
    }
    final happens = {
      ...unfollowed.pops,
      for (final n in reached)
        for (final i in _outs(n))
          if (edges[i].move != RouteMove.pop && _arrive(i, n).isNotEmpty) i,
    };
    return RouteShown(
      states,
      happens.toList()..sort(),
      opened.toList()..sort(),
    );
  }

  /// Where the app's histories start, under the values held: its launch,
  /// unless its first page has no look then; and each deep link of
  /// [entries] (each its page, the state it opens in, the values of the
  /// conditions it opens while, and the tab), under each of those values,
  /// the places of those that open.
  ({Set<int> starts, Set<int> opened}) _origins(List<RouteEntry> entries) {
    final launch = _launch;
    final starts = <int>{if (_keeps(launch)) launch};
    final opened = <int>{};
    for (final (j, entry) in entries.indexed) {
      final allowed = _guard(entry.guard);
      final t = entry.then == null ? null : _frame(entry.to, entry.then!);
      for (var g = 0; g < _valuations; g++) {
        if (!_guarded(allowed, g)) continue;
        for (final n in [
          if (t != null)
            _node(t, _apply(_requires[t], g))
          else
            ..._unsaid(entry.to, g),
        ]) {
          if (!_keeps(n)) continue;
          opened.add(j);
          starts.add(_startAt(n, -1, named: entry.tab));
        }
      }
    }
    return (starts: starts, opened: opened);
  }

  /// The canonical nodes shown on some history from [starts]. With tab
  /// bars, [_Unfollowed]: the histories are not followed (see [shown]).
  Set<int> _reached(Set<int> starts) {
    if (tabBars.isNotEmpty) {
      return {...(_Unfollowed(this)..addStarts(starts)).nodeOf};
    }
    final found = _explore(
      const [],
      (_) => false,
      alone: [...starts],
      limited: false,
    );
    return {for (final at in found.seen.keys) _plain(at.top)};
  }
}

/// A route's start ([Router._start]): its stack, whether its search stopped
/// short, whether one past a tab's bound might have reached it, and whether
/// it is alone, nothing under it, as the launch does not reach it.
typedef _Start = ({List<int> stack, bool short, bool bounded, bool alone});

/// What the search takes a step by ([Router._explore]): its steps so far,
/// the node it reaches, how many of the start's frames are under it, the
/// shell at the bottom (-1 for none), what it is from, and by.
typedef _Relax = void Function(
  int steps,
  int top,
  int under,
  int shell,
  _At from,
  _Hop how,
);

/// A node of the search: the [top]; [under], how many of the start's frames
/// are under it ([_pushedLevel]: a level pushed and not left again;
/// [_abovePast], such a level over a page in a tab's history past the
/// bound); and the [shell] at the bottom (-1 for none).
typedef _At = ({int top, int under, int shell});

/// A level pushed and not left again (see [_At]).
const _pushedLevel = -1;

/// A level pushed and not left again over a page in a tab's history past
/// the bound: the tab shown is not left from it for another (see [_At]).
const _abovePast = -2;

enum _Op { push, replace, reset, pop }

/// What a step does besides its edge: an edge (or, without one, the back),
/// a switch to another tab, tapping the tab shown again.
enum _Do { edge, back, tab, retap }

/// What the search takes a node by: a step, or a summary of a page pushed
/// and left again.
sealed class _Hop {}

class _Step implements _Hop {
  _Step(this.op, this.edge, this.node, [this.does = _Do.edge]);

  final _Op op;
  final int? edge;
  final int node;
  final _Do does;
}

/// The push [edge] entering [entered], the steps at its level to [left],
/// and the [pop] from there landing on [landed].
class _Summary implements _Hop {
  _Summary(this.edge, this.entered, this.left, this.pop, [this.landed]);

  final int edge;
  final int entered;
  final int left;
  final int? pop;
  final int? landed;

  _Summary landing(int node) => _Summary(edge, entered, left, pop, node);
}

/// The step into a node at a level: from [from] by [edge] (a replace), or
/// by a [summary].
class _Via {
  _Via(this.from, {this.edge, this.summary});

  final int from;
  final int? edge;
  final _Summary? summary;
}

/// A node at a level that pushed the node entering another: its [level],
/// the [node], the [steps] to it there, and the [edge] it pushed by.
typedef _Caller = ({int level, int node, int steps, int edge});

/// The summaries of the levels the search enters ([Router._push]): for each
/// node entered (a frame, never a shell), the fewest steps from it to each
/// node at its level, through the pages pushed and popped above it, and the
/// step into each.
///
/// One Dijkstra over all levels (Knuth's: a step out of a pushed page costs
/// more than the steps it is made of), each level put in it when first
/// needed, at the cost it has reached: a level pushed from one starts no
/// earlier than the node that pushed it was taken, so each step still costs
/// more than what it is made of, and each level is exact. A level is needed
/// only with all those it pushes, and goes to the end with them: a level
/// never needed is never summarised.
class _Summaries {
  _Summaries(this.r)
    : _dist = List.filled(r._nodeCount, null),
      _via = List.filled(r._nodeCount, null),
      _best = List.filled(r._nodeCount, null),
      _callers = List.filled(r._nodeCount, null),
      _from = List.filled(r._nodeCount, 0);

  final Router r;

  /// For each level entered: the fewest steps to each node at it, the step
  /// into each, the fewest it is in the heap with (one no fewer is not
  /// pushed again), the nodes that pushed it, and the cost it was put in
  /// the Dijkstra at.
  final List<Map<int, int>?> _dist;
  final List<Map<int, _Via?>?> _via;
  final List<Map<int, int>?> _best;
  final List<List<_Caller>?> _callers;
  final List<int> _from;

  /// By the cost so far: each level's node, its level, and the step into it.
  final _heap = _Heap<(int, int, _Via?)>();

  /// The cost the Dijkstra has reached.
  var _reached = 0;

  /// The fewest steps from [level] to each node at its level.
  Map<int, int> dist(int level) {
    if (_dist[level] == null) {
      _enter(level);
      _run();
    }
    return _dist[level]!;
  }

  /// The step into [node] at [level], summarised.
  _Via? via(int level, int node) => _via[level]![node];

  void _enter(int level) {
    _dist[level] = {};
    _via[level] = {};
    _best[level] = {};
    _callers[level] = [];
    _from[level] = _reached;
    _relax(0, level, level, null);
  }

  void _relax(int d, int level, int node, _Via? via) {
    if (_dist[level]!.containsKey(node)) return;
    final best = _best[level]!;
    final b = best[node];
    if (b != null && b <= d) return;
    best[node] = d;
    _heap.push(_from[level] + d, (level, node, via));
  }

  void _run() {
    while (_heap.isNotEmpty) {
      final (cost, (level, node, via)) = _heap.pop();
      final dist = _dist[level]!;
      if (dist.containsKey(node)) continue;
      _reached = cost;
      final d = cost - _from[level];
      dist[node] = d;
      _via[level]![node] = via;
      final tab = r._frameTab[r._frameOf(node)];
      for (final i in r._outs(node)) {
        final move = r.edges[i].move;
        final caller = (level: level, node: node, steps: d, edge: i);
        for (final h in r._arrive(i, node)) {
          switch (r._effect(move, tab, h)) {
            // Out of the level: not in its summary.
            case _Effect.pop || _Effect.reset:
              continue;
            case _Effect.replace:
              _relax(d + 1, level, r._put(h, tab), _Via(node, edge: i));
            case _Effect.push:
              _pushed(caller, r._put(h, tab));
            case _Effect.overBar:
              _pushed(caller, h);
          }
        }
      }
      for (final j in r._pops(node)) {
        for (final caller in _callers[level]!) {
          _left(caller, level, node, d, j);
        }
      }
    }
  }

  /// [caller] pushing [h]: each node its level is left from, as met.
  void _pushed(_Caller caller, int h) {
    if (_dist[h] == null) _enter(h);
    _callers[h]!.add(caller);
    for (final MapEntry(key: left, value: steps) in _dist[h]!.entries) {
      for (final j in r._pops(left)) {
        _left(caller, h, left, steps, j);
      }
    }
  }

  /// The level [h] [caller] pushed, left from [left] after [steps] by the
  /// pop [j] (null: the back): onto the frame of the caller's node.
  void _left(_Caller caller, int h, int left, int steps, int? j) {
    for (final l in r._land(caller.node, left, j)) {
      _relax(
        caller.steps + steps + 2,
        caller.level,
        l,
        _Via(caller.node, summary: _Summary(caller.edge, h, left, j)),
      );
    }
  }
}

/// What the app shows from some starts, the histories not followed
/// ([Router.shown]); and, its moves kept ([recording]), the bound the
/// route's search is pruned by ([Router._toward]).
///
/// A back is the transition it takes back, a switch finds a tab as it was
/// left, so neither shows a page not shown already; only its state can be
/// another, the one the values give when it is gone back to.
///
/// A node is a page in a state under values, and where it is: in no bar,
/// in a tab's history (the bar shown), or over the bar with a tab under
/// it. Each node keeps what can be under it: the nodes whose transition
/// put it there (a push; a replace keeps what was under the page it
/// replaces; a page gone back to keeps what was under it), or [nothing],
/// where it was put (a go, a deep link, the launch, a tab opened or tapped
/// again, whose back is the go to its parent that go_router builds under
/// it). A back, or a pop back to the page under it, lands only on what is
/// under the page left. On one stack this is exact: what happens over a
/// page depends on the page and the values, never on what is under it.
///
/// Each tab, on its own: the nodes it can be left at (or not opened yet),
/// each with the values there can be while it is left so, and the changes
/// of the values made while it is left. A switch to it lands on a node it
/// is left at under the values now, in the state they give: a tab left as
/// it was while another changed the values, as one history has it. The
/// tabs are added up, never multiplied together. It shows more than the
/// app only where what one tab's history holds and what another's holds go
/// together with no condition saying so. With the nodes, the pops that
/// land somewhere.
///
/// Each is taken once: a node's moves when it is met; what lands on what is
/// under it, as each comes to be under it; a switch to a tab, as each node
/// it can be left at comes to be. What is under a node is passed on to the
/// nodes that keep it, each once, those that keep each other's, round, one
/// group with one set; no search, no limit.
class _Unfollowed {
  _Unfollowed(this.r, {this.recording = false})
    : tabs = r._tabRoots.length,
      _leftValues = List.generate(r._tabRoots.length, (_) => {}),
      _leftAt = List.generate(r._tabRoots.length, (_) => {}),
      _changes = List.generate(r._tabRoots.length, (_) => {});

  final Router r;

  /// Whether each node's moves are kept, for [distances].
  final bool recording;
  final int tabs;

  /// Where a node is: out of any bar ([noBar]), in the tab t's history (t),
  /// or over the bar with the tab t under it ([overBar]).
  static const noBar = -1;
  int overBar(int t) => tabs + t;
  bool inTab(int where) => where >= 0 && where < tabs;
  int tabOf(int where) => where < 0 ? -1 : where % tabs;

  /// What can be under a node besides nodes: nothing, where it was put.
  static const nothing = -1;

  /// Where a tab is left besides nodes: not opened yet.
  static const unopened = -1;

  final _ids = <int, int>{};

  /// For each node: its canonical node, where it is, and the nodes its moves
  /// reach ([recording]).
  final nodeOf = <int>[];
  final whereOf = <int>[];
  final _moves = <Set<int>>[];

  /// What can be under the nodes (nodes, or [nothing]), kept by groups: the
  /// nodes that keep what is under each other, round, have the same, and
  /// are one group, its set one ([_group], [_merge]). For each node, the
  /// node it is grouped under (itself, for a group's own); for each group,
  /// what can be under its nodes, its nodes, and the groups that keep what
  /// is under them.
  final _groupOf = <int>[];
  final _under = <Set<int>>[];
  final _members = <List<int>>[];
  final _keptBy = <Set<int>>[];

  /// The groups' keeps, made so far and when they were last merged.
  var _keeps = 0;
  var _keepsMerged = 0;

  /// For each node over the bar: the nodes of the tab's history under it
  /// (its top, under the pages over the bar), the nodes over the bar whose
  /// tops those are too, and the tabs a go from it to another tab leaves at
  /// them, with the values after it.
  final _tops = <Set<int>?>[];
  final _topsAbove = <Set<int>?>[];
  final _goneWith = <Set<(int, int)>?>[];

  /// Whether tapping the tab shown again is taken from each node.
  final _retapped = <bool>[];

  /// The edges written as pops that land somewhere.
  final pops = <int>{};

  /// Each tab: the values there can be while it is left at each node (or
  /// [unopened]); the nodes it can be left at under each values; the
  /// changes of the values made while it is left.
  final List<Map<int, Set<int>>> _leftValues;
  final List<Map<int, Set<int>>> _leftAt;
  final List<Map<int, Set<int>>> _changes;

  /// The nodes that can switch to a tab under values, by both.
  final _switching = <int, List<int>>{};

  /// What is still to be taken: the nodes met; a node and what came to be
  /// under it; a tab, the node it came to be left at, and the values; a
  /// node over the bar and a top that came to be under it. Each in a row
  /// of numbers, its parts one after another: as many as nodes under nodes
  /// can be, they are not made objects.
  final _met = <int>[];
  final _cameUnder = <int>[];
  final _cameLeft = <int>[];
  final _cameTop = <int>[];

  /// A group and what came to be under its nodes, to be passed on to the
  /// groups that keep it.
  final _passing = <int>[];

  /// What has been met so far: it grows with each node, each move, and each
  /// node under another or a tab left at.
  var version = 0;

  int _key(int node, int where) => node * (2 * tabs + 1) + where + 1;

  /// The node of a search's [node] (a shell, or a frame over [shell], the
  /// shell at the bottom or -1): null if it is not met.
  int? find(int node, int shell) {
    final where = r._isShell(node)
        ? r._shellAt(node).active
        : r._frameTab[r._frameOf(node)] ??
              (shell >= 0 ? overBar(r._shellAt(shell).active) : noBar);
    return _ids[_key(r._plain(node), where)];
  }

  /// [starts], each a search's node with nothing under it (a frame, or a
  /// shell of one tab opened), and all they lead to.
  void addStarts(Iterable<int> starts) {
    for (final s in starts) {
      _start(s);
    }
    _run();
  }

  void _start(int start, {int? from}) {
    if (r._isShell(start)) {
      _newShell(r._plain(start), r._shellAt(start).active, from: from);
    } else {
      _reach(r._plain(start), noBar, below: nothing, from: from);
    }
  }

  /// [node], of a canonical frame, where [where] says, over [below], and
  /// keeping what is under [keeps]; a move from [from] to it.
  void _reach(int node, int where, {int? below, int? keeps, int? from}) {
    final key = _key(node, where);
    var id = _ids[key];
    if (id == null) {
      id = _ids[key] = nodeOf.length;
      nodeOf.add(node);
      whereOf.add(where);
      _groupOf.add(id);
      _under.add({});
      _members.add([id]);
      _keptBy.add({});
      if (recording) _moves.add({});
      final over = where >= tabs;
      _tops.add(over ? {} : null);
      _topsAbove.add(over ? {} : null);
      _goneWith.add(over ? {} : null);
      _retapped.add(false);
      _met.add(id);
      version++;
    }
    if (recording && from != null && from != id && _moves[from].add(id)) {
      version++;
    }
    if (below != null) _addUnder(id, below);
    if (keeps != null) _keep(keeps, id);
  }

  /// The group of the node [id].
  int _group(int id) {
    var g = id;
    while (_groupOf[g] != g) {
      g = _groupOf[g] = _groupOf[_groupOf[g]];
    }
    return g;
  }

  void _addUnder(int id, int u) => _addToGroup(_group(id), u);

  /// [u] under each node of the group [g]: each to land on, and passed on.
  void _addToGroup(int g, int u) {
    if (!_under[g].add(u)) return;
    for (final m in _members[g]) {
      _cameUnder
        ..add(m)
        ..add(u);
    }
    _passing
      ..add(g)
      ..add(u);
    version++;
  }

  /// [to] keeps what is under [from], and what comes to be.
  void _keep(int from, int to) {
    final a = _group(from), b = _group(to);
    if (a == b || !_keptBy[a].add(b)) return;
    _keeps++;
    for (final u in _under[a]) {
      _addToGroup(b, u);
    }
  }

  /// [u], come to be under the group [g]'s nodes, under those of the groups
  /// that keep it.
  void _pass(int g, int u) {
    final from = _group(g);
    for (final to in _keptBy[from]) {
      final b = _group(to);
      if (b != from) _addToGroup(b, u);
    }
  }

  /// The groups that keep what is under each other, round, made one (each
  /// a strongly connected component of the keeps, Tarjan's): what is under
  /// their nodes comes to be the same, and is passed on once, not round.
  void _merge() {
    _keepsMerged = _keeps;
    final n = nodeOf.length;
    final out = List<List<int>>.filled(n, const []);
    for (var a = 0; a < n; a++) {
      if (_groupOf[a] != a) continue;
      final to = {
        for (final b in _keptBy[a])
          if (_group(b) != a) _group(b),
      };
      _keptBy[a] = to;
      out[a] = to.toList();
    }
    final index = List.filled(n, -1), low = List.filled(n, 0);
    final onStack = List.filled(n, false);
    final stack = <int>[];
    var counter = 0;
    for (var s = 0; s < n; s++) {
      if (_groupOf[s] != s || index[s] >= 0) continue;
      final path = [s], next = [0];
      index[s] = low[s] = counter++;
      stack.add(s);
      onStack[s] = true;
      while (path.isNotEmpty) {
        final v = path.last, i = next.last;
        if (i < out[v].length) {
          next.last = i + 1;
          final w = out[v][i];
          if (index[w] < 0) {
            index[w] = low[w] = counter++;
            stack.add(w);
            onStack[w] = true;
            path.add(w);
            next.add(0);
          } else if (onStack[w] && index[w] < low[v]) {
            low[v] = index[w];
          }
          continue;
        }
        path.removeLast();
        next.removeLast();
        if (path.isNotEmpty && low[v] < low[path.last]) low[path.last] = low[v];
        if (low[v] != index[v]) continue;
        final component = <int>[];
        int w;
        do {
          w = stack.removeLast();
          onStack[w] = false;
          component.add(w);
        } while (w != v);
        if (component.length > 1) _join(component);
      }
    }
  }

  /// The groups [component] made one: each node lands on what it did not
  /// have under it, and that is passed on.
  void _join(List<int> component) {
    final all = <int>{for (final g in component) ..._under[g]};
    var into = component.first;
    for (final g in component) {
      if (_under[g].length > _under[into].length) into = g;
    }
    final passed = <int>{};
    final keptBy = <int>{};
    for (final g in component) {
      final had = _under[g];
      for (final u in all) {
        if (had.contains(u)) continue;
        passed.add(u);
        for (final m in _members[g]) {
          _cameUnder
            ..add(m)
            ..add(u);
        }
      }
      keptBy.addAll(_keptBy[g]);
      if (g == into) continue;
      _groupOf[g] = into;
      _members[into].addAll(_members[g]);
      _members[g] = const [];
      _under[g] = const {};
      _keptBy[g] = const {};
    }
    _under[into] = all;
    _keptBy[into] = keptBy..removeAll(component);
    for (final u in passed) {
      _passing
        ..add(into)
        ..add(u);
    }
    version++;
  }

  void _run() {
    while (true) {
      if (_keeps >= _keepsMerged + (_keepsMerged >> 3) + 64) _merge();
      if (_cameLeft.isNotEmpty) {
        final g = _cameLeft.removeLast(), at = _cameLeft.removeLast();
        _left(_cameLeft.removeLast(), at, g);
      } else if (_cameTop.isNotEmpty) {
        final top = _cameTop.removeLast();
        _topped(_cameTop.removeLast(), top);
      } else if (_passing.isNotEmpty) {
        final u = _passing.removeLast();
        _pass(_passing.removeLast(), u);
      } else if (_cameUnder.isNotEmpty) {
        final u = _cameUnder.removeLast();
        _takeUnder(_cameUnder.removeLast(), u);
      } else if (_met.isNotEmpty) {
        _take(_met.removeLast());
      } else {
        return;
      }
    }
  }

  /// The moves of the node [id] that what is under it does not decide: its
  /// transitions but its pops; in a tab, tapping it again from another page
  /// than its first, and a switch to each tab it can switch to, as each
  /// node that tab can be left at comes to be.
  void _take(int id) {
    final n = nodeOf[id], where = whereOf[id];
    final g = r._gOf(n);
    final tab = inTab(where) ? where : null;
    for (final i in r._outs(n)) {
      final e = r.edges[i];
      for (final h in r._arrive(i, n)) {
        switch (r._effect(e.move, tab, h)) {
          case _Effect.pop:
            continue;
          case _Effect.reset:
            _goTo(id, h, e.tab);
          case _Effect.replace:
            _reach(h, where, keeps: id, from: id);
            _changed(where, g, r._gOf(h));
          case _Effect.push:
            _reach(h, where, below: id, from: id);
            _changed(where, g, r._gOf(h));
          case _Effect.overBar:
            _reach(h, overBar(tab!), below: id, from: id);
            _changed(where, g, r._gOf(h));
        }
      }
    }
    if (tab == null) return;
    _retap(id, alone: true);
    for (final s in r._barTabs[r._tabBar[tab]]) {
      if (s == tab || !r._guarded(r._tabGuards[s], g)) continue;
      (_switching[s * r._valuations + g] ??= []).add(id);
      for (final at in _leftAt[s][g] ?? const <int>{}) {
        _switch(id, s, at);
      }
    }
  }

  /// What lands on [u], come to be under the node [id]: a back, or a pop,
  /// the transition that put it there taken back, onto [u], in the state
  /// the values give now; with [nothing] under it, a pop where it names,
  /// the back to the parent go_router built under it ([Router._alone]).
  void _takeUnder(int id, int u) {
    final n = nodeOf[id], where = whereOf[id];
    final g = r._gOf(n);
    final tab = inTab(where) ? where : null;
    for (final j in r._pops(n)) {
      if (u != nothing) {
        // Of u's frame alone (a canonical node's: [Router._landOn]).
        for (final l in r._land(nodeOf[u], n, j)) {
          if (j != null) pops.add(j);
          _reach(l, whereOf[u], keeps: u, from: id);
          _changed(where, g, r._gOf(l));
        }
        continue;
      }
      for (final (:node, :stays) in r._alone(n, j, tab)) {
        if (j != null) pops.add(j);
        if (stays) {
          _reach(node, where, below: nothing, from: id);
          _changed(where, g, r._gOf(node));
        } else {
          _start(node, from: id);
        }
      }
    }
    if (u == nothing) return;
    if (tab != null) _retap(id, alone: false);
    // Over the bar: the tab's tops under it.
    if (_tops[id] != null && u != id) {
      if (inTab(whereOf[u])) {
        _addTop(id, u);
      } else if (_tops[u] case final tops?) {
        _topsAbove[u]!.add(id);
        for (final top in tops) {
          _addTop(id, top);
        }
      }
    }
  }

  void _addTop(int id, int top) {
    if (_tops[id]!.add(top)) {
      _cameTop
        ..add(id)
        ..add(top);
    }
  }

  /// [top], come to be the tab's top under [id], over the bar: each tab a
  /// go from [id] left is left at it too, and it is a top of the nodes over
  /// the bar above [id].
  void _topped(int id, int top) {
    for (final (a, g) in _goneWith[id]!) {
      _leave(a, top, g);
    }
    for (final above in _topsAbove[id]!) {
      _addTop(above, top);
    }
  }

  /// Tapping the tab shown again from [id], in its history: its first page,
  /// unless [id] is it with nothing under it ([alone]: nothing yet).
  void _retap(int id, {required bool alone}) {
    if (_retapped[id]) return;
    final n = nodeOf[id], t = whereOf[id];
    final g = r._gOf(n);
    if (!r._retaps(t, g, top: n, alone: alone)) return;
    _retapped[id] = true;
    for (final x in r._tabFirst(t, g)) {
      _reach(x, t, below: nothing, from: id);
    }
  }

  /// A switch from [id], in a tab, to the tab [s] left at [at]: as left, in
  /// the state the values give, with what was under it; not opened, its
  /// first page. The tab [id] is in is left at it.
  void _switch(int id, int s, int at) {
    final g = r._gOf(nodeOf[id]);
    _leave(whereOf[id], id, g);
    final opened = at != unopened;
    // Under the values now: those held, but where a start names others.
    for (final x in r._switchTo(s, opened ? r._frameOf(nodeOf[at]) : null, g)) {
      if (opened) {
        _reach(x, s, keeps: at, from: id);
      } else {
        _reach(x, s, below: nothing, from: id);
      }
    }
  }

  /// A go from [id] to [h] (naming [named]): in the same bar, the other
  /// tabs kept, the tab shown left at its top; else a bar anew, or none.
  void _goTo(int id, int h, String? named) {
    final where = whereOf[id];
    final g = r._gOf(nodeOf[id]), g2 = r._gOf(h);
    final a = where < 0 ? null : tabOf(where);
    final t = r._goTab(r._frames[r._frameOf(h)].page, a, named);
    if (t == null) {
      _reach(h, noBar, below: nothing, from: id);
      return;
    }
    if (a == null || r._tabBar[t] != r._tabBar[a]) {
      _newShell(h, t, from: id);
      return;
    }
    if (t != a) {
      if (inTab(where)) {
        _leave(a, id, g2);
      } else if (_goneWith[id]!.add((a, g2))) {
        for (final top in _tops[id]!) {
          _leave(a, top, g2);
        }
      }
    }
    _changed(where, g, g2, to: t);
    _reach(h, t, below: nothing, from: id);
  }

  /// A bar opened anew at [h], in the tab [t]: its other tabs not opened.
  void _newShell(int h, int t, {int? from}) {
    for (final s in r._barTabs[r._tabBar[t]]) {
      if (s != t) _leave(s, unopened, r._gOf(h));
    }
    _reach(h, t, below: nothing, from: from);
  }

  /// A move where [where] says changing the values from [g] to [g2]: each
  /// other tab of the bar is left while they do (but [to], opened by it).
  void _changed(int where, int g, int g2, {int? to}) {
    if (where == noBar || g == g2) return;
    final t = tabOf(where);
    for (final s in r._barTabs[r._tabBar[t]]) {
      if (s != t && s != to) _change(s, g, g2);
    }
  }

  /// The tab [s] left at [at] while the values are [g].
  void _leave(int s, int at, int g) {
    if (!(_leftValues[s][at] ??= {}).add(g)) return;
    _cameLeft
      ..add(s)
      ..add(at)
      ..add(g);
    version++;
  }

  /// [s] come to be left at [at] while [g]: each node that switches to it
  /// then does, and it is left so while the values change as they can
  /// while it is left.
  void _left(int s, int at, int g) {
    (_leftAt[s][g] ??= {}).add(at);
    for (final id in _switching[s * r._valuations + g] ?? const <int>[]) {
      _switch(id, s, at);
    }
    for (final g2 in _changes[s][g] ?? const <int>{}) {
      _leave(s, at, g2);
    }
  }

  /// The values changing from [g] to [g2] while the tab [s] is left.
  void _change(int s, int g, int g2) {
    if (g == g2 || !(_changes[s][g] ??= {}).add(g2)) return;
    for (final at in _leftAt[s][g] ?? const <int>{}) {
      _leave(s, at, g2);
    }
  }

  /// The moves backwards, as of [version].
  List<List<int>> get _back {
    if (_backOf?.$1 == version) return _backOf!.$2;
    final back = List.generate(nodeOf.length, (_) => <int>[]);
    for (final (from, tos) in _moves.indexed) {
      for (final to in tos) {
        back[to].add(from);
      }
    }
    _backOf = (version, back);
    return back;
  }

  (int, List<List<int>>)? _backOf;

  /// For each node, the fewest moves from it to one whose canonical node
  /// [done] holds of; -1 where none leads.
  List<int> distances(bool Function(int node) done) {
    final back = _back;
    final dist = List.filled(nodeOf.length, -1);
    final queue = <int>[];
    for (var id = 0; id < nodeOf.length; id++) {
      if (done(nodeOf[id])) {
        dist[id] = 0;
        queue.add(id);
      }
    }
    for (var k = 0; k < queue.length; k++) {
      final id = queue[k];
      for (final from in back[id]) {
        if (dist[from] >= 0) continue;
        dist[from] = dist[id] + 1;
        queue.add(from);
      }
    }
    return dist;
  }
}

/// A binary heap on (d, then the tie, then the order pushed): the same route
/// each time. Only numbers move in it: the values stay where they were
/// pushed, by the order (moving a value of a record type checks its type
/// each time).
class _Heap<T> {
  final _d = <int>[];
  final _tie = <int>[];
  final _order = <int>[];
  final _values = <Object?>[];

  bool get isNotEmpty => _d.isNotEmpty;

  bool _less(int i, int j) =>
      _d[i] < _d[j] ||
      (_d[i] == _d[j] &&
          (_tie[i] < _tie[j] || (_tie[i] == _tie[j] && _order[i] < _order[j])));

  void push(int d, T value, {int tie = 0}) {
    _d.add(d);
    _tie.add(tie);
    _order.add(_values.length);
    _values.add(value);
    for (var i = _d.length - 1; i > 0;) {
      final p = (i - 1) >> 1;
      if (_less(p, i)) break;
      _swap(p, i);
      i = p;
    }
  }

  (int, T) pop() {
    final d = _d.first;
    final o = _order.first;
    final value = _values[o] as T;
    _values[o] = null;
    final last = _d.length - 1;
    _swap(0, last);
    _d.removeLast();
    _tie.removeLast();
    _order.removeLast();
    final n = _d.length;
    for (var i = 0; ;) {
      final l = 2 * i + 1, r = l + 1;
      var m = i;
      if (l < n && _less(l, m)) m = l;
      if (r < n && _less(r, m)) m = r;
      if (m == i) break;
      _swap(m, i);
      i = m;
    }
    return (d, value);
  }

  void _swap(int i, int j) {
    final d = _d[i];
    _d[i] = _d[j];
    _d[j] = d;
    final t = _tie[i];
    _tie[i] = _tie[j];
    _tie[j] = t;
    final o = _order[i];
    _order[i] = _order[j];
    _order[j] = o;
  }
}
