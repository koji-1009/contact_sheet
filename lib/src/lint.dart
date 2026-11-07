import 'dart:collection';
import 'dart:convert';

import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/sheet.dart';

/// What the sheet itself tells may be missing or written twice, in [m]'s
/// words: hints for the agent that writes it, not errors. The sheet is not
/// checked against the app; only against itself.
///
/// - a page no arrow reaches from the first page, and no deep link opens;
/// - a state of a page whose arrows name the states they leave from, that
///   none of them names: nothing happens from it, or an arrow is missing;
/// - a state, not a page's first nor one what it loads decides (`data`),
///   that nothing arrives in: no arrow (by its `then`, or from a state of
///   its name) nor deep link;
/// - an arrow written twice, or twice for other states where one with
///   `then` by the state it leaves says it; a deep link written twice;
/// - of the conditions: a value nothing gives but the launch, or nothing
///   names; a page with states of the conditions that has none for some of
///   their values, or two for the same; the first page with none for the
///   launch's; an arrow whose `if` no history meets where it happens, or
///   that names in `when` a state its `if` leaves out;
/// - a tag no page has, or one most pages have that some do not.
///
/// The hints the sheet's `checked` names are looked at and kept as they
/// are: left out. A key `checked` names that is no hint now is told.
List<String> lintSheet(Sheet sheet, Messages m) => [
  for (final hint in lintHints(sheet, m)) hint.message,
];

/// A hint of [lintSheet]'s: what it says, and the key the sheet's
/// `checked` names it by once it is looked at; empty for one that cannot
/// be checked.
class LintHint {
  const LintHint(this.key, this.message);

  final String key;
  final String message;
}

/// [lintSheet]'s hints, with their keys: those the sheet's `checked` names
/// left out, and one for each key it names that is no hint now.
List<LintHint> lintHints(Sheet sheet, Messages m) {
  final all = _hints(sheet, m);
  final keys = {for (final hint in all) hint.key};
  return [
    for (final hint in all)
      if (!sheet.checked.contains(hint.key)) hint,
    for (final key in sheet.checked)
      if (!keys.contains(key)) LintHint('', m.lintCheckedGone(jsonEncode(key))),
  ];
}

/// [lintHints] as the command tells them: each, and under it the key to
/// add to `checked` once it is looked at, quoted as YAML takes it.
List<String> lintLines(Sheet sheet, Messages m) => [
  for (final hint in lintHints(sheet, m)) ...[
    hint.message,
    if (hint.key.isNotEmpty) m.lintKey(jsonEncode(hint.key)),
  ],
];

/// How many of [sheet]'s hints its `checked` leaves out.
int checkedHints(Sheet sheet, Messages m) =>
    _hints(sheet, m).where((h) => sheet.checked.contains(h.key)).length;

