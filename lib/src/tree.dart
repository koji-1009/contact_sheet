import 'dart:math' as math;

import 'package:contact_sheet/src/layout.dart';
import 'package:contact_sheet/src/sheet.dart';

/// How a page is reached in a [PageTree]: by a transition of the sheet
/// ([edge]), or by a tab of its bar ([tab]); neither for a root.
typedef TreeLink = ({SheetEdge? edge, SheetTab? tab});

/// The pages as a tree, top to bottom, as a site map draws an app: each
/// page under the page from which the fewest steps from the app's start
/// first reach it, by a transition forward or a tab of its bar; its
/// children its bar's other tabs, in the bar's order, then those its
/// transitions reach, in the sheet's. A transition back, one from every
/// page, or one from a page to itself, is no branch: the map and a page's
/// sentences tell those. The pages nothing from the start reaches are trees
/// of their own, after it ([outside]), each from a page none of the others
/// leads to, where there is one.
///
/// Each page is the size the map draws it ([MapLayout.nodes]); the words of
/// what reaches it ([labelOf], [sizeOf] their size) sit on its branch,
/// above it, and each page is given room for them.
class PageTree {
  PageTree._(
    this.parent,
    this.link,
    this.depth,
    this.nodes,
    this.labels,
    this.lines,
    this.outside,
    this.width,
    this.height,
  );

