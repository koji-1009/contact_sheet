import 'dart:convert';
import 'dart:math' as math;

import 'package:contact_sheet/src/layout.dart';
import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/sheet.dart';
import 'package:contact_sheet/src/tree.dart';
import 'package:crypto/crypto.dart';
import 'package:shutter/shutter.dart';

/// The static part of the id shutter gives the shots of a `@Preview`: the
/// preview's file in the project it is shot in, its function, and the
/// annotation's place among those on it (see shutter's manual, "Ids").
String staticIdOf(SheetState state) => sha256
    .convert(utf8.encode('${state.projectFile}|${state.symbol}|${state.index}'))
    .toString()
    .substring(0, 16);

/// The id shutter gives the shot of [state]: the static part, and which of
/// the annotation's `Preview`s it is.
String shotIdOf(SheetState state) => '${staticIdOf(state)}.${state.runtime}';

/// A shot among the shots of both projects, the app and the sheet package,
/// drawn as either platform, whose ids may be alike: [id] shot in the sheet
/// package or the app, as [platform].
String shotKey({
  required bool inSheetPackage,
  required String id,
  VariantPlatform platform = VariantPlatform.ios,
}) => '${platform.name}/${projectOf(inSheetPackage: inSheetPackage)}/$id';

/// The shot of [state] as [platform] draws it, as [shotKey] names it.
String shotKeyOf(
  SheetState state, [
  VariantPlatform platform = VariantPlatform.ios,
]) => shotKey(
  inSheetPackage: state.inSheetPackage,
  id: shotIdOf(state),
  platform: platform,
);

/// The project a preview is shot in, as `sheet.json` names it.
String projectOf({required bool inSheetPackage}) =>
    inSheetPackage ? 'sheet' : 'app';

/// What the app changed since its sheet was written: the app's files that
/// differ from what it was written from, or null when git does not know the
/// [commit]. A hint: a change does not make the sheet wrong.
typedef SheetDrift = ({String commit, List<String>? changed});

/// A label's size on the map, at 11 logical pixels: a full-width character
/// is about as wide as it is high, another about half that. An estimate,
/// as the text is drawn by whatever shows the map, in its own fonts.
(double, double) labelSize(String text) {
  var width = 0.0;
  for (final rune in text.runes) {
    width += _wide(rune) ? 11 : (rune == 0x20 ? 3.2 : 6.4);
  }
  return (width + 8, 17);
}

bool _wide(int r) =>
    (r >= 0x1100 && r <= 0x115f) ||
    (r >= 0x2e80 && r <= 0xa4cf) ||
    (r >= 0xac00 && r <= 0xd7a3) ||
    (r >= 0xf900 && r <= 0xfaff) ||
    (r >= 0xfe30 && r <= 0xfe4f) ||
    (r >= 0xff00 && r <= 0xff60) ||
    (r >= 0xffe0 && r <= 0xffe6) ||
    r >= 0x20000;

/// The words for how a transition moves.
String kindName(Messages m, NavigationKind kind) => switch (kind) {
  NavigationKind.push => m.kindPush,
  NavigationKind.go => m.kindGo,
  NavigationKind.replace => m.kindReplace,
  NavigationKind.pop => m.kindPop,
  NavigationKind.redirect => m.kindRedirect,
};

/// What an arrow says, in three parts, in this order: [code], what only the
/// code names (a key, a widget class tapped); [plain], what anyone reads
/// (what is on the screen, the state it needs, a redirect); and [kind], how
/// the code keeps its pages (go, replace). [code] and [kind] are shown to
/// developers only.
typedef EdgeLabel = ({String? code, String? plain, String? kind});

/// A part of what anyone reads of an arrow's label: what is done
/// ([LabelPart.does]), a state or the conditions' values it needs
/// ([LabelPart.when]), or a redirect ([LabelPart.kind]). The map draws each
/// apart, so the parts read apart.
enum LabelPart { does, when, kind }

/// Which app an export was drawn from: its version (the pubspec's), and the
/// commit and branch it was at, when git knows them.
typedef SheetRelease = ({String? version, String? commit, String? branch});

/// The map of a sheet: the sheet with its shots, laid out, in [m]'s words.
class SheetMap {
  SheetMap(
    this.sheet, {
    required this.shots,
    required this.m,
    this.failed = const {},
    this.drift,
    this.release,
  });

