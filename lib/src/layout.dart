import 'dart:collection';
import 'dart:math' as math;

import 'package:contact_sheet/src/sheet.dart';

/// A point on the map, in its logical pixels.
class Point {
  const Point(this.x, this.y);

  final double x;
  final double y;

  Point operator +(Point o) => Point(x + o.x, y + o.y);
  Point operator -(Point o) => Point(x - o.x, y - o.y);
  Point operator *(double k) => Point(x * k, y * k);

  double distanceTo(Point o) => math.sqrt(_sq(x - o.x) + _sq(y - o.y));

  static double _sq(double v) => v * v;
}

/// A box on the map.
class Box {
  const Box(this.left, this.top, this.width, this.height);

  Box.around(Point center, double width, double height)
    : this(center.x - width / 2, center.y - height / 2, width, height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  Point get center => Point(left + width / 2, top + height / 2);
  Point get topLeft => Point(left, top);

  Box shift(Point by) => Box(left + by.x, top + by.y, width, height);

  /// The area [this] and [other] share.
  double overlap(Box other) {
    final w = math.min(right, other.right) - math.max(left, other.left);
    final h = math.min(bottom, other.bottom) - math.max(top, other.top);
    return w > 0 && h > 0 ? w * h : 0;
  }
}

/// A cubic curve: start, two controls, end.
typedef Curve = (Point, Point, Point, Point);

/// A section of the sheet on the map: an island holding its pages.
typedef SectionIsland = ({String name, Box box});

/// Arrows from other sections into one page, all saying the same: drawn as
/// one short arrow into the page instead of one long one from each.
typedef EdgeBundle = ({String to, List<SheetEdge> edges});

/// The side of a page an arrow leaves or comes in at. [bottom] is under
/// the page's label.
enum _Side { left, right, top, bottom }

/// How an arrow runs between its two pages, and the sides of them it
/// leaves and comes in at.
enum _Route {
  forward(_Side.right, _Side.left),
  backFromBelow(_Side.left, _Side.bottom),
  over(_Side.top, _Side.top),
  aroundDown(_Side.right, _Side.right),
  aroundUp(_Side.left, _Side.left),
  down(_Side.bottom, _Side.top),
  up(_Side.top, _Side.bottom);

  const _Route(this.from, this.to);

  final _Side from;
  final _Side to;
}

/// Where each page sits on the map, and where its arrows run: the same for
/// the HTML and the SVG, so they read alike.
///
/// Each section is an island of its own. In it, columns go by distance along
/// its arrows from where its flow comes in (the first page, an arrow from
/// another section, a deep link), so the flow reads left to right; the pages
/// no arrow in it reaches are a row of their own under the rest. The islands
/// are laid in rows, in the order the sheet first names them, so a large app
/// is a map to look over rather than a long band.
class MapLayout {
  MapLayout._(
    this.nodes,
    this.sections,
    this.width,
    this.height,
    this._sheet,
    this.bundles,
  );

