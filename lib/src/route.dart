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
/// from where the bar is not switched. [Route.bounded] tells a route a
/// switch from deeper might have made shorter.
///
/// The fewest steps are a shortest path in this pushdown system, its stack
/// the frames and its control the conditions' values and the shell, exact,
/// with no bound on the stack (a shortest route can need a page twice on
/// it): each frame entered under each value of the conditions is
/// summarised once, the fewest steps from it to each frame and value at its
/// level through the pages pushed and popped above it, in one Dijkstra over
/// all levels (Knuth's: a step out of a pushed page costs more than the
/// steps it is made of); the route is then searched from a stack over those
/// summaries, the shell's moves among them. The shell is never pushed: no
/// summary holds it.
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

/// The moves a search's bound below is the fewest of ([Router._boundOf]):
/// canonical nodes, numbered as the router does, and tab states after them.
class _Bound {
  _Bound(this.base);

  final int base;
  final moves = <int, Set<int>>{};
  final tabs = <_TabState>[];
  final _ids = <String, int>{};

  /// The tab state of [t] showing [history] under [g], numbered as met.
  int tab(int bar, int t, List<int> history, int g) =>
      _ids['$t|${history.join(',')}|$g'] ??= () {
        tabs.add(_TabState(bar, t, history, g));
        return base + tabs.length - 1;
      }();

  int? find(int t, List<int> history, int g) =>
      _ids['$t|${history.join(',')}|$g'];

  /// The canonical node the tab state [id] shows, by [node].
  int shown(int id, int Function(int frame, int g) node) {
    final a = tabs[id - base];
    return node(a.history.last, a.g);
  }
}

/// A bar showing [tab], its history [history], under [g].
class _TabState {
  _TabState(this.bar, this.tab, this.history, this.g);

  final int bar;
  final int tab;
  final List<int> history;
  final int g;
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
        _ids['${p.id}\u0000${s.name}'] = _frames.length;
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
      _deepTabs.add(tabs.toList());
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