  final Sheet sheet;

  /// shutter's shot of each state, by [shotKeyOf].
  final Map<String, ShotResult> shots;

  /// The preview files shutter could not take, by the sheet's path, and
  /// why: each of their states is an error.
  final Map<String, String> failed;
  final Messages m;
  final SheetDrift? drift;
  final SheetRelease? release;

  /// The device size a state is drawn at when it has no image.
  static const fallbackSize = (390.0, 844.0);

  late final MapLayout layout = MapLayout.of(
    sheet,
    (page) => sizeOf(page.states.first),
    gap: _columnGap,
    labelOf: edgeLabel,
  );

  /// The pages as a tree, top to bottom, each the size the map draws it.
  late final PageTree tree = PageTree.of(
    sheet,
    layout.nodes,
    labelOf: treeLabel,
    sizeOf: labelSize,
  );

  /// The words on a page's branch in the tree: what its transition says, as
  /// on the map; a tab, its words, or its page's name where only the code
  /// names it.
  String? treeLabel(TreeLink link) => switch (link) {
    (edge: final edge?, tab: _) => edgeLabel(edge),
    (edge: _, tab: final tab?) =>
      tab.trigger.namedInCode
          ? sheet.pageOf(tab.page)!.label
          : tab.trigger.what,
    _ => null,
  };

  /// The room between columns: enough for the widest arrow label to lie
  /// between two pages, within [MapLayout.maxColumnGap].
  double get _columnGap {
    var widest = 0.0;
    for (final edge in sheet.edges) {
      if (edgeLabel(edge) case final label?) {
        widest = math.max(widest, labelSize(label).$1);
      }
    }
    return (widest + 16).clamp(MapLayout.columnGap, MapLayout.maxColumnGap);
  }

  /// Where each deep link's label is, and each arrow's, off them.
  late final Map<SheetEntry, Box> entryLabels = layout.placeEntryLabels(
    labelSize,
  );
  late final Map<SheetEdge, Box> edgeLabels = layout.placeEdgeLabels(
    edgeLabel,
    labelSize,
    avoid: entryLabels.values,
  );

  /// Where each bundle's label is, off the others.
  late final Map<EdgeBundle, Box> bundleLabels = layout.placeBundleLabels(
    bundleLabel,
    labelSize,
    avoid: [...entryLabels.values, ...edgeLabels.values],
  );

  /// The size of the map drawn: the layout's, and as far right and down as
  /// a label lies.
  late final (double, double) canvas = () {
    var (w, h) = (layout.width, layout.height);
    for (final box in [
      ...entryLabels.values,
      ...edgeLabels.values,
      ...bundleLabels.values,
    ]) {
      w = math.max(w, box.right + 8);
      h = math.max(h, box.bottom + 8);
    }
    return (w, h);
  }();

  /// What a bundle says: what each of its arrows says, and how many.
  String bundleLabel(EdgeBundle bundle) =>
      [?edgeLabel(bundle.edges.first), bundleCount(bundle)].join(' ');

  /// How many arrows [bundle] is: `×3`, or, from every page, said so.
  String bundleCount(EdgeBundle bundle) =>
      bundle.edges.first.anywhere ? m.fromAnywhere : '×${bundle.edges.length}';

  /// The shot of [state] in [variant] (the first by default): the one it
  /// names, as the variant's platform draws it; or, for a variant naming a
  /// `Preview`, the one of that name its annotation gives.
  ShotResult? shotOf(SheetState state, [SheetVariant? variant]) {
    final v = variant ?? sheet.variants.first;
    final preview = v.preview;
    if (failed[state.file] case final error?) {
      return ShotResult(
        id: shotIdOf(state),
        status: ShotStatus.error,
        name: preview ?? state.symbol,
        error: error,
      );
    }
    if (preview == null) return shots[shotKeyOf(state, v.platform)];
    final given =
        _byStatic[shotKey(
          inSheetPackage: state.inSheetPackage,
          id: staticIdOf(state),
          platform: v.platform,
        )];
    return given?.where((s) => s.name == preview).firstOrNull;
  }