  /// [sizeOf] is the screen each page's first state was shot at; [gap] the
  /// room between columns, where the arrows' labels go. [labelOf] is what an
  /// arrow says: those from other sections into one page that say the same
  /// are bundled, from [bundleFrom] of them.
  factory MapLayout.of(
    Sheet sheet,
    (double, double) Function(SheetPage) sizeOf, {
    double gap = columnGap,
    String? Function(SheetEdge)? labelOf,
  }) {
    final sectionOf = {for (final p in sheet.pages) p.id: p.section};
    // The first pages of the other tabs of a tab's bar.
    final tabsBeside = <String, List<String>>{
      for (final bar in sheet.tabBars)
        for (final tab in bar.tabs)
          tab.page: [
            for (final t in bar.tabs)
              if (t != tab) t.page,
          ],
    };
    // An edge from every page comes in from outside, as a deep link does.
    final next = <String, List<String>>{};
    for (final e in sheet.edges) {
      if (!e.anywhere && sectionOf[e.from] == sectionOf[e.to]) {
        (next[e.from] ??= []).add(e.to);
      }
    }
    // Where each section's flow comes in, first to last: the first page, an
    // arrow from another section, a deep link or an arrow from every page.
    // Each only for the pages the ones before it do not lead to.
    final seeds = <List<String>>[
      [if (sheet.pages.isNotEmpty) sheet.pages.first.id],
      [
        for (final e in sheet.edges)
          if (!e.anywhere && sectionOf[e.from] != sectionOf[e.to]) e.to,
      ],
      [
        for (final e in sheet.entries) e.to,
        for (final e in sheet.edges)
          if (e.anywhere) e.to,
      ],
    ];
    // Each island laid out on its own, from its top left.
    final islands = <({String name, Map<String, Box> nodes, Box box})>[];
    for (final name in {for (final p in sheet.pages) p.section}) {
      final pages = [
        for (final p in sheet.pages)
          if (p.section == name) p,
      ];
      final ids = {for (final p in pages) p.id};
      final depth = <String, int>{};
      void reach(Iterable<String> from) {
        final queue = Queue<String>();
        for (final id in from) {
          if (ids.contains(id) && !depth.containsKey(id)) {
            depth[id] = 0;
            queue.add(id);
          }
        }
        while (queue.isNotEmpty) {
          final id = queue.removeFirst();
          // A tab's first page: the bar's other tabs' in the same column.
          for (final to in tabsBeside[id] ?? const <String>[]) {
            if (ids.contains(to) && !depth.containsKey(to)) {
              depth[to] = depth[id]!;
              queue.add(to);
            }
          }
          for (final to in next[id] ?? const <String>[]) {
            if (!depth.containsKey(to)) {
              depth[to] = depth[id]! + 1;
              queue.add(to);
            }
          }
        }
      }

      seeds.forEach(reach);
      if (depth.isEmpty) reach([pages.first.id]);
      // The pages' first row has the room the rows below have in rowGap.
      final first = (name.isEmpty ? 0 : sectionLabelHeight) + marksHeight;
      final local = <String, Box>{};
      final columns = <int, double>{};
      Box place(SheetPage page, int column, double at) {
        final (w, h) = sizeOf(page);
        return local[page.id] = Box(
          column * (thumbWidth + gap),
          at,
          thumbWidth,
          thumbWidth * h / w,
        );
      }

      for (final page in pages) {
        final column = depth[page.id];
        if (column == null) continue;
        final box = place(page, column, columns[column] ?? first);
        columns[column] = box.bottom + labelHeight + rowGap;
      }
      var bottom = columns.values.reduce(math.max) - rowGap;
      // The pages no arrow in the section reaches, under the rest.
      final rest = [
        for (final p in pages)
          if (!depth.containsKey(p.id)) p,
      ];
      final restTop = bottom + rowGap;
      for (final (i, page) in rest.indexed) {
        final box = place(page, i, restTop);
        bottom = math.max(bottom, box.bottom + labelHeight);
      }
      final right = local.values.map((b) => b.right).reduce(math.max);
      islands.add((
        name: name,
        nodes: local,
        box: Box(
          -islandPadding,
          -islandPadding,
          right + islandPadding * 2,
          bottom + islandPadding * 2,
        ),
      ));
    }
    // The islands in rows about as wide as a screen is to its height, with
    // room beside the widest island for a small one.
    // Side by side, the room between two islands' pages is a column's: the
    // labels of the arrows between them go there.
    final across = math.max(sectionGap, gap - islandPadding * 2);
    final area = islands.fold(
      0.0,
      (sum, i) => sum + (i.box.width + across) * (i.box.height + sectionGap),
    );
    final widest = islands.fold(0.0, (w, i) => math.max(w, i.box.width));
    final rowWidth = math.max(widest * 1.3, math.sqrt(area * 1.6));
    final nodes = <String, Box>{};
    final sections = <SectionIsland>[];
    var x = margin - islandPadding;
    var y = margin - islandPadding;
    var rowHeight = 0.0;
    for (final island in islands) {
      if (x > margin - islandPadding &&
          x + island.box.width > margin - islandPadding + rowWidth) {
        x = margin - islandPadding;
        y += rowHeight + sectionGap;
        rowHeight = 0;
      }
      final at = Point(x + islandPadding, y + islandPadding);
      for (final MapEntry(:key, :value) in island.nodes.entries) {
        nodes[key] = value.shift(at);
      }
      sections.add((name: island.name, box: island.box.shift(at)));
      x += island.box.width + across;
      rowHeight = math.max(rowHeight, island.box.height);
    }
    final width =
        sections.fold(0.0, (w, s) => math.max(w, s.box.right)) + margin;
    final height =
        sections.fold(0.0, (h, s) => math.max(h, s.box.bottom)) + margin;
    // The arrows from other sections into one page that say the same, and
    // those of an item from every page, however many.
    final bundles = <EdgeBundle>[];
    final anywhere = <int, List<SheetEdge>>{};
    for (final e in sheet.edges) {
      if (e.anywhere) (anywhere[e.item] ??= []).add(e);
    }
    for (final edges in anywhere.values) {
      bundles.add((to: edges.first.to, edges: edges));
    }
    if (labelOf != null) {
      final into = <(String, String?), List<SheetEdge>>{};
      for (final e in sheet.edges) {
        if (!e.anywhere && sectionOf[e.from] != sectionOf[e.to]) {
          (into[(e.to, labelOf(e))] ??= []).add(e);
        }
      }
      for (final MapEntry(key: (to, _), value: edges) in into.entries) {
        if (edges.length >= bundleFrom) bundles.add((to: to, edges: edges));
      }
    }
    // Room for the arrows that go back over the top or round the side, and
    // for the short arrows' labels above the pages.
    final placed = MapLayout._(nodes, sections, width, height, sheet, bundles);
    var top = 0.0;
    var right = width;
    for (final e in sheet.edges) {
      final curve = placed.curveOf(e);
      if (curve == null) continue;
      final (s, c1, c2, end) = curve;
      final mid = bezier(s, c1, c2, end, 0.5);
      top = math.min(top, mid.y - 20);
      right = math.max(right, mid.x + margin);
    }
    for (final entry in sheet.entries) {
      final (s, _) = placed.entryOf(entry);
      top = math.min(top, s.y - 24);
    }
    for (final bundle in bundles) {
      final (s, _) = placed.bundleOf(bundle);
      top = math.min(top, s.y - 24);
      right = math.max(right, s.x + margin);
    }
    final shift = Point(0, -top);
    return MapLayout._(
      {
        for (final MapEntry(:key, :value) in nodes.entries)
          key: value.shift(shift),
      },
      [for (final s in sections) (name: s.name, box: s.box.shift(shift))],
      right,
      height - top,
      sheet,
      bundles,
    );
  }