List<LintHint> _hints(Sheet sheet, Messages m) {
  final findings = <LintHint>[];
  if (sheet.pages.isEmpty) return findings;
  final reached = <String>{
    sheet.pages.first.id,
    for (final e in sheet.entries) e.to,
  };
  // The bar a page is shown in: reached, every tab of it is, by a switch.
  final barPages = <String, SheetTabBar>{
    for (final bar in sheet.tabBars)
      for (final page in sheet.pages)
        if (bar.tabs.any(
          (t) => t.page == page.id || page.tabs.contains(t.page),
        ))
          page.id: bar,
  };
  final queue = Queue.of(reached);
  while (queue.isNotEmpty) {
    final id = queue.removeFirst();
    for (final e in sheet.edges) {
      if (e.from == id && reached.add(e.to)) queue.add(e.to);
    }
    for (final tab in barPages[id]?.tabs ?? const <SheetTab>[]) {
      if (reached.add(tab.page)) queue.add(tab.page);
    }
  }
  for (final page in sheet.pages) {
    if (!reached.contains(page.id)) {
      findings.add(
        LintHint(
          'unreachable ${page.id}',
          m.lintUnreachable(page.label, page.id),
        ),
      );
    }
  }
  for (final page in sheet.pages) {
    // An item from every page is not the page's own.
    final out = [
      for (final e in sheet.edges)
        if (e.from == page.id && !e.anywhere) e,
    ];
    if (!out.any((e) => e.when.isNotEmpty)) continue;
    // An arrow in every state leaves from each; so does a switch, in a bar.
    if (out.any((e) => e.when.isEmpty) || barPages.containsKey(page.id)) {
      continue;
    }
    final named = {for (final e in out) ...e.when};
    for (final state in page.states) {
      if (!named.contains(state.name)) {
        findings.add(
          LintHint(
            'nothing-leaves ${page.id}/${state.name}',
            m.lintUnusedState(state.name, page.label),
          ),
        );
      }
    }
  }
  for (final page in sheet.pages) {
    final into = [
      for (final e in sheet.edges)
        if (e.to == page.id) e,
    ];
    // A tab's first page opens, switched to, as nothing says which.
    final tab = sheet.tabOf(page.id);
    bool arrives(String state) =>
        (tab != null &&
            sheet.router.opening(page.id, null, tab.guard).contains(state)) ||
        sheet.entries.any(
          (e) => e.to == page.id && sheet.opening(e).contains(state),
        ) ||
        into.any(
          (e) => sheet.arrivals(e).values.any((to) => to.contains(state)),
        );
    for (final state in page.states.skip(1)) {
      if (!state.data && !arrives(state.name)) {
        findings.add(
          LintHint(
            'nothing-arrives ${page.id}/${state.name}',
            m.lintUnarrivedState(state.name, page.label),
          ),
        );
      }
    }
  }
  // By the items of `edges`, as written: an item from several pages is
  // told once.
  final told = <(int, int)>{};
  final seen = <String, int>{};
  final split = <String, SheetEdge>{};
  for (final e in sheet.edges) {
    final first = seen.putIfAbsent(e.key, () => e.item);
    if (first != e.item && told.add((first, e.item))) {
      findings.add(
        LintHint('twice ${e.key}', m.lintDuplicateEdge(first, e.item)),
      );
      continue;
    }
    if (e.when.isEmpty) continue;
    // Two that differ by the conditions they happen while are two.
    final other = split.putIfAbsent(
      [
        e.from,
        e.to,
        '${e.trigger}',
        guardKey(e.guard),
        e.kind.name,
      ].join('\u0001'),
      () => e,
    );
    if (other.item != e.item &&
        other.key != e.key &&
        told.add((other.item, e.item))) {
      findings.add(
        LintHint('split ${e.key}', m.lintSplitEdge(other.item, e.item)),
      );
    }
  }
  final entries = <String, int>{};
  for (final (i, e) in sheet.entries.indexed) {
    final first = entries.putIfAbsent(e.key, () => i);
    if (first != i) {
      findings.add(LintHint('twice ${e.key}', m.lintDuplicateEntry(first, i)));
    }
  }
  return [
    ...findings,
    ..._lintConditions(sheet, m, reached),
    ..._lintTabs(sheet, m),
    ..._lintTags(sheet, m),
  ];
}

/// The hints of the tags: one no page has; one most pages have (three
/// quarters or more), the pages without it named.
List<LintHint> _lintTags(Sheet sheet, Messages m) {
  final findings = <LintHint>[];
  final all = sheet.pages.length;
  for (final tag in sheet.tags) {
    final without = [
      for (final page in sheet.pages)
        if (!page.tags.any((t) => t.tag == tag.name)) page,
    ];
    final has = all - without.length;
    if (has == 0) {
      findings.add(
        LintHint('tag-unused ${tag.name}', m.lintTagUnused(tag.name)),
      );
    } else if (without.isNotEmpty && has * 4 >= all * 3) {
      findings.add(
        LintHint(
          'tag-missing ${tag.name}: ${without.map((p) => p.id).join(', ')}',
          m.lintTagMissing(
            tag.name,
            has,
            all,
            without.map((p) => p.label).join(', '),
          ),
        ),
      );
    }
  }
  return findings;
}