  /// The shots by their keys without the runtime part: those one
  /// annotation gives.
  late final Map<String, List<ShotResult>> _byStatic = () {
    final all = <String, List<ShotResult>>{};
    for (final MapEntry(:key, :value) in shots.entries) {
      (all[key.substring(0, key.lastIndexOf('.'))] ??= []).add(value);
    }
    return all;
  }();

  /// The image of [state] in [variant], if shutter drew it.
  String? pngOf(SheetState state, [SheetVariant? variant]) =>
      switch (shotOf(state, variant)) {
        ShotResult(status: ShotStatus.ok, :final png?) => png,
        _ => null,
      };

  /// The size [state] was shot at in [variant].
  (double, double) sizeOf(SheetState state, [SheetVariant? variant]) =>
      switch (shotOf(state, variant)?.size) {
        final size? => (size.width, size.height),
        null => fallbackSize,
      };

  /// The file name of [state]'s image in [variant] in an export (named by
  /// the shot, and the platform when it is not iOS); null when it has none.
  String? imageNameOf(SheetState state, [SheetVariant? variant]) {
    final v = variant ?? sheet.variants.first;
    final shot = shotOf(state, v);
    if (shot == null || pngOf(state, v) == null) return null;
    return [
      if (state.inSheetPackage) 'sheet-',
      if (v.platform != VariantPlatform.ios) '${v.platform.name}-',
      '${shot.id}.png',
    ].join();
  }

  /// What an arrow says: its trigger, the state it needs, the conditions'
  /// values it needs, and how it moves when the line does not tell it (not
  /// for a push, nor for a pop, whose line is dashed): a redirect for
  /// anyone, go and replace for developers.
  EdgeLabel labelOf(SheetEdge edge) {
    final trigger = edge.trigger;
    final rest = plainLabelParts(edge);
    return (
      code: trigger != null && trigger.namedInCode ? _said(trigger) : null,
      plain: rest.isEmpty ? null : rest.map((p) => p.text).join(' / '),
      kind: switch (edge.kind) {
        NavigationKind.go || NavigationKind.replace => kindName(m, edge.kind),
        _ => null,
      },
    );
  }

  /// What anyone reads of [edge]'s label ([labelOf]'s `plain`), part by
  /// part, in its order.
  List<({String text, LabelPart part})> plainLabelParts(SheetEdge edge) {
    final trigger = edge.trigger;
    return [
      if (trigger != null && !trigger.namedInCode)
        (text: _said(trigger), part: LabelPart.does),
      if (edge.when.isNotEmpty)
        (text: edge.when.join(m.stateSeparator), part: LabelPart.when),
      for (final values in edge.guard.values)
        (text: values.join(m.stateSeparator), part: LabelPart.when),
      if (edge.kind == NavigationKind.redirect)
        (text: kindName(m, edge.kind), part: LabelPart.kind),
    ];
  }

  String _said(Trigger trigger) =>
      trigger.isBack ? m.triggerBack : trigger.what;

  /// [labelOf] whole: what a developer reads.
  String? edgeLabel(SheetEdge edge) {
    final (:code, :plain, :kind) = labelOf(edge);
    final parts = [?code, ?plain, ?kind];
    return parts.isEmpty ? null : parts.join(' / ');
  }

  /// The app's files the sheet names for [page]: its widget's, its
  /// dependencies', the code of its transitions out and of the deep links
  /// into it. Relative to the app, with `/`.
  static Set<String> filesOf(Sheet sheet, SheetPage page) => {
    ?page.source,
    for (final d in sheet.dependenciesOf(page)) ?d.source,
    for (final e in sheet.edges)
      if (e.from == page.id) ?e.source,
    for (final e in sheet.entries)
      if (e.to == page.id) ?e.source,
  };

  /// Of what changed since the basis, the files the sheet names for [page].
  List<String> changedFor(SheetPage page) {
    final changed = drift?.changed;
    if (changed == null) return const [];
    final files = filesOf(sheet, page);
    return [
      for (final file in changed)
        if (files.contains(file)) file,
    ];
  }