  /// [json], `sheet.json`: its conditions, tab bars, pages and edges.
  factory Router.fromJson(Map<String, Object?> json) => Router(
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

  /// For each canonical frame, the tabs it has a frame in past the bound.
  final _deepTabs = <List<int>>[];
  final _ids = <String, int>{};
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
  final _shellIds = <String, int>{};

  int? _frame(String page, String state) => _ids['$page\u0000$state'];

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
  final _historyIds = <String, int>{};
  final _historyOf = Map<List<int>, int>.identity();

  int _history(List<int> history) =>
      _historyOf[history] ??= _historyIds[history.join(',')] ??= () {
        _histories.add(history);
        return _histories.length - 1;
      }();

  /// The shell of [bar] showing [active], with [stacks], under [g].
  int _shell(int bar, int active, List<List<int>> stacks, int g) {
    final ids = [for (final s in stacks) _history(s)];
    return _shellIds['$bar|$active|${ids.join(',')}|$g'] ??= () {
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

  /// The tab a go (by [edge], or a deep link naming [named]) opens [page]
  /// in, while [active] is shown; null when the page is in none.
  int? _goTab(String page, int? active, String? named) {
    final t = _rootTab[named] ?? _rootTab[page];
    if (t != null) return t;
    final tabs = _inTabs[page]!;
    if (tabs.isEmpty) return null;
    return active != null && tabs.contains(active) ? active : tabs.first;
  }

  /// Where a go, or the app's launch, or a deep link, puts [node] (of a
  /// canonical frame) as all the history, from [ctx] (the shell at the
  /// bottom, or -1), by [edge] or naming [named]: in its tab (keeping the
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

  bool _valid(int node) => _holds(_requires[_frameOf(node)], _gOf(node));

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
  List<int> _unsaid(String page, int g) => [
    for (final f in _pageFrames[page] ?? const <int>[])
      if (_decided[f] && _holds(_requires[f], g)) _node(f, g),
  ];

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

  /// The nodes, of canonical frames, the edge [i] arrives at from [node].
  List<int> _arrive(int i, int node) {
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

  /// [h], of a canonical frame, put where [like]'s frame is (not a shell):
  /// in the same tab's history past the bound when [like] is and [h]'s page
  /// is shown in that tab, or [landing] in [like]'s place (as a pop lands
  /// in the tab's history within the bound, whatever the page); else over
  /// the bar.
  int _keep(int like, int h, {bool landing = false}) {
    final t = _frameTab[_frameOf(like)];
    final f = _frameOf(h);
    if (t == null || (!landing && !_inTab(_frames[f].page, t))) return h;
    final deep = _deep[(f, t)];
    return deep == null ? h : _node(deep, _gOf(h));
  }

  /// Whether a replace from [f] by which [h] arrives puts [h] over the bar
  /// instead: [f] in a tab's history past the bound, [h] not shown in it
  /// (as within the bound, the tab's top stays).
  bool _overBar(int f, int h) =>
      _frameTab[_frameOf(f)] != null && _frameTab[_frameOf(h)] == null;

  /// The nodes that take [below]'s place (its frame read; the conditions
  /// are the top's) when [top] is taken off by the pop [j] (null: the
  /// back). Under a shell, its tab shown's top is what is landed on.
  List<int> _land(int below, int top, int? j) {
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
    return [
      for (final l in _landOn(_frameOf(below), top, j))
        _keep(below, l, landing: true),
    ];
  }

  /// The nodes, of canonical frames, landed on in place of the frame
  /// [under] when [top] is taken off by [j].
  List<int> _landOn(int under, int top, int? j) {
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

  /// Whether tapping the tab [t] shown again, its history [stack], goes
  /// back to its first page: the bar says so, the conditions let the tab be
  /// switched to, and the history is not that page alone.
  bool _retaps(int t, List<int> stack, int g) =>
      tabBars[_tabBar[t]].retapFirst &&
      _guarded(_tabGuards[t], g) &&
      (stack.length >= 2 || _frames[stack.single].page != _tabRoots[t]);

  /// Where the app launches: its first page, in the first state its first
  /// values allow, in its tab if it is in one.
  int get _launch {
    final first = pages.first;
    final unsaid = _unsaid(first.id, 0);
    final f = _pageFrames[first.id]!.first;
    return _startAt(
      unsaid.isNotEmpty ? unsaid.first : _node(f, _apply(_requires[f], 0)),
      -1,
    );
  }

  /// The pages each page can be put over: those that push it; those the
  /// pages it takes the place of can be put over (and those, where a tab's
  /// page puts it over the bar instead); and, for a pop to it from a page,
  /// those the pages under that page can be put over, whose place it takes.
  late final Map<String, Set<String>> _over = () {
    final over = <String, Set<String>>{};
    for (var grew = true; grew;) {
      grew = false;
      for (final e in edges) {
        final under = switch (e.move) {
          RouteMove.push => {e.from},
          RouteMove.replace => {e.from, ...?over[e.from]},
          RouteMove.pop when !e.under => {
            for (final b in over[e.from] ?? const <String>{}) ...?over[b],
          },
          _ => const <String>{},
        };
        final known = over[e.to] ??= {};
        for (final p in under) {
          if (known.add(p)) grew = true;
        }
      }
    }
    return over;
  }();

  /// The canonical nodes: the canonical frames come first.
  late final int _canonCount =
      _pageFrames.values.fold(0, (s, f) => s + f.length) * _valuations;

  /// Each canonical node's edges' arrivals: its moves with the history left
  /// out, but its pops and a switch.
  late final List<List<int>> _loose = () {
    final next = List.generate(_canonCount, (_) => <int>{});
    for (var node = 0; node < _canonCount; node++) {
      if (!_valid(node)) continue;
      for (final i in _outs(node)) {
        next[node].addAll(_arrive(i, node));
      }
    }
    return [for (final s in next) s.toList()];
  }();

  /// The moves from [stack] with the other tabs' histories left out ([_Bound]),
  /// once for each start: a route's searches from one start share it. They
  /// keep tabs' histories within [tabDepth] even while a route is searched
  /// again past it: what goes deeper is a page over the bar there, which
  /// switches too (raised, the tab states would be too many), so the bound
  /// stays below the steps past it.
  _Bound _bound(List<int> stack) => _bounds[stack.join(',')] ??= () {
    final depth = _depth;
    _depth = tabDepth;
    try {
      return _boundOf(stack);
    } finally {
      _depth = depth;
    }
  }();

  final _bounds = <String, _Bound>{};

  /// The moves reached from [stack], over two kinds of node: a canonical
  /// node (a page over the bar, or out of it, with no history under it but
  /// what [_over] says can be), and a tab's state (a bar showing one tab,
  /// that tab's history exactly, the values), with each other tab's history
  /// one of those it can have been left with (a set for each tab, which
  /// grows as tab states are reached). Every step of a route from [stack]
  /// is one of these moves between nodes they reach, so the fewest of them
  /// to a page are a bound below the route's that no step lowers by more
  /// than its own; and as the tabs are each on their own, the nodes are as
  /// many as the tabs' histories added up, not multiplied.
  _Bound _boundOf(List<int> stack) {
    final bound = _Bound(_canonCount);
    final moves = bound.moves;
    final queue = <int>[];
    void reach(int id) {
      if (moves.containsKey(id)) return;
      moves[id] = {};
      queue.add(id);
    }

    int tab(int t, List<int> history, int g) {
      final id = bound.tab(_tabBar[t], t, history, g);
      reach(id);
      return id;
    }

    void add(int from, int to) {
      moves[from]!.add(to);
      reach(to);
    }

    List<int> shown(int top, int g) => _holds(_requires[top], g)
        ? [_node(top, g)]
        : _unsaid(_frames[top].page, g);

    // The histories each tab can have been left with; the pages of a tab
    // it can have been left at deeper than that, as a page over the bar (a
    // route past the bound switches from there, and back to it); and what
    // switches in each bar: a node, its values, its own tab (-1: a page
    // over the bar). Each grows, and the moves with it.
    final left = List.generate(_tabRoots.length, (_) => <String, List<int>>{});
    final leftDeep = List.generate(_tabRoots.length, (_) => <int>{});
    final switchers = List.generate(
      _barTabs.length,
      (_) => <(int, int, int)>[],
    );
    void restore(int from, int t, List<int> history, int g) {
      for (final x in shown(history.last, g)) {
        add(
          from,
          tab(t, [...history.take(history.length - 1), _frameOf(x)], g),
        );
      }
    }

    void leave(int t, List<int> history) {
      if (left[t].putIfAbsent(history.join(','), () => history) != history) {
        return;
      }
      for (final (from, g, own) in [...switchers[_tabBar[t]]]) {
        if (own != t && _guarded(_tabGuards[t], g)) {
          restore(from, t, history, g);
        }
      }
    }

    void leaveDeep(int t, int f) {
      if (!leftDeep[t].add(f)) return;
      for (final (from, g, own) in [...switchers[_tabBar[t]]]) {
        if (own == t || !_guarded(_tabGuards[t], g)) continue;
        for (final x in shown(f, g)) {
          add(from, x);
        }
      }
    }

    void switches(int from, int own, int bar, int g) {
      switchers[bar].add((from, g, own));
      for (final t in _barTabs[bar]) {
        if (t == own || !_guarded(_tabGuards[t], g)) continue;
        for (final x in _unsaid(_tabRoots[t], g)) {
          add(from, tab(t, [_frameOf(x)], g));
        }
        for (final history in [...left[t].values]) {
          restore(from, t, history, g);
        }
        for (final f in [...leftDeep[t]]) {
          for (final x in shown(f, g)) {
            add(from, x);
          }
        }
      }
    }

    // The tab states by their history's top page, and the pages over the
    // bar by the pages that can be under them: a pop from such a page lands
    // on such a tab state.
    final byTop = <String, List<int>>{};
    final byUnder = <String, List<int>>{};
    void land(int canon, int tabState) {
      final a = bound.tabs[tabState - _canonCount];
      for (final j in _pops(canon)) {
        for (final l in _landOn(a.history.last, canon, j)) {
          add(
            canon,
            tab(a.tab, [
              ...a.history.take(a.history.length - 1),
              _frameOf(l),
            ], _gOf(l)),
          );
        }
      }
    }

    // The pages shown so far: only one of them can be under a page, so a
    // pop lands only on those; a page over the bar waits for the pages it
    // can be over to be shown.
    final shownPages = <String>{};
    final waiting = <String, List<int>>{};
    void landOn(int canon, String under) {
      for (final j in _pops(canon)) {
        for (final u in _pageFrames[under]!) {
          for (final l in _landOn(u, canon, j)) {
            add(canon, l);
          }
        }
      }
    }

    void show(String page) {
      if (!shownPages.add(page)) return;
      for (final canon in [...?waiting[page]]) {
        landOn(canon, page);
      }
    }

    for (final n in stack) {
      if (!_isShell(n)) {
        show(_frames[_frameOf(n)].page);
        reach(_plain(n));
        continue;
      }
      final s = _shellAt(n);
      for (final t in _barTabs[s.bar]) {
        final history = s.stacks[_tabPos[t]];
        for (final f in history) {
          show(_frames[f].page);
        }
        if (history.isEmpty) continue;
        if (t == s.active) {
          tab(t, history, s.g);
        } else {
          leave(t, history);
        }
      }
    }

    // A node's moves, as it is reached; those the others reached later
    // give are added as they are.
    void own(int id) {
      final to = moves[id]!;
      if (id < _canonCount) {
        final f = _frameOf(id);
        final page = _frames[f].page;
        final g = _gOf(id);
        for (final x in _loose[id]) {
          add(id, x);
        }
        show(page);
        for (final under in _over[page] ?? const <String>{}) {
          if (shownPages.contains(under)) {
            landOn(id, under);
          } else {
            (waiting[under] ??= []).add(id);
          }
        }
        for (final i in _outs(id)) {
          if (edges[i].move != RouteMove.reset) continue;
          for (final h in _arrive(i, id)) {
            final t = _goTab(_frames[_frameOf(h)].page, null, edges[i].tab);
            if (t != null) add(id, tab(t, [_frameOf(h)], _gOf(h)));
          }
        }
        // Nothing under it: its back to its parent.
        for (final h in _toParent(id)) {
          add(id, h);
          final t = _goTab(_frames[_frameOf(h)].page, null, null);
          if (t != null) add(id, tab(t, [_frameOf(h)], _gOf(h)));
        }
        // A page of a tab, past the bound in it: tapping it again, and a
        // switch, from here and back to here.
        final tabs = _deepTabs[f];
        for (final t in tabs) {
          if (tabBars[_tabBar[t]].retapFirst && _guarded(_tabGuards[t], g)) {
            for (final x in _unsaid(_tabRoots[t], g)) {
              add(id, tab(t, [_frameOf(x)], g));
            }
          }
          leaveDeep(t, f);
        }
        for (final bar in {for (final t in tabs) _tabBar[t]}) {
          switches(id, -1, bar, g);
        }
        // Its pops landing on the tab states under it.
        for (final under in _over[page] ?? const <String>{}) {
          (byUnder[under] ??= []).add(id);
          for (final a in [...?byTop[under]]) {
            land(id, a);
          }
        }
        return;
      }
      final a = bound.tabs[id - _canonCount];
      final history = a.history;
      final n = _node(history.last, a.g);
      for (final f in history) {
        show(_frames[f].page);
      }
      leave(a.tab, history);
      switches(id, a.tab, a.bar, a.g);
      final top = _frames[history.last].page;
      (byTop[top] ??= []).add(id);
      for (final canon in [...?byUnder[top]]) {
        land(canon, id);
      }
      for (final i in _outs(n)) {
        final move = edges[i].move;
        if (move == RouteMove.pop) continue;
        for (final h in _arrive(i, n)) {
          final f = _frameOf(h);
          final page = _frames[f].page;
          final inTab = _inTab(page, a.tab);
          switch (move) {
            case RouteMove.reset:
              final t = _goTab(page, a.tab, edges[i].tab);
              to.add(t == null ? h : tab(t, [f], _gOf(h)));
            case RouteMove.replace when inTab:
              to.add(
                tab(a.tab, [...history.take(history.length - 1), f], _gOf(h)),
              );
            case _
                when inTab && move == RouteMove.push && history.length < _depth:
              to.add(tab(a.tab, [...history, f], _gOf(h)));
            case _:
              to.add(h);
          }
        }
      }
      for (final j in _pops(n)) {
        if (history.length >= 2) {
          for (final l in _landOn(history[history.length - 2], n, j)) {
            to.add(
              tab(a.tab, [
                ...history.take(history.length - 2),
                _frameOf(l),
              ], _gOf(l)),
            );
          }
        } else if (j != null && !edges[j].under) {
          for (final h in _arrive(j, n)) {
            to.add(
              _inTab(_frames[_frameOf(h)].page, a.tab)
                  ? tab(a.tab, [_frameOf(h)], _gOf(h))
                  : h,
            );
          }
        }
      }
      if (history.length == 1) {
        for (final h in _toParent(n)) {
          final f = _frameOf(h);
          final t = _inTab(_frames[f].page, a.tab)
              ? a.tab
              : _goTab(_frames[f].page, null, null);
          to.add(h);
          if (t != null) to.add(tab(t, [f], _gOf(h)));
        }
      }
      if (_retaps(a.tab, history, a.g)) {
        for (final x in _unsaid(_tabRoots[a.tab], a.g)) {
          to.add(tab(a.tab, [_frameOf(x)], a.g));
        }
      }
      to.forEach(reach);
    }

    while (queue.isNotEmpty) {
      own(queue.removeLast());
    }
    return bound;
  }

  /// For each node [bound] reaches, the fewest of its moves to one [done]
  /// holds of (a tab state, as its history's top); -1 where none leads.
  List<int> _towards(_Bound bound, bool Function(int node) done) {
    final dist = List.filled(_canonCount + bound.tabs.length, -1);
    final back = <int, List<int>>{};
    for (final MapEntry(key: from, value: tos) in bound.moves.entries) {
      for (final to in tos) {
        (back[to] ??= []).add(from);
      }
    }
    final queue = [
      for (final id in bound.moves.keys)
        if (done(id < _canonCount ? id : bound.shown(id, _node))) id,
    ];
    for (final id in queue) {
      dist[id] = 0;
    }
    for (var i = 0; i < queue.length; i++) {
      final id = queue[i];
      for (final from in back[id] ?? const <int>[]) {
        if (dist[from] < 0) {
          dist[from] = dist[id] + 1;
          queue.add(from);
        }
      }
    }
    return dist;
  }

  /// A bound below the steps from a search's node to one [done] holds of,
  /// from [stack]; -1 where none leads. A shell [_bound] has not met (none
  /// should be), 0.
  int Function(int node) _toward(List<int> stack, bool Function(int) done) {
    final bound = _bound(stack);
    final dist = _towards(bound, done);
    return (node) {
      final id = _boundNode(bound, node);
      return id == null ? 0 : dist[id];
    };
  }

  /// The node of [bound] a search's [node] is: a shell as its tab state, a
  /// frame as its canonical node; null for a shell it does not have.
  int? _boundNode(_Bound bound, int node) {
    if (!_isShell(node)) return _plain(node);
    final s = _shellAt(node);
    return bound.find(s.active, s.stacks[_tabPos[s.active]], s.g);
  }

  late final _Summaries _summaries = _summarise();

  /// For each node g entered (a frame, never a shell): the fewest steps to
  /// each node at its level, and the step into each.
  _Summaries _summarise() {
    final n = _nodeCount;
    final dist = List.generate(n, (_) => <int, int>{});
    final pred = List.generate(n, (_) => <int, _Via?>{});
    // At g's level, after d, f pushed the node by the edge i.
    final callers = List.generate(n, (_) => <(int, int, int, int)>[]);
    final heap = _Heap<(int, int, _Via?)>();
    for (var g = 0; g < n; g++) {
      if (_valid(g)) heap.push(0, (g, g, null));
    }
    void relax(int d, int g, int f, _Via via) {
      if (!dist[g].containsKey(f)) heap.push(d, (g, f, via));
    }

    // f, at g's level after d, pushed h by i; h's level left from x, after
    // dh, by the pop j.
    void back(int g, int f, int d, int i, int h, int x, int dh, int? j) {
      for (final f2 in _land(f, x, j)) {
        relax(d + dh + 2, g, f2, _Via(f, summary: _Summary(i, h, x, j)));
      }
    }

    while (heap.isNotEmpty) {
      final (d, (g, f, via)) = heap.pop();
      if (dist[g].containsKey(f)) continue;
      dist[g][f] = d;
      pred[g][f] = via;
      for (final i in _outs(f)) {
        final move = edges[i].move;
        if (move == RouteMove.pop || move == RouteMove.reset) continue;
        for (final arrived in _arrive(i, f)) {
          final h = _keep(f, arrived);
          if (move == RouteMove.replace && !_overBar(f, h)) {
            relax(d + 1, g, h, _Via(f, edge: i));
            continue;
          }
          callers[h].add((g, f, d, i));
          for (final MapEntry(key: x, value: dh) in dist[h].entries) {
            for (final j in _pops(x)) {
              back(g, f, d, i, h, x, dh, j);
            }
          }
        }
      }
      for (final j in _pops(f)) {
        for (final (g0, f0, d0, i0) in callers[g]) {
          back(g0, f0, d0, i0, g, f, d, j);
        }
      }
    }
    return (dist: dist, pred: pred);
  }

  /// The search from [stack] (its top last) and from each of [alone] (a
  /// node with nothing under it): over (the top, how many of the stack's
  /// frames are under it, and the shell at the bottom or -1), and over the
  /// levels pushed above it that are not left again (-1). It stops at the
  /// first node [done] holds of, and gives what it reached, each with what
  /// it was reached from and by, that node, the fewest steps after which a
  /// page went past a tab's bound, and whether it stopped short, at
  /// [searchLimit] nodes taken.
  (Map<_At, (_At?, _Hop?)>, _At?, int?, bool) _explore(
    List<int> stack,
    bool Function(int node) done, {
    List<int> alone = const [],
    int Function(int node)? toward,
    bool limited = true,
    int? below,
  }) {
    // A*: the fewest steps so far and, from [toward], a bound below those
    // left, which no step lowers by more than its own (so a node is first
    // taken at its fewest); a node from which none leads is not taken.
    int bound(int f) => toward == null ? 0 : toward(f);
    final heap = _Heap<(int, _At, _At?, _Hop?)>();
    final seen = <_At, (_At?, _Hop?)>{};
    int? deep;
    // Whether [stack]'s first k frames hold one past a tab's bound.
    final pastUnder = [false];
    for (final n in stack) {
      pastUnder.add(pastUnder.last || _frameTab[_frameOf(n)] != null);
    }
    // Whether the tab shown's history goes on past the bound at [f], at k:
    // [f] is in it, or is over a frame that is.
    bool past(int f, int k) =>
        _frameTab[_frameOf(f)] != null ||
        k == _abovePast ||
        (k > 0 && pastUnder[k]);
    void relax(int d, int f, int k, int ctx, _At at, _Hop how) {
      if (_isShell(f)) ctx = f;
      final left = bound(f);
      // None leads on, or none in fewer than [below] steps.
      if (left < 0 || (below != null && d + left >= below)) return;
      // Past a tab's bound: a switch from here, which is not followed,
      // might lead on in no fewer steps than the bound says.
      if (_frameTab[_frameOf(f)] != null &&
          (deep == null || d + left < deep!)) {
        deep = d + left;
      }
      final next = (f, k, ctx);
      if (!seen.containsKey(next)) heap.push(d + left, (d, next, at, how));
    }

    if (stack.isNotEmpty) {
      final bottom = _isShell(stack.first) ? stack.first : -1;
      final left = bound(stack.last);
      if (stack.any((n) => _frameTab[_frameOf(n)] != null) && left >= 0) {
        deep = left;
      }
      if (left >= 0) {
        heap.push(left, (
          0,
          (stack.last, stack.length - 1, bottom),
          null,
          null,
        ));
      }
    }
    for (final node in alone) {
      final left = bound(node);
      if (left < 0) continue;
      heap.push(left, (0, (node, 0, _isShell(node) ? node : -1), null, null));
    }
    while (heap.isNotEmpty) {
      final (_, (d, at, from, how)) = heap.pop();
      if (seen.containsKey(at)) continue;
      seen[at] = (from, how);
      final (f, k, ctx) = at;
      if (done(f)) return (seen, at, deep, false);
      if (limited && seen.length >= searchLimit) {
        return (seen, null, deep, true);
      }
      if (_isShell(f)) {
        _shellMoves(d, at, relax);
        continue;
      }
      final tab = _frameTab[_frameOf(f)];
      final isPast = past(f, k);
      for (final i in _outs(f)) {
        final move = edges[i].move;
        if (move == RouteMove.pop) continue;
        for (final arrived in _arrive(i, f)) {
          if (move == RouteMove.reset) {
            // Past the bound, the tab shown is not left by a go to another
            // tab of its bar, from a page in its history or over it: that
            // history would have to be kept.
            final to = _startAt(arrived, ctx, named: edges[i].tab);
            if (isPast &&
                _isShell(to) &&
                _shellAt(to).bar == _shellAt(ctx).bar &&
                _shellAt(to).active != _shellAt(ctx).active) {
              continue;
            }
            // Out of the bar, its histories are gone.
            relax(d + 1, to, 0, -1, at, _Step(_Op.reset, i, to));
            continue;
          }
          final h = _keep(f, arrived);
          if (move == RouteMove.replace && !_overBar(f, h)) {
            relax(d + 1, h, k, ctx, at, _Step(_Op.replace, i, h));
          } else {
            _push(d, at, i, h, relax, past: isPast);
          }
        }
      }
      // Past the bound in the tab shown, tapping it again.
      if (tab != null && ctx >= 0) {
        final s = _shellAt(ctx);
        if (tab == s.active &&
            tabBars[s.bar].retapFirst &&
            _guarded(_tabGuards[tab], _gOf(f))) {
          for (final x in _unsaid(_tabRoots[tab], _gOf(f))) {
            final to = _withStack(s, [_frameOf(x)], _gOf(x));
            relax(d + 1, to, 0, ctx, at, _Step(_Op.reset, null, to, _Do.retap));
          }
        }
      }
      if (k > 0) {
        for (final j in _pops(f)) {
          for (final f2 in _land(stack[k - 1], f, j)) {
            relax(d + 1, f2, k - 1, ctx, at, _Step(_Op.pop, j, f2));
          }
        }
      } else if (k == 0) {
        // Nothing under it: a written pop is the sheet's word; the back goes
        // to its parent, where it has one.
        for (final j in _pops(f)) {
          if (j == null || edges[j].under) continue;
          for (final h in _arrive(j, f)) {
            relax(d + 1, h, 0, ctx, at, _Step(_Op.pop, j, h));
          }
        }
        for (final h in _toParent(f)) {
          final to = _startAt(h, -1);
          relax(d + 1, to, 0, -1, at, _Step(_Op.reset, null, to, _Do.back));
        }
      }
    }
    return (seen, null, deep, false);
  }

  /// From [at] after [d]: the push by [i] of [h], and each summary of it
  /// left again; [past]: from a page in a tab's history past the bound, or
  /// over one.
  void _push(
    int d,
    _At at,
    int i,
    int h,
    void Function(int, int, int, int, _At, _Hop) relax, {
    bool past = false,
  }) {
    final (f, k, ctx) = at;
    final dist = _summaries.dist;
    relax(d + 1, h, past ? _abovePast : -1, ctx, at, _Step(_Op.push, i, h));
    for (final MapEntry(key: x, value: dh) in dist[h].entries) {
      for (final j in _pops(x)) {
        for (final f2 in _land(f, x, j)) {
          relax(d + dh + 2, f2, k, ctx, at, _Summary(i, h, x, j, f2));
        }
      }
    }
  }

  /// The moves of the shell [at] shows (its tab's top): what the page does,
  /// in the tab's history within the bound, its back, a switch to another
  /// tab, and tapping it again.
  void _shellMoves(
    int d,
    _At at,
    void Function(int, int, int, int, _At, _Hop) relax,
  ) {
    final (f, _, ctx) = at;
    final s = _shellAt(f);
    final stack = s.stacks[_tabPos[s.active]];
    final g = s.g;
    void become(int to, int? edge, [_Do does = _Do.edge]) =>
        relax(d + 1, to, 0, ctx, at, _Step(_Op.replace, edge, to, does));
    for (final i in _outs(f)) {
      final move = edges[i].move;
      if (move == RouteMove.pop) continue;
      for (final h in _arrive(i, f)) {
        final page = _frames[_frameOf(h)].page;
        switch (move) {
          case RouteMove.reset:
            final to = _startAt(h, f, named: edges[i].tab);
            relax(d + 1, to, 0, -1, at, _Step(_Op.reset, i, to));
          // A page not in the tab, in place of its top: over the bar.
          case RouteMove.replace when !_inTab(page, s.active):
            _push(d, at, i, h, relax);
          case RouteMove.replace:
            become(
              _withStack(s, [
                ...stack.take(stack.length - 1),
                _frameOf(h),
              ], _gOf(h)),
              i,
            );
          case _ when !_inTab(page, s.active):
            _push(d, at, i, h, relax);
          case _ when stack.length < _depth:
            become(_withStack(s, [...stack, _frameOf(h)], _gOf(h)), i);
          case _:
            final deep = _node(_deep[(_frameOf(h), s.active)]!, _gOf(h));
            _push(d, at, i, deep, relax);
        }
      }
    }
    for (final j in _pops(f)) {
      if (stack.length >= 2) {
        for (final l in _landOn(stack[stack.length - 2], f, j)) {
          become(
            _withStack(s, [
              ...stack.take(stack.length - 2),
              _frameOf(l),
            ], _gOf(l)),
            j,
            j == null ? _Do.back : _Do.edge,
          );
        }
      } else if (j != null && !edges[j].under) {
        // Nothing under the tab's first page: a written pop is the
        // sheet's word, in the tab if its page is.
        for (final h in _arrive(j, f)) {
          if (_inTab(_frames[_frameOf(h)].page, s.active)) {
            become(_withStack(s, [_frameOf(h)], _gOf(h)), j);
          } else {
            relax(d + 1, h, 0, -1, at, _Step(_Op.reset, j, h));
          }
        }
      }
    }
    // A page alone in the tab's history (after a go): its back goes to its
    // parent, where it has one.
    if (stack.length == 1) {
      for (final h in _toParent(f)) {
        if (_inTab(_frames[_frameOf(h)].page, s.active)) {
          become(_withStack(s, [_frameOf(h)], _gOf(h)), null, _Do.back);
        } else {
          final to = _startAt(h, -1);
          relax(d + 1, to, 0, -1, at, _Step(_Op.reset, null, to, _Do.back));
        }
      }
    }
    for (final t in _barTabs[s.bar]) {
      if (t == s.active || !_guarded(_tabGuards[t], g)) continue;
      final other = s.stacks[_tabPos[t]];
      if (other.isEmpty) {
        for (final x in _unsaid(_tabRoots[t], g)) {
          become(_withStack(s, [_frameOf(x)], g, active: t), null, _Do.tab);
        }
      } else if (_holds(_requires[other.last], g)) {
        become(_withStack(s, other, g, active: t), null, _Do.tab);
      } else {
        for (final x in _unsaid(_frames[other.last].page, g)) {
          become(
            _withStack(
              s,
              [...other.take(other.length - 1), _frameOf(x)],
              g,
              active: t,
            ),
            null,
            _Do.tab,
          );
        }
      }
    }
    if (_retaps(s.active, stack, g)) {
      for (final x in _unsaid(_tabRoots[s.active], g)) {
        become(_withStack(s, [_frameOf(x)], g), null, _Do.retap);
      }
    }
  }

  /// The fewest steps from [stack] (its top last) to a node [done] holds
  /// of; null when none reaches one; the fewest steps after which a page
  /// went past a tab's bound; and whether the search stopped short.
  ///
  /// A route found within the bound is the fewest of all: when a switch
  /// past it might have been shorter, it is searched again among routes of
  /// fewer steps, with the bound raised to the deepest history at the start
  /// and the steps found (none of fewer steps puts more pages in a tab than
  /// that), from [stack] with the pages past the bound in the tab shown
  /// taken into it; the stack searched from is given too.
  (List<_Step>?, int?, bool, List<int>) _search(
    List<int> stack,
    bool Function(int node) done,
  ) {
    final (seen, end, deep, short) = _explore(
      stack,
      done,
      toward: _toward(stack, done),
    );
    if (end == null) return (null, deep, short, stack);
    final steps = _path(seen, end);
    if (deep == null || deep >= steps.length) {
      return (steps, null, false, stack);
    }
    final deepest = _deepest(stack);
    _depth = (deepest > tabDepth ? deepest : tabDepth) + steps.length;
    try {
      final deeper = _deepen(stack);
      final (seen2, end2, _, short2) = _explore(
        deeper,
        done,
        toward: _toward(deeper, done),
        below: steps.length,
      );
      if (end2 != null) return (_path(seen2, end2), null, false, deeper);
      return (steps, null, short2, stack);
    } finally {
      _depth = tabDepth;
    }
  }

  /// The steps to [end] in [seen].
  List<_Step> _path(Map<_At, (_At?, _Hop?)> seen, _At end) {
    final pred = _summaries.pred;
    final steps = <_Step>[];
    for (var at = end; seen[at]!.$1 != null; at = seen[at]!.$1!) {
      steps.insertAll(0, _open(seen[at]!.$2!, pred));
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
  List<_Step> _open(_Hop hop, List<Map<int, _Via?>> pred) => switch (hop) {
    final _Step step => [step],
    final _Summary s => [
      _Step(_Op.push, s.edge, s.entered),
      ..._within(s.entered, s.left, pred),
      _Step(_Op.pop, s.pop, s.landed!),
    ],
  };

  /// The steps at the level [g] entered from it to [x].
  List<_Step> _within(int g, int x, List<Map<int, _Via?>> pred) {
    final out = <_Step>[];
    for (var at = x; at != g;) {
      final via = pred[g][at]!;
      final summary = via.summary;
      out.insertAll(
        0,
        summary == null
            ? [_Step(_Op.replace, via.edge, at)]
            : _open(summary.landing(at), pred),
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
  /// whether the search stopped short, and whether a switch from past a
  /// tab's bound might have reached it.
  (List<int>, bool, bool) _start(
    String from,
    String? state,
    Map<String, String> chosen,
  ) =>
      _starts[[
        from,
        '$state',
        for (final (c, v) in _values(chosen)) '$c=$v',
      ].join('\u0000')] ??= _startOf(
        from,
        state,
        chosen,
      );

  /// The starts found, by page, state and values, whether their search
  /// stopped short, and whether it went past a tab's bound: one for every
  /// route from them.
  final _starts = <String, (List<int>, bool, bool)>{};

  (List<int>, bool, bool) _startOf(
    String from,
    String? state,
    Map<String, String> chosen,
  ) {
    final named = state == null ? null : _frame(from, state);
    final want = _values(chosen);
    final launch = [_launch];
    final (steps, deep, short, searched) = _search(launch, (n) {
      final f = _canon[_frameOf(n)];
      return _frames[f].page == from &&
          (named == null || f == named) &&
          _holds(want, _gOf(n));
    });
    if (steps != null) return (_replay(searched, steps).$1, false, false);
    // Not reached within the bound: alone, unless a switch from past it
    // might have reached it.
    final bounded = deep != null;
    final g = _apply(want, 0);
    if (named != null) {
      return (
        [_startAt(_node(named, _apply(_requires[named], g)), -1)],
        short,
        bounded,
      );
    }
    final unsaid = _unsaid(from, g);
    if (unsaid.isNotEmpty) {
      return ([_startAt(unsaid.first, -1)], short, bounded);
    }
    final f = _pageFrames[from]!.first;
    return ([_startAt(_node(f, _apply(_requires[f], g)), -1)], short, bounded);
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
    final (started, startShort, startBounded) = _start(from, state, valuation);
    final (steps, deep, short, stack) = from == to
        ? (<_Step>[], null, false, started)
        : _search(started, (n) => _frames[_frameOf(n)].page == to);
    final searched = !short && !startShort;
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
        startBounded ||
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
    List<int> arriving(int node) {
      if (e.move != RouteMove.pop) return _arrive(i, node);
      return [
        for (final u in _overFrames[e.from] ?? const <int>{})
          if (_frames[u].page == e.to) ..._landOn(u, node, i),
        if (!e.under) ..._arrive(i, node),
      ];
    }

    return {
      for (final f in _pageFrames[e.from] ?? const <int>[])
        if (e.can(_frames[f].state))
          _frames[f].state: _states([
            for (var g = 0; g < _valuations; g++)
              if (_holds(_requires[f], g) && _guarded(_guards[i], g))
                ...arriving(_node(f, g)),
          ]),
    };
  }

  /// The frames each page can be put over, as [_over] has their pages: of
  /// a push's, the states it happens in.
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
          RouteMove.replace => {...leaving(e), ...?over[e.from]},
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
  /// from a deep link into [entries]' pages (each its page, the state it
  /// opens in, the values of the conditions it opens while, and the tab).
  Set<int> happening(
    List<
      ({String to, String? then, Map<String, List<String>> guard, String? tab})
    >
    entries,
  ) {
    final starts = <int>{_launch};
    for (final entry in entries) {
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
          starts.add(_startAt(n, -1, named: entry.tab));
        }
      }
    }
    // With tab bars, every history would be too many: the moves with the
    // other tabs' histories left out, which take every one of a route's
    // steps, from where they start (an edge they find may still not happen).
    if (tabBars.isNotEmpty) {
      return {
        for (final s in starts)
          for (final (id, bound) in [
            for (final b in [
              _bound([s]),
            ])
              for (final id in b.moves.keys) (id, b),
          ])
            ..._outs(id < _canonCount ? id : bound.shown(id, _node)),
      };
    }
    final (seen, _, _, _) = _explore(
      const [],
      (_) => false,
      alone: [...starts],
      limited: false,
    );
    return {for (final (f, _, _) in seen.keys) ..._outs(f)};
  }
}

typedef _Summaries = ({List<Map<int, int>> dist, List<Map<int, _Via?>> pred});

/// A node of the search: the top, how many of the start's frames are under
/// it (-1: a level pushed and not left again; [_abovePast], such a level
/// over a page in a tab's history past the bound), and the shell at the
/// bottom (-1 for none).
typedef _At = (int, int, int);

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

/// A binary heap on (d, then the order pushed): the same route each time.
class _Heap<T> {
  final _items = <(int, int, T)>[];
  var _count = 0;

  bool get isNotEmpty => _items.isNotEmpty;

  static bool _less<T>((int, int, T) a, (int, int, T) b) =>
      a.$1 < b.$1 || (a.$1 == b.$1 && a.$2 < b.$2);

  void push(int d, T value) {
    final a = _items..add((d, _count++, value));
    for (var i = a.length - 1; i > 0;) {
      final p = (i - 1) >> 1;
      if (_less(a[p], a[i])) break;
      _swap(p, i);
      i = p;
    }
  }

  (int, T) pop() {
    final a = _items;
    final top = a.first;
    final last = a.removeLast();
    if (a.isNotEmpty) {
      a[0] = last;
      for (var i = 0; ;) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < a.length && _less(a[l], a[m])) m = l;
        if (r < a.length && _less(a[r], a[m])) m = r;
        if (m == i) break;
        _swap(m, i);
        i = m;
      }
    }
    return (top.$1, top.$3);
  }

  void _swap(int i, int j) {
    final t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;
  }
}