/// The hints of the tab bars whose tabs keep their histories.
List<LintHint> _lintTabs(Sheet sheet, Messages m) {
  final findings = <LintHint>[];
  for (final (i, bar) in sheet.tabBars.indexed) {
    if (bar.tabs.length < 2) {
      findings.add(LintHint('one-tab ${bar.tabs.first.page}', m.lintOneTab(i)));
    }
  }
  // The tabs a page is shown in, by their first pages.
  List<String> tabsOf(String page) => [
    if (sheet.tabOf(page) != null) page,
    ...sheet.pageOf(page)!.tabs,
  ];
  final told = <int>{};
  for (final e in sheet.edges) {
    if (!told.add(e.item)) continue;
    final from = tabsOf(e.from);
    final to = tabsOf(e.to);
    final fromTab = sheet.tabOf(e.from);
    final toTab = sheet.tabOf(e.to);
    final page = sheet.pageOf(e.to)!.label;
    // The bar's switch written as an edge: by the tab's own words, or by
    // nothing; a button on the page that goes to another tab is the page's.
    if (fromTab != null &&
        toTab != null &&
        e.from != e.to &&
        sheet.barOf(fromTab) == sheet.barOf(toTab) &&
        (e.trigger == null || '${e.trigger}' == '${toTab.trigger}')) {
      findings.add(LintHint('between-tabs ${e.key}', m.lintTabEdge(e.item)));
    } else if (to.isNotEmpty && toTab == null) {
      final push =
          e.kind == NavigationKind.push || e.kind == NavigationKind.redirect;
      if (push && from.isNotEmpty && !from.any(to.contains)) {
        findings.add(
          LintHint('not-in-tab ${e.key}', m.lintNotInTab(e.item, page)),
        );
      } else if ((push || e.kind == NavigationKind.replace) && from.isEmpty) {
        findings.add(
          LintHint('over-bar ${e.key}', m.lintTabFromOutside(e.item, page)),
        );
      } else if (e.kind == NavigationKind.go &&
          to.length > 1 &&
          e.tab == null) {
        findings.add(
          LintHint(
            'which-tab ${e.key}',
            m.lintWhichTab(e.item, page, to.first),
          ),
        );
      }
    }
  }
  for (final (i, e) in sheet.entries.indexed) {
    final to = tabsOf(e.to);
    if (sheet.tabOf(e.to) == null && to.length > 1 && e.tab == null) {
      findings.add(
        LintHint(
          'which-tab ${e.key}',
          m.lintEntryWhichTab(i, sheet.pageOf(e.to)!.label, to.first),
        ),
      );
    }
  }
  return findings;
}