  /// Of what changed since the basis, the app's code (`lib/`) the sheet names
  /// for no page, nor as a preview: a page the sheet does not have yet may be
  /// in it.
  List<String> get unmapped {
    final changed = drift?.changed;
    if (changed == null) return const [];
    final named = {
      for (final page in sheet.pages) ...filesOf(sheet, page),
      for (final page in sheet.pages)
        for (final state in page.states)
          if (!state.inSheetPackage) state.file,
    };
    return [
      for (final file in changed)
        if (file.startsWith('lib/') &&
            file.endsWith('.dart') &&
            !named.contains(file))
          file,
    ];
  }

  /// The version of [json]'s shape, for tools that read it.
  static const schemaVersion = 1;

  /// The data of an export, which `index.html` is drawn from: the pages with
  /// where they sit, the image of each state, the edges with their curves,
  /// and the deep links. Only the labels are in [m]'s words.
  Map<String, Object?> json({required String app, DateTime? at}) {
    List<double> point(Point p) => [_round(p.x), _round(p.y)];
    Map<String, double> box(Box b) => {
      'x': _round(b.left),
      'y': _round(b.top),
      'width': _round(b.width),
      'height': _round(b.height),
    };
    final drift = this.drift;
    final release = this.release;
    // Which transition, which deep link: the same from one export to the
    // next; ` #2` on the second of a key written twice.
    Map<T, String> keyed<T>(Iterable<T> all, String Function(T) keyOf) {
      final count = <String, int>{};
      return {
        for (final x in all)
          x: switch (count.update(keyOf(x), (n) => n + 1, ifAbsent: () => 1)) {
            1 => keyOf(x),
            final n => '${keyOf(x)} #$n',
          },
      };
    }

    final edgeKeys = keyed(sheet.edges, (e) => e.key);
    final entryKeys = keyed(sheet.entries, (e) => e.key);
    return {
      'schemaVersion': schemaVersion,
      'app': app,
      'locale': m.localeName,
      'generatedAt': (at ?? DateTime.now()).toUtc().toIso8601String(),
      // What the app keeps across its pages; the first value, at launch.
      'conditions': [
        for (final c in sheet.conditions)
          {'name': c.name, 'values': c.values, 'source': c.source},
      ],
      // The tab bars whose tabs each keep their own history.
      'tabs': [
        for (final bar in sheet.tabBars)
          {
            'pages': [
              for (final tab in bar.tabs)
                {
                  'page': tab.page,
                  'trigger': tab.trigger.toString(),
                  'if': tab.guard,
                },
            ],
            'retap': bar.retapFirst ? 'first' : 'stay',
            'source': bar.source,
          },
      ],
      // The ways every state is shot, the first the map's.
      'variants': [
        for (final v in sheet.variants)
          {'name': v.name, 'platform': v.platform.name, 'preview': v.preview},
      ],
      // Which app it was drawn from.
      if (release != null)
        'release': {
          'version': release.version,
          'commit': release.commit,
          'branch': release.branch,
        },
      if (drift != null)
        'basis': {
          'commit': drift.commit,
          'found': drift.changed != null,
          'changed': drift.changed ?? const <String>[],
          'unmapped': unmapped,
        },
      'canvas': {
        'width': _round(canvas.$1),
        'height': _round(canvas.$2),
        // The page's label under its image, in each page's box below.
        'labelHeight': MapLayout.labelHeight,
      },
      // Each section's island on the map; unnamed for the pages without.
      'sections': [
        for (final island in layout.sections)
          {'name': island.name, ...box(island.box)},
      ],
      'pages': [
        for (final page in sheet.pages)
          {
            'id': page.id,
            'label': page.label,
            'section': page.section,
            'widget': page.widget,
            'source': page.source,
            'path': page.path,
            'route': page.route,
            'memo': page.memo,
            'links': [
              for (final link in page.links)
                {'label': link.label, 'url': link.url},
            ],
            'dependencies': [
              for (final d in sheet.dependenciesOf(page))
                {'name': d.name, 'target': d.target, 'source': d.source},
            ],
            'sheetChanged': changedFor(page),
            'tab': page.tabs,
            ...box(layout.nodes[page.id]!),
            'states': [for (final state in page.states) _state(state)],
          },
      ],
      'edges': [
        for (final edge in sheet.edges)
          {
            'key': edgeKeys[edge],
            'from': edge.from,
            'to': edge.to,
            'trigger': edge.trigger?.toString(),
            'item': edge.item,
            // Back to the page under it, whichever: one of those it can be
            // over; from every page.
            'under': edge.under,
            'anywhere': edge.anywhere,
            'tab': edge.tab,
            'when': edge.when,
            'if': edge.guard,
            'set': edge.sets,
            'then': edge.thenBy.isNotEmpty ? edge.thenBy : edge.then,
            // The states of `to` it can arrive in, from each state it
            // happens in, under any values of the conditions.
            'arrive': sheet.arrivals(edge),
            'kind': edge.kind.name,
            'source': edge.source,
            'label': edgeLabel(edge),
            'labelCode': labelOf(edge).code,
            'labelPlain': labelOf(edge).plain,
            'labelKind': labelOf(edge).kind,
            // What anyone reads of it, part by part.
            'labelParts': [
              for (final p in plainLabelParts(edge))
                {'text': p.text, 'part': p.part.name},
            ],
            if (layout.curveOf(edge) case (
              final s,
              final c1,
              final c2,
              final e,
            )) ...{
              'curve': [...point(s), ...point(c1), ...point(c2), ...point(e)],
              if (edgeLabels[edge] case final b?) 'labelAt': point(b.center),
            },
            if (layout.bundleWith(edge) case final b?)
              'bundle': layout.bundles.indexOf(b),
          },
      ],
      // The arrows from other sections into one page that say the same,
      // drawn as one short arrow into it.
      'bundles': [
        for (final bundle in layout.bundles)
          {
            'to': bundle.to,
            'edges': [for (final e in bundle.edges) sheet.edges.indexOf(e)],
            'label': bundleLabel(bundle),
            if (layout.bundleOf(bundle) case (final s, final e))
              'line': [...point(s), ...point(e)],
            'labelAt': point(bundleLabels[bundle]!.center),
          },
      ],
      // The pages as a tree, top to bottom: each under the page the fewest
      // steps from the app's start first reach it from.
      'tree': {
        'width': _round(tree.width),
        'height': _round(tree.height),
        'outside': tree.outside,
        'pages': [
          for (final page in sheet.pages)
            {
              'page': page.id,
              ...box(tree.nodes[page.id]!),
              'parent': tree.parent[page.id],
              'depth': tree.depth[page.id],
              'edge': switch (tree.link[page.id]!.edge) {
                final e? => sheet.edges.indexOf(e),
                null => null,
              },
              'tab': tree.link[page.id]!.tab?.page,
              if (tree.lines[page.id] case final line?)
                'line': [for (final p in line) ...point(p)],
              if (tree.labels[page.id] case final b?) ...{
                'label': treeLabel(tree.link[page.id]!),
                'labelAt': point(b.center),
              },
            },
        ],
      },
      'entries': [
        for (final entry in sheet.entries)
          {
            'key': entryKeys[entry],
            'to': entry.to,
            'via': entry.via,
            'then': entry.then,
            'if': entry.guard,
            'tab': entry.tab,
            'source': entry.source,
            if (layout.entryOf(entry) case (final s, final e))
              'line': [...point(s), ...point(e)],
            'labelAt': point(entryLabels[entry]!.center),
          },
      ],
    };
  }

  /// [state] in [variant]: its shot, size, image and error.
  Map<String, Object?> _drawn(SheetState state, SheetVariant variant) {
    final shot = shotOf(state, variant);
    final (width, height) = sizeOf(state, variant);
    final image = imageNameOf(state, variant);
    return {
      'shot': shot?.id ?? (variant.preview == null ? shotIdOf(state) : null),
      'width': width,
      'height': height,
      'image': image == null ? null : 'images/$image',
      'error': shot?.status == ShotStatus.error ? shot!.error ?? '' : null,
    };
  }

  Map<String, Object?> _state(SheetState state) => {
    'name': state.name,
    'preview': state.preview,
    'project': projectOf(inSheetPackage: state.inSheetPackage),
    'uses': state.uses,
    'data': state.data,
    'if': state.conditions,
    // In the first variant, the map's; then in each, the first again.
    ..._drawn(state, sheet.variants.first),
    'variants': [for (final v in sheet.variants) _drawn(state, v)],
  };

  static double _round(double v) => (v * 10).roundToDouble() / 10;
}