  factory PageTree.of(
    Sheet sheet,
    Map<String, Box> sizes, {
    required String? Function(TreeLink) labelOf,
    required (double, double) Function(String) sizeOf,
  }) {
    // What each page leads to, in order: its bar's tabs first, then its
    // transitions forward.
    final out = <String, List<(String, TreeLink)>>{};
    for (final page in sheet.pages) {
      final bars = {
        if (sheet.tabOf(page.id) case final tab?) sheet.barOf(tab),
        for (final t in page.tabs)
          if (sheet.tabOf(t) case final tab?) sheet.barOf(tab),
      };
      for (final bar in bars) {
        for (final tab in bar.tabs) {
          if (tab.page == page.id) continue;
          (out[page.id] ??= []).add((tab.page, (edge: null, tab: tab)));
        }
      }
    }
    for (final edge in sheet.edges) {
      if (edge.kind == NavigationKind.pop ||
          (edge.trigger?.isBack ?? false) ||
          edge.anywhere ||
          edge.from == edge.to) {
        continue;
      }
      (out[edge.from] ??= []).add((edge.to, (edge: edge, tab: null)));
    }

    // Breadth first from the app's start; then from each page not reached
    // yet that none of the others not reached leads to, in the sheet's
    // order; then from those left (leading to each other round), likewise.
    final parent = <String, String?>{};
    final link = <String, TreeLink>{};
    final depth = <String, int>{};
    final children = <String, List<String>>{};
    final roots = <String>[];
    void grow(String root) {
      roots.add(root);
      parent[root] = null;
      link[root] = (edge: null, tab: null);
      depth[root] = 0;
      final queue = [root];
      for (var i = 0; i < queue.length; i++) {
        final from = queue[i];
        for (final (to, how) in out[from] ?? const <(String, TreeLink)>[]) {
          if (depth.containsKey(to)) continue;
          parent[to] = from;
          link[to] = how;
          depth[to] = depth[from]! + 1;
          (children[from] ??= []).add(to);
          queue.add(to);
        }
      }
    }

    if (sheet.pages.isNotEmpty) grow(sheet.pages.first.id);
    final left = {
      for (final page in sheet.pages)
        if (!depth.containsKey(page.id)) page.id,
    };
    final ledTo = {
      for (final from in left)
        for (final (to, _) in out[from] ?? const <(String, TreeLink)>[])
          if (to != from && left.contains(to)) to,
    };
    for (final id in left) {
      if (!ledTo.contains(id) && !depth.containsKey(id)) grow(id);
    }
    for (final id in left) {
      if (!depth.containsKey(id)) grow(id);
    }

    // Each page's room across: its own (the page, or the words above it,
    // whichever is wider), or its children's side by side.
    final labelSizes = {
      for (final id in parent.keys)
        if (labelOf(link[id]!) case final words?) id: sizeOf(words),
    };
    double own(String id) =>
        math.max(sizes[id]!.width, labelSizes[id]?.$1 ?? 0) + gap;
    final across = <String, double>{};
    double measure(String id) {
      final kids = children[id] ?? const [];
      final theirs = kids.fold(0.0, (sum, k) => sum + measure(k));
      return across[id] = math.max(own(id), theirs);
    }

    for (final root in roots) {
      measure(root);
    }

    // The rows: each depth as tall as its tallest page with its label, and
    // the room for the branches and their words above the next.
    final deepest = depth.values.fold(0, math.max);
    final tallest = List.filled(deepest + 1, 0.0);
    for (final MapEntry(key: id, value: d) in depth.entries) {
      tallest[d] = math.max(tallest[d], sizes[id]!.height);
    }
    final rowTop = <double>[];
    var y = margin + outsideLabelHeight;
    for (var d = 0; d <= deepest; d++) {
      rowTop.add(y);
      y += tallest[d] + MapLayout.labelHeight + branchHeight;
    }

    final nodes = <String, Box>{};
    void place(String id, double left) {
      final size = sizes[id]!;
      final center = left + across[id]! / 2;
      nodes[id] = Box(
        center - size.width / 2,
        rowTop[depth[id]!],
        size.width,
        size.height,
      );
      final kids = children[id] ?? const [];
      final theirs = kids.fold(0.0, (sum, k) => sum + across[k]!);
      var x = left + (across[id]! - theirs) / 2;
      for (final k in kids) {
        place(k, x);
        x += across[k]!;
      }
    }

    final outside = <String>[];
    var x = margin;
    for (final (i, root) in roots.indexed) {
      if (i == 1) x += treeGap;
      if (i > 0) outside.add(root);
      place(root, x);
      x += across[root]!;
    }

    // Each branch: down from under its parent's label, across, and down
    // into the page, its words on the last part.
    final labels = <String, Box>{};
    final lines = <String, List<Point>>{};
    for (final MapEntry(key: id, value: from) in parent.entries) {
      if (from == null) continue;
      final p = nodes[from]!;
      final c = nodes[id]!;
      final start = Point(p.center.x, p.bottom + MapLayout.labelHeight);
      final turn = c.top - branchHeight + branchTurn;
      lines[id] = [
        start,
        Point(start.x, turn),
        Point(c.center.x, turn),
        Point(c.center.x, c.top),
      ];
      if (labelSizes[id] case (final w, final h)) {
        labels[id] = Box.around(Point(c.center.x, (turn + c.top) / 2), w, h);
      }
    }

    final width =
        nodes.values.fold(0.0, (w, b) => math.max(w, b.right)) + margin;
    return PageTree._(
      parent,
      link,
      depth,
      nodes,
      labels,
      lines,
      outside,
      math.max(width, x + margin),
      y - branchHeight + margin,
    );
  }

  /// The room across between two pages side by side.
  static const double gap = 32;

  /// The room between the app's tree and the trees after it.
  static const double treeGap = 96;

  static const double margin = 32;

  /// Room above the trees, for what says the ones after the first are not
  /// reached from the app's start.
  static const double outsideLabelHeight = 24;

  /// The room between a row's labels and the pages of the next, where the
  /// branches and their words go; [branchTurn] down it, they turn across.
  static const double branchHeight = 72;
  static const double branchTurn = 16;

  /// The page each page is under; null for a root.
  final Map<String, String?> parent;

  /// What reaches each page from its parent.
  final Map<String, TreeLink> link;

  /// How many steps down each page is from its root.
  final Map<String, int> depth;

  /// Where each page's image is (its label below it, as on the map).
  final Map<String, Box> nodes;

  /// Where the words of what reaches each page are.
  final Map<String, Box> labels;

  /// Each page's branch from its parent, as a polyline.
  final Map<String, List<Point>> lines;

  /// The roots of the trees after the app's: pages nothing from its start
  /// reaches.
  final List<String> outside;

  final double width;
  final double height;
}