/// The hints of the conditions; [reached], the pages an arrow leads to
/// from the first or a deep link opens (those not, already told).
List<LintHint> _lintConditions(Sheet sheet, Messages m, Set<String> reached) {
  final findings = <LintHint>[];
  String said(Map<String, String> values) =>
      [for (final MapEntry(:key, :value) in values.entries) '$key: $value']
          .join(', ');
  SheetState stateOf(String page, String name) =>
      sheet.pageOf(page)!.states.firstWhere((s) => s.name == name);
  // The values something gives: a set, or a then of a state of them.
  final given = <(String, String)>{
    for (final e in sheet.edges) ...[
      for (final MapEntry(:key, :value) in e.sets.entries) (key, value),
      for (final then in [?e.then, ...e.thenBy.values])
        for (final MapEntry(:key, :value) in stateOf(
          e.to,
          then,
        ).conditions.entries)
          (key, value),
    ],
    for (final entry in sheet.entries)
      if (entry.then case final then?)
        for (final MapEntry(:key, :value) in stateOf(
          entry.to,
          then,
        ).conditions.entries)
          (key, value),
  };
  final named = <(String, String)>{
    ...given,
    for (final page in sheet.pages)
      for (final state in page.states)
        for (final MapEntry(:key, :value) in state.conditions.entries)
          (key, value),
    for (final guard in [
      for (final e in sheet.edges) e.guard,
      for (final e in sheet.entries) e.guard,
    ])
      for (final MapEntry(:key, :value) in guard.entries)
        for (final v in value) (key, v),
  };
  for (final c in sheet.conditions) {
    for (final (i, value) in c.values.indexed) {
      if (!named.contains((c.name, value))) {
        findings.add(
          LintHint(
            'value-unnamed ${c.name}=$value',
            m.lintValueUnused(value, c.name),
          ),
        );
      } else if (i > 0 && !given.contains((c.name, value))) {
        findings.add(
          LintHint(
            'value-not-given ${c.name}=$value',
            m.lintValueNeverSet(value, c.name),
          ),
        );
      }
    }
  }
  // Where nothing says which state, the page shows its first, its data
  // states and its states of the conditions, those the values allow.
  bool shows(SheetPage page, Map<String, String> values) =>
      page.states.indexed.any(
        (s) =>
            (s.$1 == 0 || s.$2.data || s.$2.conditions.isNotEmpty) &&
            s.$2.conditions.entries.every((e) => values[e.key] == e.value),
      );
  final first = sheet.pages.first;
  if (!shows(first, {for (final c in sheet.conditions) c.name: c.values[0]})) {
    findings.add(
      LintHint('no-launch-state ${first.id}', m.lintNoLaunchState(first.label)),
    );
  }
  for (final page in sheet.pages) {
    final of = [
      for (final c in sheet.conditions)
        if (page.states.any((s) => s.conditions.containsKey(c.name))) c,
    ];
    if (of.isEmpty) continue;
    // Each valuation of the conditions its states name.
    var valuations = [<String, String>{}];
    for (final c in of) {
      valuations = [
        for (final g in valuations)
          for (final v in c.values) {...g, c.name: v},
      ];
    }
    for (final g in valuations) {
      if (!shows(page, g)) {
        findings.add(
          LintHint(
            'no-state ${page.id} ${guardKey({
              for (final MapEntry(:key, :value) in g.entries) key: [value],
            })}',
            m.lintNoStateUnder(page.label, said(g)),
          ),
        );
      }
    }
    final looks = <String, SheetState>{};
    for (final state in page.states) {
      if (state.data || state.conditions.isEmpty) continue;
      final key = guardKey({
        for (final MapEntry(:key, :value) in state.conditions.entries)
          key: [value],
      });
      final other = looks.putIfAbsent(key, () => state);
      if (other != state) {
        findings.add(
          LintHint(
            'same-values ${page.id}/${other.name}/${state.name}',
            m.lintTwoStatesUnder(other.name, state.name, page.label),
          ),
        );
      }
    }
  }
  final happening = sheet.router.happening([
    for (final e in sheet.entries)
      (to: e.to, then: e.then, guard: e.guard, tab: e.tab),
  ]);
  final told = <String>{};
  // An item from a page happens if one of its edges from there does (a pop
  // back to the page under it is one edge to each page it can be over).
  final happens = <(int, String), bool>{};
  // The key of the first of those edges: which the hint is.
  final keys = <(int, String), String>{};
  for (final (i, e) in sheet.edges.indexed) {
    if (e.guard.isEmpty) continue;
    final from = sheet.pageOf(e.from)!;
    for (final state in from.states) {
      if (e.when.contains(state.name) &&
          !state.allowedBy(e.guard) &&
          told.add('${e.item}\u0000${state.name}')) {
        findings.add(
          LintHint(
            'if-leaves-out ${e.key} ${state.name}',
            m.lintIfExcludesWhen(e.item, state.name),
          ),
        );
      }
    }
    if (reached.contains(e.from)) {
      happens[(e.item, e.from)] =
          (happens[(e.item, e.from)] ?? false) || happening.contains(i);
      keys.putIfAbsent((e.item, e.from), () => e.key);
    }
  }
  for (final MapEntry(key: (item, from), value: does) in happens.entries) {
    if (!does) {
      findings.add(
        LintHint(
          'if-never-met ${keys[(item, from)]}',
          m.lintGuardUnsatisfied(item, sheet.pageOf(from)!.label),
        ),
      );
    }
  }
  return findings;
}
