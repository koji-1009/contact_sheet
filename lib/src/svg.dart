import 'dart:convert';

import 'package:contact_sheet/src/layout.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:contact_sheet/src/sheet.dart';

/// The map's colours, as CSS custom properties: `index.html` and the SVGs
/// all take them from here.
const mapPalette = {
  'bg': '#f6f7f9',
  'surface': '#ffffff',
  'text': '#1b1d21',
  'muted': '#5f6672',
  'line': '#d9dde3',
  'accent': '#0a84ff',
  'hover': '#eef5ff',
  'island': '#eceff3',
  'e-sheet': '#6b7280',
  'e-entry': '#0f766e',
  'changed': '#b26a00',
  'error': '#b3261e',
};

/// [mapPalette] when what shows the map is set dark.
const mapPaletteDark = {
  'bg': '#15171a',
  'surface': '#1f2226',
  'text': '#e6e8eb',
  'muted': '#a0a7b2',
  'line': '#363b42',
  'accent': '#3d9bff',
  'hover': '#1d2a3a',
  'island': '#24282d',
  'e-sheet': '#9aa3ae',
  'e-entry': '#2dd4bf',
  'changed': '#f0a64a',
  'error': '#f2a7a1',
};

String _vars(Map<String, String> palette) =>
    [for (final MapEntry(:key, :value) in palette.entries) '--$key: $value;']
        .join(' ');

const _fonts = 'system-ui, sans-serif';

/// The CSS of the map's drawing, which [mapUnder] and [mapOver] write with
/// classes: the palette, light or dark as what shows it is set, and how each
/// part is drawn.
final mapCss =
    ':root { color-scheme: light dark; ${_vars(mapPalette)} }\n'
    '@media (prefers-color-scheme: dark) { :root { ${_vars(mapPaletteDark)} } }\n'
    '''
.map-bg { fill: var(--bg); }
.island { fill: var(--island); }
.island-name { font-size: 13px; font-weight: 600; fill: var(--muted); }
path.edge { fill: none; stroke: var(--e-sheet); stroke-width: 1.5; }
path.edge.pop, g.bundle.pop path { stroke-dasharray: 6 4; }
.arrow-sheet { fill: var(--e-sheet); }
.arrow-entry { fill: var(--e-entry); }
g.entry circle { fill: var(--e-entry); }
g.entry path { fill: none; stroke: var(--e-entry); stroke-width: 1.5; stroke-dasharray: 2 3; }
g.bundle circle { fill: var(--e-sheet); }
g.bundle path { fill: none; stroke: var(--e-sheet); stroke-width: 1.5; }
a.page-link:hover .page { stroke: var(--accent); stroke-width: 2; }
.edge-label { font-size: 11px; fill: var(--muted); }
.edge-label .l-does { fill: var(--text); }
.edge-label .l-kind { font-style: italic; }
.entry .edge-label { fill: var(--e-entry); }
.edge-bg { fill: var(--surface); }
.tabbar rect { fill: var(--line); }
.tabbar rect.on { fill: var(--accent); }
''';

/// The arrowheads, as [mapUnder] names them.
const mapDefs =
    '<defs>'
    '<marker id="arrow-sheet" viewBox="0 0 10 10" refX="9" refY="5" '
    'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
    '<path class="arrow-sheet" d="M0,0 L10,5 L0,10 z"/></marker>'
    '<marker id="arrow-entry" viewBox="0 0 10 10" refX="9" refY="5" '
    'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
    '<path class="arrow-entry" d="M0,0 L10,5 L0,10 z"/></marker>'
    '</defs>';