  /// How many arrows from other sections into one page, saying the same,
  /// are drawn as one (those from every page always are).
  static const bundleFrom = 3;

  /// The arrows drawn as one, each into its page.
  final List<EdgeBundle> bundles;

  static const double thumbWidth = 96;
  static const double labelHeight = 28;

  /// The least room between columns, and the most: a label wider than that
  /// is placed where it covers the least.
  static const double columnGap = 88;
  static const double maxColumnGap = 200;
  static const double rowGap = 48;
  static const double margin = 48;
  static const double sectionLabelHeight = 24;
  static const double sectionGap = 56;
  static const double islandPadding = 16;

  /// Room above each page's image for the HTML's marks (a memo, links),
  /// drawn there and not on the image.
  static const double marksHeight = 22;

  /// The image of each page (without its label below), by page id.
  final Map<String, Box> nodes;

  /// The sections' islands, in the sheet's order.
  final List<SectionIsland> sections;

  /// The size of the whole map.
  final double width;
  final double height;

  final Sheet _sheet;

  /// The curve of [edge]; null when it goes from a page to itself, or is
  /// drawn in a bundle.
  Curve? curveOf(SheetEdge edge) => _curves[edge];

  /// The bundle [edge] is drawn in, if any.
  EdgeBundle? bundleWith(SheetEdge edge) => _bundleOf[edge];

  late final Map<SheetEdge, EdgeBundle> _bundleOf = {
    for (final b in bundles)
      for (final e in b.edges) e: b,
  };

  /// The short arrow of [bundle]: from outside, above to the right, into the
  /// page's top right corner. Several into one page sit side by side.
  (Point, Point) bundleOf(EdgeBundle bundle) {
    final to = nodes[bundle.to]!;
    final lane = [
      for (final b in bundles)
        if (b.to == bundle.to) b,
    ].indexOf(bundle);
    final end = Point(to.right - 12 - lane * 14.0, to.top);
    return (end + const Point(20, -30), end);
  }

  /// An arrow goes right to a later column; back to an earlier one over the
  /// top, or, from lower down, from its left into the page's bottom; within
  /// a column straight to the next page, or round the side past the pages
  /// between. The arrows at one side of a page are spread along it, in the
  /// order of the pages at their other ends, so they do not meet in a point.
  late final Map<SheetEdge, Curve> _curves = () {
    final routes = <SheetEdge, _Route>{
      for (final edge in _sheet.edges)
        if (!_bundleOf.containsKey(edge)) edge: ?_routeOf(edge),
    };
    // The arrows at each side of each page, and the page at their other end.
    final at = <(String, _Side), List<(SheetEdge, bool)>>{};
    for (final MapEntry(key: edge, value: route) in routes.entries) {
      (at[(edge.from, route.from)] ??= []).add((edge, true));
      (at[(edge.to, route.to)] ??= []).add((edge, false));
    }
    final points = <(SheetEdge, bool), Point>{};
    for (final MapEntry(key: (id, side), value: ends) in at.entries) {
      final box = nodes[id]!;
      final along = side == _Side.left || side == _Side.right;
      double other((SheetEdge, bool) end) {
        final b = nodes[end.$2 ? end.$1.to : end.$1.from]!;
        return along ? b.center.y : b.center.x;
      }

      ends.sort((a, b) => other(a).compareTo(other(b)));
      // The top's left end is the deep links'.
      final (from, to) = switch (side) {
        _Side.left || _Side.right => (
          box.top + box.height * 0.2,
          box.bottom - box.height * 0.2,
        ),
        _Side.top => (box.left + box.width * 0.35, box.right - box.width * 0.1),
        _Side.bottom => (
          box.left + box.width * 0.15,
          box.right - box.width * 0.15,
        ),
      };
      for (final (k, end) in ends.indexed) {
        final t = from + (to - from) * (k + 1) / (ends.length + 1);
        points[end] = switch (side) {
          _Side.left => Point(box.left, t),
          _Side.right => Point(box.right, t),
          _Side.top => Point(t, box.top),
          _Side.bottom => Point(t, box.bottom + labelHeight),
        };
      }
    }
    return {
      for (final MapEntry(key: edge, value: route) in routes.entries)
        edge: _curve(route, points[(edge, true)]!, points[(edge, false)]!),
    };
  }();

  /// How [edge] runs; null for one from a page to itself.
  _Route? _routeOf(SheetEdge edge) {
    if (edge.from == edge.to) return null;
    final from = nodes[edge.from]!;
    final to = nodes[edge.to]!;
    const eps = 1.0;
    if (to.center.x > from.center.x + eps) return _Route.forward;
    if (to.center.x < from.center.x - eps) {
      // From lower down, over the top would run through the pages above.
      return from.top > to.bottom ? _Route.backFromBelow : _Route.over;
    }
    final down = to.center.y > from.center.y;
    final between = nodes.values.any(
      (b) =>
          b != from &&
          b != to &&
          (b.center.x - from.center.x).abs() <= eps &&
          b.center.y > math.min(from.center.y, to.center.y) &&
          b.center.y < math.max(from.center.y, to.center.y),
    );
    if (between) {
      // Round the side: the right going down, the left going up.
      return down ? _Route.aroundDown : _Route.aroundUp;
    }
    return down ? _Route.down : _Route.up;
  }

  static Curve _curve(_Route route, Point s, Point e) {
    switch (route) {
      case _Route.forward:
        final d = (e.x - s.x) / 2;
        return (s, s + Point(d, 0), e - Point(d, 0), e);
      case _Route.backFromBelow:
        return (s, Point((s.x + e.x) / 2, s.y), Point(e.x, (s.y + e.y) / 2), e);
      case _Route.over:
        final rise = rowGap / 2 + (s.x - e.x) * 0.12 + (s.y - e.y).abs() / 2;
        final top = math.min(s.y, e.y) - rise;
        return (s, Point(s.x, top), Point(e.x, top), e);
      case _Route.aroundDown || _Route.aroundUp:
        final side = Point(
          (route == _Route.aroundDown ? 1 : -1) * columnGap * 0.45,
          0,
        );
        return (s, s + side, e + side, e);
      case _Route.down || _Route.up:
        final d = (e.y - s.y) / 2;
        return (s, s + Point(0, d), e - Point(0, d), e);
    }
  }

  /// The short arrow of [entry]: from outside, above to the left, into the
  /// page's top left corner, where no arrow between pages comes in. Several
  /// into one page sit side by side.
  (Point, Point) entryOf(SheetEntry entry) {
    final to = nodes[entry.to]!;
    final lane = [
      for (final e in _sheet.entries)
        if (e.to == entry.to) e,
    ].indexOf(entry);
    final end = to.topLeft + Point(12 + lane * 14.0, 0);
    return (end + const Point(-20, -30), end);
  }

  static Point bezier(Point a, Point b, Point c, Point d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * (t * t * t);
  }

  /// What arrow labels keep off: the pages with their labels (and, above
  /// them, their marks in the HTML, for those with a memo or links), and the
  /// sections' names, [sizeOf] giving a name's size at a label's font.
  List<Box> _keepOff((double, double) Function(String) sizeOf) => [
    for (final page in _sheet.pages)
      if (nodes[page.id] case final box?)
        page.memo != null || page.links.isNotEmpty
            ? Box(
                box.left,
                box.top - marksHeight,
                box.width,
                marksHeight + box.height + labelHeight,
              )
            : Box(box.left, box.top, box.width, box.height + labelHeight),
    for (final (:name, :box) in sections)
      if (name.isNotEmpty)
        // The name is drawn at 13px (`.island-name`), a label at 11.
        Box(box.left + 8, box.top + 4, sizeOf(name).$1 * 13 / 11, 22),
  ];