/// What lies under the pages: the sections' islands, a tab bar under each
/// tab's first page (`g.tabbar`), the arrows (`path.edge`,
/// `data-i` the edge's place in the sheet; `pop` dashed), the deep links
/// (`g.entry`, `data-i` the entry's) and the bundles of arrows from other
/// sections (`g.bundle`, `data-i` the bundle's).
String mapUnder(SheetMap map) {
  final layout = map.layout;
  final sheet = map.sheet;
  final out = StringBuffer();
  for (final island in layout.sections) {
    final b = island.box;
    out.write(
      '<rect class="island" x="${_n(b.left)}" y="${_n(b.top)}" '
      'width="${_n(b.width)}" height="${_n(b.height)}" rx="12"/>',
    );
    if (island.name.isNotEmpty) {
      out.write(
        '<text class="island-name" x="${_n(b.left + 12)}" '
        'y="${_n(b.top + 22)}">${_esc(island.name)}</text>',
      );
    }
  }
  // Under each tab's first page, its bar (`g.tabbar`), its own tab lit.
  for (final bar in sheet.tabBars) {
    for (final tab in bar.tabs) {
      final b = layout.nodes[tab.page]!;
      final w = b.width / bar.tabs.length;
      out.write('<g class="tabbar">');
      for (final (i, t) in bar.tabs.indexed) {
        out.write(
          '<rect${t == tab ? ' class="on"' : ''} x="${_n(b.left + i * w + 1)}" '
          'y="${_n(b.bottom + 3)}" width="${_n(w - 2)}" height="3" rx="1.5"/>',
        );
      }
      out.write('</g>');
    }
  }
  final labels = {for (final p in sheet.pages) p.id: p.label};
  String label(String id) => labels[id]!;
  for (final (i, edge) in sheet.edges.indexed) {
    final curve = layout.curveOf(edge);
    if (curve == null) continue;
    final (s, c1, c2, e) = curve;
    // What a reader outside the code may see: without the code's names.
    final plain = map.labelOf(edge).plain;
    out.write(
      '<path class="edge${edge.kind == NavigationKind.pop ? ' pop' : ''}" '
      'data-i="$i" d="M${_p(s)} C${_p(c1)} ${_p(c2)} ${_p(e)}" '
      'marker-end="url(#arrow-sheet)"><title>'
      '${_esc('${label(edge.from)} → ${label(edge.to)}${plain == null ? '' : ': $plain'}')}'
      '</title></path>',
    );
  }
  for (final (i, entry) in sheet.entries.indexed) {
    final (s, e) = layout.entryOf(entry);
    out.write(
      '<g class="entry" data-i="$i"><circle cx="${_n(s.x)}" cy="${_n(s.y)}" '
      'r="3"/><path d="M${_p(s)} L${_p(e)}" marker-end="url(#arrow-entry)"/>'
      '<title>${_esc('${entry.via} → ${label(entry.to)}')}</title></g>',
    );
  }
  for (final (i, bundle) in layout.bundles.indexed) {
    final (s, e) = layout.bundleOf(bundle);
    final from = {for (final edge in bundle.edges) label(edge.from)};
    final pop = bundle.edges.every((e) => e.kind == NavigationKind.pop);
    out.write(
      '<g class="bundle${pop ? ' pop' : ''}" data-i="$i"><circle cx="${_n(s.x)}" '
      'cy="${_n(s.y)}" r="3"/><path d="M${_p(s)} L${_p(e)}" '
      'marker-end="url(#arrow-sheet)"/>'
      '<title>${_esc('${from.join(', ')} → ${label(bundle.to)}')}</title></g>',
    );
  }
  return '$out';
}

/// The words of [edge]'s label: with [plain], what anyone reads (null when
/// that is nothing); else all of it, what developers read in `.dev` spans.
/// What anyone reads is in a span for each part (`l-does`, `l-when`,
/// `l-kind`), drawn apart.
String? _labelText(SheetMap map, SheetEdge edge, {required bool plain}) {
  final (:code, plain: words, :kind) = map.labelOf(edge);
  final parts = [
    for (final (i, p) in map.plainLabelParts(edge).indexed)
      '${i == 0 ? '' : ' / '}<tspan class="l-${p.part.name}">${_esc(p.text)}</tspan>',
  ].join();
  if (plain) return words == null ? null : parts;
  if (code == null && words == null && kind == null) return null;
  return '${code == null ? '' : '<tspan class="dev">${_esc(code)}${words == null ? '' : ' / '}</tspan>'}'
      '$parts'
      '${kind == null ? '' : '<tspan class="dev">${code == null && words == null ? '' : ' / '}${_esc(kind)}</tspan>'}';
}