  /// Where each deep link's label goes: above where its arrow starts, or
  /// beside it, off the pages and the labels placed before it. [sizeOf] is
  /// a label's size.
  Map<SheetEntry, Box> placeEntryLabels(
    (double, double) Function(String) sizeOf,
  ) {
    final pages = _keepOff(sizeOf);
    final placed = <Box>[];
    return {
      for (final entry in _sheet.entries)
        entry: _placeAbove(entryOf(entry).$1, sizeOf(entry.via), -1, [
          ...placed,
          ...pages,
        ], placed),
    };
  }

  /// Where each bundle's [labelOf] goes: above where its arrow starts, or
  /// beside it, off the pages, the labels to [avoid] and those placed before
  /// it.
  Map<EdgeBundle, Box> placeBundleLabels(
    String Function(EdgeBundle) labelOf,
    (double, double) Function(String) sizeOf, {
    Iterable<Box> avoid = const [],
  }) {
    final keep = [...avoid, ..._keepOff(sizeOf)];
    final placed = <Box>[];
    return {
      for (final bundle in bundles)
        bundle: _placeAbove(bundleOf(bundle).$1, sizeOf(labelOf(bundle)), 1, [
          ...placed,
          ...keep,
        ], placed),
    };
  }

  /// A label of [size] above [start], or a little higher, or leaning to
  /// [side] (-1 left, 1 right): where it covers the least of [keep], near
  /// [start]. Added to [placed].
  static Box _placeAbove(
    Point start,
    (double, double) size,
    int side,
    List<Box> keep,
    List<Box> placed,
  ) {
    final (w, h) = size;
    final above = start - Point(0, h / 2 + 2);
    final step = Point(0, h + 2);
    final candidates = [
      for (var k = 0; k <= 3; k++) ...[
        above - step * k.toDouble(),
        above - step * k.toDouble() + Point(side * w / 2, 0),
      ],
    ];
    final box = _cheapest(
      candidates,
      w,
      h,
      (box) => _overlap(box, keep) * 4 + box.center.distanceTo(above) * h,
    );
    placed.add(box);
    return box;
  }

  /// Where each arrow's [labelOf] goes: on its curve, beside it, or a little
  /// above or below it; where it covers the fewest labels placed before it
  /// and those to [avoid] (above all, the deep links'), and pages, and stays
  /// near its line.
  Map<SheetEdge, Box> placeEdgeLabels(
    String? Function(SheetEdge) labelOf,
    (double, double) Function(String) sizeOf, {
    Iterable<Box> avoid = const [],
  }) {
    final placed = <SheetEdge, Box>{};
    final pages = _keepOff(sizeOf);
    final entries = avoid.toList();
    for (final edge in _sheet.edges) {
      final label = labelOf(edge);
      final curve = curveOf(edge);
      if (curve == null || label == null) continue;
      final (s, c1, c2, e) = curve;
      final (w, h) = sizeOf(label);
      final line = [for (var i = 1; i < 20; i++) bezier(s, c1, c2, e, i / 20)];
      final side = Point(w / 2 + 6, 0);
      final step = Point(0, h + 2);
      final candidates = [
        for (final t in [0.5, 0.4, 0.6, 0.3, 0.7, 0.2, 0.8])
          for (final p in [bezier(s, c1, c2, e, t)]) ...[
            p,
            p + side,
            p - side,
            for (var k = 1; k <= 3; k++) ...[
              p + step * k.toDouble(),
              p - step * k.toDouble(),
            ],
          ],
      ];
      double away(Box box) => line.map(box.center.distanceTo).reduce(math.min);
      placed[edge] = _cheapest(
        candidates,
        w,
        h,
        (box) =>
            (_overlap(box, placed.values) + _overlap(box, entries)) * 4 +
            _overlap(box, pages) +
            away(box) * h,
      );
    }
    return placed;
  }

  /// Of a [w] by [h] label centred at each of [candidates], the first that
  /// [cost]s the least; each cost worked out once.
  static Box _cheapest(
    List<Point> candidates,
    double w,
    double h,
    double Function(Box) cost,
  ) {
    Box? best;
    var least = double.infinity;
    for (final candidate in candidates) {
      final box = Box.around(candidate, w, h);
      final c = cost(box);
      if (c < least) {
        least = c;
        best = box;
      }
    }
    return best!;
  }

  static double _overlap(Box box, Iterable<Box> boxes) =>
      boxes.fold(0, (sum, b) => sum + box.overlap(b));
}