/// What lies over the pages: the arrows' labels (`g.lbl`, the parts for
/// developers in `.dev` spans; `pop` for an arrow back) and the deep links'
/// (`g.entry`), each on a background of its estimated size, which a browser
/// may measure again. With [plain], the labels hold only what anyone reads,
/// an arrow with nothing of that having none.
String mapOver(SheetMap map, {bool plain = false}) {
  final out = StringBuffer();
  void label(String cls, int i, Box box, String text) => out.write(
    '<g class="$cls" data-i="$i"><rect class="edge-bg" '
    'x="${_n(box.left)}" y="${_n(box.top)}" width="${_n(box.width)}" '
    'height="${_n(box.height)}" rx="4"/><text class="edge-label" '
    'x="${_n(box.center.x)}" y="${_n(box.center.y + 4)}" '
    'text-anchor="middle">$text</text></g>',
  );
  // With [plain], a background the size of what is left.
  Box fit(Box box, String? words) {
    if (!plain || words == null) return box;
    final (w, h) = labelSize(words);
    return Box.around(box.center, w, h);
  }

  for (final (i, edge) in map.sheet.edges.indexed) {
    final box = map.edgeLabels[edge];
    if (box == null) continue;
    final text = _labelText(map, edge, plain: plain);
    if (text == null) continue;
    final pop = edge.kind == NavigationKind.pop;
    label(
      'lbl${pop ? ' pop' : ''}',
      i,
      fit(box, map.labelOf(edge).plain),
      text,
    );
  }
  for (final (i, entry) in map.sheet.entries.indexed) {
    label('entry', i, map.entryLabels[entry]!, _esc(entry.via));
  }
  for (final (i, bundle) in map.layout.bundles.indexed) {
    final first = map.labelOf(bundle.edges.first);
    final count = map.bundleCount(bundle);
    final text = _labelText(map, bundle.edges.first, plain: plain);
    // Dashed, as its line, when all in it go back.
    final pop = bundle.edges.every((e) => e.kind == NavigationKind.pop);
    label(
      'blbl${pop ? ' pop' : ''}',
      i,
      fit(map.bundleLabels[bundle]!, [?first.plain, count].join(' ')),
      text == null ? count : '$text $count',
    );
  }
  return '$out';
}

/// `map.svg`: the whole map as one picture: each page's first state, its
/// label, the arrows with theirs and the deep links. The images are in it
/// ([bytesOf] reads each), so the file can be passed around alone; the text
/// is drawn by what opens it. Each page links to itself in `index.html` next
/// to it, and says its name when pointed at. With [plain], the labels hold
/// only what anyone reads (`map.svg`); without, what developers read too
/// (`map-dev.svg`).
String exportSvg(
  SheetMap map,
  List<int>? Function(SheetState) bytesOf, {
  required bool plain,
}) {
  final layout = map.layout;
  final w = _n(map.canvas.$1);
  final h = _n(map.canvas.$2);
  final out = StringBuffer()
    ..write(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" '
      'viewBox="0 0 $w $h" font-family=\'$_fonts\' font-size="11">'
      '<style>$mapCss.page { fill: var(--surface); stroke: var(--line); }\n'
      '.page-label { font-size: 12px; fill: var(--text); }</style>',
    )
    ..write(mapDefs)
    ..write('<rect class="map-bg" width="100%" height="100%"/>')
    ..write(mapUnder(map));
  for (final page in map.sheet.pages) {
    final b = layout.nodes[page.id]!;
    final box =
        'x="${_n(b.left)}" y="${_n(b.top)}" '
        'width="${_n(b.width)}" height="${_n(b.height)}"';
    out.write(
      '<a class="page-link" href="index.html#map/${_esc(Uri.encodeComponent(page.id))}">'
      '<title>${_esc(page.label)}</title><rect class="page" $box/>',
    );
    final bytes = bytesOf(page.states.first);
    if (bytes != null) {
      out.write(
        '<image $box preserveAspectRatio="xMidYMin slice" '
        'href="data:image/webp;base64,${base64Encode(bytes)}"/>',
      );
    }
    out.write(
      '<text class="page-label" x="${_n(b.center.x)}" '
      'y="${_n(b.bottom + MapLayout.labelHeight / 2 + 4)}" '
      'text-anchor="middle">${_esc(page.label)}</text></a>',
    );
  }
  out
    ..write(mapOver(map, plain: plain))
    ..write('</svg>');
  return '$out';
}

/// A coordinate to a tenth of a pixel.
String _n(double v) {
  final r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? '${r.toInt()}' : '$r';
}

String _p(Point p) => '${_n(p.x)},${_n(p.y)}';

String _esc(String text) =>
    const HtmlEscape(HtmlEscapeMode.attribute).convert(text);
