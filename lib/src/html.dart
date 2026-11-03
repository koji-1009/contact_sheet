import 'dart:convert';

import 'package:contact_sheet/src/map.dart';
import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/route_js.g.dart';
import 'package:contact_sheet/src/sheet.dart';
import 'package:contact_sheet/src/svg.dart';

/// The words of `index.html`, in [m]'s language. `{name}` in them is filled
/// in by the page.
Map<String, String> htmlStrings(Messages m) => {
  'tabMap': m.htmlTabMap,
  'tabTree': m.htmlTabTree,
  'treeOutside': m.htmlTreeOutside,
  'tabList': m.htmlTabList,
  'tabTable': m.htmlTabTable,
  'zoomIn': m.htmlZoomIn,
  'zoomOut': m.htmlZoomOut,
  'fit': m.htmlFit,
  'search': m.htmlSearch,
  'noMatch': m.htmlNoMatch,
  'showCode': m.htmlShowCode,
  'onMap': m.htmlOnMap,
  'inList': m.htmlInList,
  'detail': m.htmlDetail,
  'goesTo': m.htmlGoesTo,
  'comesFrom': m.htmlComesFrom,
  'statesOf': m.htmlStatesOf('{page}', '{count}'),
  'statesOfOne': m.htmlStatesOfOne('{page}'),
  'noImage': m.htmlNoImage,
  'none': m.htmlNone,
  'colFrom': m.htmlColFrom,
  'colTo': m.htmlColTo,
  'colTrigger': m.htmlColTrigger,
  'back': m.triggerBack,
  'colWhen': m.htmlColWhen,
  'whenAny': m.htmlWhenAny,
  'colKind': m.htmlColKind,
  'colCode': m.htmlColCode,
  'legendSheet': m.legendSheet,
  'legendBack': m.legendBack,
  'legendEntries': m.legendEntries,
  'show': m.htmlShow,
  'level_pages': m.htmlLevelPages,
  'level_flow': m.htmlLevelFlow,
  'level_actions': m.htmlLevelActions,
  'backToggle': m.htmlBackToggle,
  'routeButton': m.htmlRouteButton,
  'entries': m.htmlEntries,
  'colVia': m.htmlColVia,
  for (final kind in NavigationKind.values)
    'kind_${kind.name}': kindName(m, kind),
  'close': m.htmlClose,
  'outgoing': m.htmlOutgoing,
  'incoming': m.htmlIncoming,
  'basis': m.htmlBasis('{commit}'),
  'basisUnknown': m.htmlBasisUnknown('{commit}'),
  'sheetChanged': m.htmlSheetChanged,
  'dependencies': m.htmlDependencies,
  'generated': m.htmlGenerated('{date}'),
  'unmapped': m.htmlUnmapped('{count}'),
  'unmappedAbout': m.htmlUnmappedAbout,
  'states': m.htmlStates,
  'route': m.htmlRoute,
  'routeFrom': m.htmlRouteFrom,
  'routeTo': m.htmlRouteTo,
  'routeSwap': m.htmlRouteSwap,
  'routeNone': m.htmlRouteNone,
  'routeSame': m.htmlRouteSame,
  'routeSteps': m.htmlRouteSteps('{count}'),
  'routeStepsOne': m.htmlRouteStepsOne,
  'version': m.htmlVersion('{version}'),
  'inState': m.htmlInState('{state}'),
  'tap': m.htmlTap('{text}'),
  'goBack': m.htmlGoBack,
  'onItsOwn': m.htmlOnItsOwn,
  'unnamed': m.htmlUnnamed,
  'backTo': m.htmlBackTo('{page}'),
  'redirected': m.htmlRedirected,
  'arriving': m.htmlArriving('{state}'),
  'arrivingFrom': m.htmlArrivingFrom('{from}', '{state}'),
  'routeUnder': m.htmlRouteUnder('{pages}'),
  'arrivingSeparator': m.htmlArrivingSeparator,
  'conditionAnd': m.htmlConditionAnd,
  'fromAnywhere': m.fromAnywhere,
  'tabOf': m.htmlTabOf('{tab}'),
  'inTabs': m.htmlInTabs('{tabs}'),
  'tapAgain': m.htmlTapAgain('{text}'),
  'asLeft': m.htmlAsLeft,
  'routeTabs': m.htmlRouteTabs('{tabs}'),
  'routeBounded': m.htmlRouteBounded,
  'routeUnsearched': m.htmlRouteUnsearched,
  'setting': m.htmlSetting('{values}'),
  'fromHere': m.htmlFromHere,
  'toHere': m.htmlToHere,
  'enlarge': m.htmlEnlarge,
  'section': m.htmlSection,
  'stateSeparator': m.stateSeparator,
  'variant': m.htmlVariant,
  'notInVariant': m.htmlNotInVariant('{variant}'),
};

/// `index.html` of an export: one file that reads [sheet] (`sheet.json`)
/// from a JSON block inside it (so it works opened from disk or served
/// anywhere), with the images next to it in `images/`, and holds the map's
/// drawing, as `map.svg` draws it, from [map]. [strings] are its own words.
///
/// Two views of the same pages: the map, which moves to a page and the
/// pages next to it when one is chosen, and the list, one page under the
/// other, each with the pages it goes to and comes from. Each view and page
/// has its own address (`#map/<id>`, `#list/<id>`), to be passed around.
String exportHtml(
  Map<String, Object?> sheet,
  Map<String, String> strings,
  SheetMap map,
) {
  // No `<` at all in a block: it only comes inside JSON strings, where its
  // `\u` escape means the same; so neither `</script>` nor `<!--` can end
  // or escape it.
  String block(Object data) => jsonEncode(data).replaceAll('<', '\\u003c');
  final filled = {
    'TITLE': const HtmlEscape().convert('${sheet['app']}'),
    'LANG': const HtmlEscape().convert('${sheet['locale']}'),
    'MAP_CSS': mapCss,
    'MAP_DEFS': mapDefs,
    'MAP_UNDER': mapUnder(map),
    'MAP_OVER': mapOver(map),
    'SHEET_JSON': block(sheet),
    'STRINGS_JSON': block(strings),
    // Compiled from Dart; it holds no `</script` (test/route_test.dart).
    'ROUTE_JS': routeJs,
  };
  // In one pass over the template: what is filled in is never read again.
  return _template.replaceAllMapped(
    RegExp('__(${filled.keys.join('|')})__'),
    (match) => filled[match[1]]!,
  );
}

const _template = r'''<!doctype html>
<html lang="__LANG__">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__ — Contact Sheet</title>
<style>
__MAP_CSS__
* { box-sizing: border-box; }
[hidden] { display: none !important; }
body { margin: 0; font: 14px/1.5 system-ui, sans-serif; background: var(--bg); color: var(--text); }
/* What only the app's developers read: the code. */
body.plain .dev { display: none !important; }
body:not(.plain) .plain-only { display: none !important; }
header { position: sticky; top: 0; z-index: 5; background: var(--surface); border-bottom: 1px solid var(--line); padding: 8px 16px; display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; }
header h1 { font-size: 16px; margin: 0; }
#meta { display: flex; flex-wrap: wrap; gap: 0 10px; }
header input[type=search] { font: inherit; padding: 4px 10px; border: 1px solid var(--line); border-radius: 6px; min-width: 200px; }
header label { font-size: 12px; color: var(--muted); display: flex; gap: 4px; align-items: center; cursor: pointer; }
header select { font: inherit; font-size: 13px; padding: 3px 6px; border: 1px solid var(--line); border-radius: 6px; background: var(--surface); color: var(--text); }
/* Another variant than the map's: its images in the map's boxes, whole. */
:is(#canvas, #tree-canvas).contain .node img { object-fit: contain; object-position: center; background: var(--surface); }
nav { display: flex; gap: 4px; margin-left: auto; }
nav button { border: 1px solid var(--line); background: var(--surface); color: var(--text); border-radius: 6px; padding: 4px 12px; cursor: pointer; font: inherit; }
nav button[aria-selected="true"] { background: var(--accent); border-color: var(--accent); color: #fff; }
main > section { display: none; }
main > section.on { display: block; }
button.link { border: 1px solid var(--line); background: var(--surface); color: var(--accent); border-radius: 6px; padding: 1px 10px; cursor: pointer; font: inherit; font-size: 12px; }
.badge { display: inline-block; border-radius: 999px; padding: 0 8px; font-size: 12px; border: 1px solid currentColor; white-space: nowrap; }
.e-sheet { color: var(--e-sheet); } .e-entry { color: var(--e-entry); }
.changed { color: var(--changed); }
button.badge { background: none; font: inherit; font-size: 12px; cursor: pointer; }
.meta { color: var(--muted); font-size: 12px; }
code { font: 12px ui-monospace, Menlo, monospace; }
/* What the sheet says of a page: its memo and links. */
.memo { white-space: pre-wrap; margin: 6px 0 10px; padding: 8px 12px; background: var(--surface); border-left: 3px solid var(--accent); border-radius: 4px; }
.links { display: flex; flex-wrap: wrap; gap: 6px; margin: 0 0 10px; }
.links a, .links span { display: inline-flex; gap: 6px; align-items: baseline; border: 1px solid var(--line); border-radius: 999px; padding: 1px 10px; font-size: 12px; background: var(--surface); color: var(--accent); text-decoration: none; }
.links a:hover { border-color: var(--accent); background: var(--hover); }
.links a::after { content: '↗'; }
.links small { color: var(--muted); font-size: 11px; }
.links span { color: var(--muted); }
/* map */
/* Under the header, however many lines it takes (--header-h, measured). */
/* No element's id is a view's address (#map, #list, #table), or opening one would scroll to it. */
#map-view { position: relative; height: calc(100vh - var(--header-h, 52px)); height: calc(100dvh - var(--header-h, 52px)); overflow: hidden; cursor: grab; touch-action: none; }
#map-view.drag { cursor: grabbing; }
#canvas { position: absolute; left: 0; top: 0; transform-origin: 0 0; }
#canvas.moving { transition: transform .45s ease; }
#canvas svg { position: absolute; left: 0; top: 0; overflow: visible; }
#over { pointer-events: none; z-index: 1; }
.node { position: absolute; cursor: pointer; transition: opacity .3s; }
.node .img { width: 100%; border: 1px solid var(--line); background: var(--surface); overflow: hidden; }
.node img { display: block; width: 100%; height: 100%; object-fit: cover; object-position: top; }
.node .label { height: var(--label-height); display: flex; flex-direction: column; align-items: center; justify-content: center; font-size: 12px; line-height: 1.2; white-space: nowrap; }
/* Another state than its first: named under the page's name. */
.node .label small { font-size: 10px; color: var(--accent); }
.node .label small:empty { display: none; }
.node.other-state .img { border-color: var(--accent); }
/* Far out, the sections' names to go into, of a size to read. */
.island-chip { position: absolute; display: none; transform-origin: 0 0; transform: scale(var(--inv, 1)); z-index: 2; border: 1px solid var(--line); border-radius: 999px; background: var(--surface); color: var(--text); font: 600 14px/1.4 inherit; padding: 4px 14px; cursor: pointer; box-shadow: 0 2px 8px rgba(0,0,0,.12); white-space: nowrap; }
.island-chip:hover { border-color: var(--accent); color: var(--accent); }
#canvas.far .island-chip { display: block; }
#canvas.far .island-name { visibility: hidden; }
.node:hover .img { border: 2px solid var(--accent); }
.node.sel .img { border: 3px solid var(--accent); }
/* Above the image, not on it: the image stays readable. On the right, clear of the section's name. */
.node .marks { position: absolute; bottom: calc(100% + 4px); right: 0; display: flex; gap: 4px; }
.mark { background: var(--accent); color: #fff; border-radius: 999px; padding: 0 6px; font-size: 11px; line-height: 18px; }
path.edge, g.lbl, g.entry, g.bundle, g.blbl { transition: opacity .3s; }
/* A page chosen: it and the pages next to it, the rest faint. */
#canvas.focusing .node:not(.near) { opacity: .25; }
#canvas.focusing path.edge:not(.near), #canvas.focusing g.lbl:not(.near), #canvas.focusing g.entry:not(.near), #canvas.focusing g.bundle:not(.near), #canvas.focusing g.blbl:not(.near) { opacity: .12; }
/* How much the map shows: the pages alone, with the arrows, or with what
   each arrow says too. A page chosen, or a route, shows its own whatever. */
#map-view[data-level="pages"] :is(path.edge, g.entry, g.bundle):not(.near),
#map-view:is([data-level="pages"], [data-level="flow"]) :is(g.lbl, g.blbl, #over g.entry):not(.near) { visibility: hidden; pointer-events: none; }
#map-view:is([data-level="pages"], [data-level="flow"]) .node .marks,
#map-view[data-level="pages"] .legend { display: none; }
/* The arrows back, hidden when the viewer chose so: those of a page chosen,
   or of a route, stay. */
#map-view.no-back :is(path.edge.pop, g.lbl.pop, g.bundle.pop, g.blbl.pop):not(.near) { visibility: hidden; pointer-events: none; }
/* An arrow, or its label, tapped to read it: a wide line to tap, unseen. */
#under path.hit { stroke: transparent; stroke-width: 14; stroke-dasharray: none; fill: none; pointer-events: stroke; cursor: pointer; }
#over :is(g.lbl, g.blbl) { pointer-events: auto; cursor: pointer; }
.tools { position: absolute; right: 12px; top: 12px; display: flex; gap: 4px; z-index: 2; }
.tools button { border: 1px solid var(--line); background: var(--surface); color: var(--text); border-radius: 6px; min-width: 32px; height: 32px; cursor: pointer; font-size: 16px; }
.tools #routeOpen { font-size: 13px; padding: 0 10px; }
/* Under the map: how much it shows, and what its lines are. */
.bar { position: absolute; left: 12px; right: 12px; bottom: 12px; z-index: 2; display: flex; flex-wrap: wrap; gap: 8px; align-items: center; pointer-events: none; }
.bar > * { pointer-events: auto; }
.levels { display: flex; align-items: center; gap: 4px; background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 3px 3px 3px 10px; font-size: 12px; }
.levels > span { color: var(--muted); margin-right: 4px; }
.levels button { border: 1px solid var(--line); background: var(--surface); color: var(--text); border-radius: 6px; padding: 2px 10px; cursor: pointer; font: inherit; }
.levels button[aria-pressed="true"] { background: var(--accent); border-color: var(--accent); color: #fff; }
.legend { background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 5px 10px; display: flex; flex-wrap: wrap; gap: 4px 12px; font-size: 12px; }
.legend i { display: inline-block; width: 18px; height: 0; border-top: 2px solid currentColor; vertical-align: middle; margin-right: 4px; }
.legend i.dash { border-top-style: dashed; }
.legend i.dot { border-top-style: dotted; }
.legend button { border: 0; background: none; color: inherit; font: inherit; padding: 0; cursor: pointer; }
.legend button[aria-pressed="false"] { opacity: .45; text-decoration: line-through; }
/* The chosen page, beside the map. */
#card { position: absolute; right: 12px; bottom: 12px; z-index: 3; width: 320px; max-height: calc(100% - 68px); overflow: auto; overscroll-behavior: contain; background: var(--bg); border: 1px solid var(--line); border-radius: 10px; box-shadow: 0 8px 24px rgba(0,0,0,.18); padding: 10px 12px; display: none; cursor: auto; }
#card.on { display: block; }
#card h3 { margin: 0 0 2px; font-size: 15px; }
#card .actions { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
/* The transitions, as sentences. */
#card h4 { margin: 10px 0 4px; font-size: 12px; color: var(--muted); font-weight: 600; }
ul.says { margin: 0; padding: 0; list-style: none; font-size: 13px; }
ul.says li { margin: 2px 0; }
ul.says a { display: block; padding: 3px 6px; border-radius: 6px; color: var(--text); text-decoration: none; cursor: pointer; }
ul.says a:hover { background: var(--hover); }
#route ol code, ul.says code { font-size: 11px; }
/* Which of the page's states the map shows. */
.card-states { display: flex; flex-wrap: wrap; gap: 6px; margin: 8px 0 0; }
.card-states button { display: inline-flex; flex-direction: column; align-items: center; gap: 2px; border: 1px solid var(--line); border-radius: 6px; background: var(--surface); color: var(--text); padding: 3px; cursor: pointer; font: inherit; font-size: 11px; max-width: 76px; }
.card-states button[aria-pressed="true"] { border-color: var(--accent); outline: 1px solid var(--accent); }
.card-states img { width: 40px; height: 64px; object-fit: cover; object-position: top; border-radius: 3px; }
/* The route between two pages, beside the map. */
#route { position: absolute; left: 12px; top: 12px; z-index: 3; width: 340px; max-height: calc(100% - 72px); overflow: auto; overscroll-behavior: contain; background: var(--bg); border: 1px solid var(--line); border-radius: 10px; box-shadow: 0 8px 24px rgba(0,0,0,.18); padding: 10px 12px; display: none; cursor: auto; }
#route.on { display: block; }
#route h3 { margin: 0 0 8px; font-size: 14px; }
#route .close { float: right; }
#route .pick { display: grid; grid-template-columns: auto 1fr; gap: 6px 8px; align-items: center; font-size: 12px; color: var(--muted); }
#route select { font: inherit; font-size: 13px; padding: 3px 6px; border: 1px solid var(--line); border-radius: 6px; background: var(--surface); color: var(--text); min-width: 0; }
#route .row-actions { display: flex; gap: 6px; margin: 8px 0; }
#route ol { margin: 0; padding-left: 20px; font-size: 13px; }
#route li { margin: 4px 0; }
#route li small { display: block; color: var(--muted); }
/* tree: the pages top to bottom, scrolled, larger or smaller */
.tree-wrap { position: relative; }
#tree-view { height: calc(100vh - var(--header-h, 52px)); height: calc(100dvh - var(--header-h, 52px)); overflow: auto; overscroll-behavior: contain; }
#tree-sizer { position: relative; }
#tree-canvas { position: absolute; left: 0; top: 0; transform-origin: 0 0; }
#tree-canvas svg { position: absolute; left: 0; top: 0; overflow: visible; }
#tree-canvas path { fill: none; stroke: var(--e-sheet); stroke-width: 1.5; }
.tlabel { position: absolute; transform: translate(-50%, -50%); background: var(--surface); border-radius: 4px; padding: 0 4px; font-size: 11px; line-height: 17px; color: var(--muted); white-space: nowrap; }
.tlabel .l-does, .tlabel.tab { color: var(--text); }
.tlabel .l-kind { font-style: italic; }
.tree-outside { position: absolute; font-size: 13px; font-weight: 600; color: var(--muted); white-space: nowrap; }
/* list */
.wrap { padding: 16px; max-width: 1200px; margin: 0 auto; }
h2 { font-size: 15px; margin: 24px 0 8px; color: var(--muted); }
.row { background: var(--surface); border: 1px solid var(--line); border-radius: 10px; padding: 12px 14px; margin-bottom: 12px; scroll-margin-top: 64px; }
.row.hit { outline: 3px solid var(--accent); }
.row > header { position: static; padding: 0; border: 0; background: none; gap: 8px 12px; }
.row h3 { font-size: 15px; margin: 0; }
.row .actions { margin-left: auto; display: flex; gap: 6px; }
.states { display: flex; gap: 10px; flex-wrap: wrap; margin: 8px 0; }
.state { width: 150px; }
.state img, .state .none { width: 150px; border: 1px solid var(--line); display: block; background: var(--bg); border-radius: 4px; }
.state img { cursor: zoom-in; }
.state .none { display: flex; align-items: center; justify-content: center; color: var(--muted); font-size: 12px; padding: 8px; text-align: center; }
.state .none.error { color: var(--error); }
.state .name { font-size: 12px; color: var(--muted); margin-top: 4px; }
.flows { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.flows h4 { margin: 4px 0; font-size: 12px; color: var(--muted); font-weight: 600; }
.chips { display: flex; flex-wrap: wrap; gap: 6px; }
.chip { display: inline-flex; align-items: center; gap: 6px; border: 1px solid var(--line); border-radius: 8px; padding: 3px 8px 3px 3px; background: var(--bg); cursor: pointer; text-decoration: none; color: var(--text); font-size: 12px; }
.chip:hover { border-color: var(--accent); }
.chip img { width: 22px; height: 36px; object-fit: cover; object-position: top; border-radius: 3px; border: 1px solid var(--line); }
.chip small { color: var(--muted); }
.chip.entry { color: var(--e-entry); cursor: default; padding-left: 8px; }
#nomatch { display: none; color: var(--muted); }
/* table */
table { border-collapse: collapse; width: 100%; background: var(--surface); }
th, td { border-bottom: 1px solid var(--line); padding: 6px 8px; text-align: left; vertical-align: top; font-size: 13px; }
th { color: var(--muted); font-weight: 600; }
td a { color: var(--accent); text-decoration: none; cursor: pointer; }
tr.group td { border-top: 2px solid var(--line); }
#edge-table:not(.filtering) tr.again td:first-child > * { visibility: hidden; }
/* detail */
#detail { position: fixed; inset: 0; background: rgba(0,0,0,.4); display: none; z-index: 10; }
#detail.on { display: block; }
#detail .panel { position: absolute; right: 0; top: 0; bottom: 0; width: min(920px, 100%); background: var(--bg); overflow: auto; overscroll-behavior: contain; padding: 16px 20px; box-shadow: -4px 0 24px rgba(0,0,0,.2); }
#detail .close { float: right; }
#detail .state, #detail .state img, #detail .state .none { width: 240px; }
/* An image, large. */
#zoom { position: fixed; inset: 0; background: rgba(0,0,0,.75); display: none; z-index: 20; align-items: center; justify-content: center; flex-direction: column; gap: 8px; cursor: zoom-out; }
#zoom.on { display: flex; }
#zoom img { max-height: 88vh; max-width: 92vw; border-radius: 6px; background: var(--surface); }
#zoom div { color: #fff; font-size: 13px; }
.scroll { overflow-x: auto; }
/* A phone: one column, the panels across the map. */
@media (max-width: 640px) {
  header { padding: 8px 12px; }
  header input[type=search] { min-width: 0; flex: 1 1 140px; }
  nav { margin-left: 0; }
  .flows { grid-template-columns: 1fr; }
  #card { left: 12px; right: 12px; width: auto; bottom: calc(var(--bar-h, 32px) + 20px); max-height: 45%; }
  #route { right: 12px; width: auto; }
  .wrap { padding: 12px; }
}
/* On paper: the list, or the table, whole; the map is map.svg's, and from
   the map or the tree, the list is printed. */
@media print {
  header input, header label, nav, .actions, .tools, #detail, #zoom, #route, #card { display: none !important; }
  header { position: static; border: 0; }
  body:is([data-view="map"], [data-view="tree"]) :is(#sec-map, #sec-tree) { display: none; }
  body:is([data-view="map"], [data-view="tree"]) #sec-list { display: block; }
  #nomatch { display: none !important; }
  .row { break-inside: avoid; border-color: #bbb; }
  .row.hit { outline: 0; }
  tr { break-inside: avoid; }
  .wrap { max-width: none; padding: 0; }
}
</style>
</head>
<body>
<header>
  <h1 id="app"></h1>
  <div class="meta" id="meta"></div>
  <button class="badge changed" id="unmapped" hidden></button>
  <input type="search" id="search" list="pages" data-ph="search" autocomplete="off">
  <datalist id="pages"></datalist>
  <label><input type="checkbox" id="code"><span data-t="showCode"></span></label>
  <label id="variant-pick" hidden><span data-t="variant"></span><select id="variant"></select></label>
  <nav>
    <button data-tab="map" data-t="tabMap"></button>
    <button data-tab="tree" data-t="tabTree"></button>
    <button data-tab="list" data-t="tabList"></button>
    <button data-tab="table" data-t="tabTable"></button>
  </nav>
</header>
<main>
  <section id="sec-map"><div id="map-view"><div class="tools"><button id="routeOpen" data-title="route">⇢ <span data-t="routeButton"></span></button><button id="zin" data-title="zoomIn">＋</button><button id="zout" data-title="zoomOut">－</button><button id="fit" data-title="fit">⤢</button></div>
    <div id="canvas"><svg id="under">__MAP_DEFS____MAP_UNDER__</svg><svg id="over">__MAP_OVER__</svg></div>
    <div class="bar" id="bar"><div class="levels" id="levels"></div><div class="legend" id="legend"></div></div><div id="card"></div><div id="route"></div></div></section>
  <section id="sec-tree"><div class="tree-wrap"><div class="tools"><button id="tzin" data-title="zoomIn">＋</button><button id="tzout" data-title="zoomOut">－</button><button id="tfit" data-title="fit">⤢</button></div>
    <div id="tree-view"><div id="tree-sizer"><div id="tree-canvas"></div></div></div></div></section>
  <section id="sec-list"><div class="wrap"><p id="nomatch" data-t="noMatch"></p><div id="page-list"></div></div></section>
  <section id="sec-table"><div class="wrap" id="edge-table"></div></section>
</main>
<div id="detail"><div class="panel" id="panel"></div></div>
<div id="zoom"><img alt=""><div></div></div>
<script id="sheet" type="application/json">__SHEET_JSON__</script>
<script id="strings" type="application/json">__STRINGS_JSON__</script>
<script>__ROUTE_JS__</script>
<script>
const S = JSON.parse(document.getElementById('sheet').textContent);
const W = JSON.parse(document.getElementById('strings').textContent);
// The export's own words, with {name} filled in.
const T = (key, args = {}) => (W[key] ?? key).replace(/\{(\w+)\}/g, (_, k) => args[k] ?? '');
for (const el of document.querySelectorAll('[data-t]')) el.textContent = T(el.dataset.t);
for (const el of document.querySelectorAll('[data-title]')) el.title = T(el.dataset.title);
for (const el of document.querySelectorAll('[data-ph]')) el.placeholder = T(el.dataset.ph);
const $ = (s) => document.querySelector(s);
const esc = (t) => String(t ?? '').replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const pageById = Object.fromEntries(S.pages.map((p) => [p.id, p]));
const label = (id) => pageById[id].label;
const edges = S.edges;
const entries = S.entries;
// The edges, an item from every page (`from: '*'`) once.
const once = edges.filter((e, i) => !e.anywhere || edges.findIndex((x) => x.anywhere && x.item === e.item) === i);
// The tab bars whose tabs keep their histories: a tab by its first page,
// with its bar; the bar a page is shown in.
const tabItem = {}, barOfPage = {};
for (const bar of S.tabs ?? []) for (const t of bar.pages) tabItem[t.page] = { ...t, bar };
for (const p of S.pages) {
  const bar = (S.tabs ?? []).find((b) => b.pages.some((t) => t.page === p.id || p.tab.includes(t.page)));
  if (bar) barOfPage[p.id] = bar;
}
// A tab's name, in the screen's words: what its trigger says, or, where
// only the code names it (a key, a widget class), its first page's.
const tabText = (t) => {
  const how = t.trigger.split(':', 1)[0];
  return how === 'key' || how === 'type' ? label(t.page) : t.trigger.slice(how.length + 1);
};
// Which tab a page is, or is shown in.
const tabMeta = (p) => tabItem[p.id]
  ? `<div class="meta">${esc(T('tabOf', { tab: tabText(tabItem[p.id]) }))}</div>`
  : p.tab.length ? `<div class="meta">${esc(T('inTabs', { tabs: p.tab.map(label).join(T('stateSeparator')) }))}</div>` : '';
// What switches to a tab, in the screen's words.
const tapWords = (t) => t.trigger.startsWith('other:') ? tabText(t) : T('tap', { text: tabText(t) });
// What a search looks for in a page: its names, memo, states and links, and
// what is done on it (a button's words find the page it is on); with [dev],
// what developers read too (its id and path, a key or a widget class
// tapped), as only they are shown it.
const said = (e, dev) => {
  if (!e.trigger || e.trigger === 'back') return '';
  const how = e.trigger.split(':', 1)[0];
  return !dev && (how === 'key' || how === 'type') ? '' : e.trigger.slice(how.length + 1);
};
const findText = (p, dev) => [
  p.label, p.section, p.memo,
  ...(dev ? [p.path, p.id] : []),
  ...p.states.map((s) => s.name),
  ...p.links.map((l) => l.label),
  ...edges.filter((e) => e.from === p.id).map((e) => said(e, dev)),
].filter(Boolean).join(' ').toLowerCase();
// What it looks for in a transition: its pages, states, and what is done.
const findEdge = (e, dev) => [label(e.from), label(e.to), said(e, dev), ...e.when, ...Object.values(e.if).flat(), ...thenNames(e)].filter(Boolean).join(' ').toLowerCase();
// What is searched in, as the developers' information is shown or not.
const forDev = () => !document.body.classList.contains('plain');
const findIn = (el) => forDev() ? el.dataset.findDev : el.dataset.find;
// A viewer's choice, kept in their browser when it can be.
const load = (key, fallback) => { try { const v = localStorage.getItem(key); return v === null ? fallback : v === '1'; } catch { return fallback; } };
const save = (key, on) => { try { localStorage.setItem(key, on ? '1' : '0'); } catch {} };
// An arrow's words: what only the code names, for developers; what anyone
// reads; how the code keeps its pages, for developers.
const edgeWords = (e) => [
  e.labelCode ? `<span class="dev">${esc(e.labelCode)}${e.labelPlain ? ' / ' : ''}</span>` : '',
  esc(e.labelPlain ?? ''),
  e.labelKind ? `<span class="dev">${e.labelCode || e.labelPlain ? ' / ' : ''}${esc(e.labelKind)}</span>` : '',
].join('');
// What a transition is, as a sentence anyone reads: in which state, doing
// what, it leads where, arriving in which state. Shown beside a page tapped
// on the map, and along a route; the map's labels stay short.
const states = (list) => list.join(T('stateSeparator'));
function doing(e) {
  if (!e.trigger) return esc(T('onItsOwn'));
  const how = e.trigger.split(':', 1)[0];
  const what = e.trigger.slice(how.length + 1);
  if (how === 'back') return esc(T('goBack'));
  if (how === 'text' || how === 'label') return esc(T('tap', { text: what }));
  if (how === 'other') return esc(what);
  // A key or a widget class: named only in the code.
  return `<span class="plain-only">${esc(T('unnamed'))}</span><code class="dev">${esc(e.trigger)}</code>`;
}
// The states of its `to` [e] can arrive in from the state [state] of its
// page, as sheet.json resolves them under any values of the conditions:
// one, where said or kept by its name; else the page's first, those its
// data decides and those of the conditions.
const arrival = (e, state) => e.arrive[state] ?? [];
// The states the sheet writes a transition or a deep link arrives in.
const thenNames = (e) => typeof e.then === 'string' ? [e.then] : Object.values(e.then ?? {});
// What the sheet writes it arrives in, from [state] (null: not known, each
// of a `then` by state told). A state kept by its name goes unsaid: nothing
// changes.
function arriving(e, state) {
  if (typeof e.then === 'string') return esc(T('arriving', { state: e.then }));
  if (!e.then) return '';
  if (state != null) return e.then[state] ? esc(T('arriving', { state: e.then[state] })) : '';
  return esc(T('arriving', { state: Object.entries(e.then)
    .map(([from, to]) => T('arrivingFrom', { from, state: to })).join(T('arrivingSeparator')) }));
}
// In which states and while which values of the conditions [e] happens:
// each a part, the parts all needed; empty for any.
const needs = (e) => [...(e.when.length ? [states(e.when)] : []), ...Object.values(e.if).map(states)];
// The values [sets] gives the conditions.
const setting = (sets) => Object.keys(sets ?? {}).length ? esc(T('setting', { values: Object.values(sets).join(T('conditionAnd')) })) : '';
function sentence(e, { from = false, state = null, sets = e.set } = {}) {
  // Their spacing is the words': a comma and a space, or 「、」.
  const when = needs(e).length ? esc(T('inState', { state: needs(e).join(T('conditionAnd')) })) : '';
  // Going back by the back: "back to" says it once.
  const what = e.kind === 'pop' && e.trigger === 'back' ? '' : doing(e) + ' → ';
  const to = e.kind === 'pop' ? esc(T('backTo', { page: label(e.to) })) : `<b>${esc(label(e.to))}</b>`;
  const then = arriving(e, state);
  const redirected = e.kind === 'redirect' ? esc(T('redirected')) : '';
  // [from]: its page's name said first, or what to say instead.
  return `${from ? `<b>${esc(typeof from === 'string' ? from : label(e.from))}</b>: ` : ''}${when}${what}${to}${then}${redirected}${setting(sets)}`;
}
// What the sheet says of a page. Only web and mail links are followed: a
// `javascript:` one would run here.
const memoHtml = (p) => p.memo ? `<p class="memo">${esc(p.memo)}</p>` : '';
const where = (url) => { try { const u = new URL(url); return u.protocol === 'mailto:' ? u.pathname : u.host; } catch { return ''; } };
const linksHtml = (p) => p.links.length ? `<p class="links">${p.links.map((l) => /^(https?:|mailto:)/i.test(l.url)
  ? `<a href="${esc(l.url)}" target="_blank" rel="noopener noreferrer" title="${esc(l.url)}">${esc(l.label)}<small>${esc(where(l.url))}</small></a>`
  : `<span title="${esc(l.url)}">${esc(l.label)}</span>`).join('')}</p>` : '';
const codeMeta = (p) => [p.path, p.widget, p.route, p.source].filter(Boolean).map((c) => `<code>${esc(c)}</code>`).join(' · ');
// The ways every state is shot (a platform, a size), the first the map's:
// the one shown, chosen in the header, from the address or as the viewer
// last chose.
const variants = S.variants;
let variant = (() => {
  let saved = null;
  try { saved = localStorage.getItem('contact_sheet.variant'); } catch {}
  const i = variants.findIndex((v) => v.name === (new URLSearchParams(location.search).get('variant') ?? saved));
  return i < 0 ? 0 : i;
})();
// [s] as the variant shown draws it: its image, size and error.
const drawn = (s) => s.variants?.[variant] ?? s;
const variantName = () => variants[variant]?.name ?? '';
// A state shutter could not draw says why; one the variant has none of
// says so.
const stateHtml = (s) => {
  const d = drawn(s);
  return `<div class="state">${d.image
    ? `<img src="${esc(d.image)}" alt="${esc(s.name)}" loading="lazy" style="aspect-ratio:${d.width}/${d.height}" data-zoom="${esc(s.name)}">`
    : `<div class="none${d.error ? ' error' : ''}" style="aspect-ratio:${d.width}/${d.height}" title="${esc(d.error ?? '')}">${esc(d.error ?? (d.shot == null && variant ? T('notInVariant', { variant: variantName() }) : T('noImage')))}</div>`}
  <div class="name">${esc(s.name)}</div></div>`;
};

$('#app').textContent = S.app;
// When the map was exported, for anyone to tell how old it is; what the
// sheet was written against, when `contact_sheet basis` recorded it, for
// developers.
const exported = (() => {
  try { return new Date(S.generatedAt).toLocaleString(S.locale, { dateStyle: 'medium', timeStyle: 'short' }); } catch { return S.generatedAt; }
})();
// Which app: its version and branch, for anyone; its commit, for
// developers. How current: when it was exported.
const release = S.release ?? {};
$('#meta').innerHTML = [
  release.version ? `<span>${esc(T('version', { version: release.version }))}</span>` : '',
  release.branch ? `<span>${esc(release.branch)}</span>` : '',
  release.commit ? `<code class="dev">${esc(release.commit.slice(0, 10))}</code>` : '',
  `<span>${esc(T('generated', { date: exported }))}</span>`,
  S.basis ? `<span class="dev">${esc(T(S.basis.found ? 'basis' : 'basisUnknown', { commit: S.basis.commit.slice(0, 10) }))}</span>` : '',
].join('');
// The app's code changed since the basis that the sheet names for no page:
// what it says to anyone, and the files, for developers.
const unmapped = S.basis?.unmapped ?? [];
if (unmapped.length) {
  const button = $('#unmapped');
  button.hidden = false;
  button.textContent = T('unmapped', { count: unmapped.length });
  button.onclick = () => openPanel(`<h2 style="margin-top:0;color:var(--text)">${esc(T('unmapped', { count: unmapped.length }))}</h2>
    <p>${esc(T('unmappedAbout'))}</p><p class="dev">${unmapped.map((f) => `<code>${esc(f)}</code>`).join('<br>')}</p>`);
}
// The map fills what the header leaves, however many lines it wraps to.
const fitHeader = () => document.documentElement.style.setProperty('--header-h', $('body > header').offsetHeight + 'px');
fitHeader();
$('#pages').innerHTML = S.pages.map((p) => `<option value="${esc(p.label)}">${esc(p.section)}</option>`).join('');
document.documentElement.style.setProperty('--label-height', S.canvas.labelHeight + 'px');

// --- map: the drawing is the export's, as map.svg draws it ---
const map = $('#map-view');
const canvas = $('#canvas');
canvas.style.width = S.canvas.width + 'px';
canvas.style.height = S.canvas.height + 'px';
for (const svg of canvas.querySelectorAll('svg')) { svg.setAttribute('width', S.canvas.width); svg.setAttribute('height', S.canvas.height); }
const byIndex = (selector) => { const all = []; for (const el of canvas.querySelectorAll(selector)) all[el.dataset.i] = el; return all; };
const edgePaths = byIndex('#under path.edge');
const edgeLabels = byIndex('#over g.lbl');
const entryLines = byIndex('#under g.entry');
const entryLabels = byIndex('#over g.entry');
const bundles = S.bundles;
const bundleLines = byIndex('#under g.bundle');
const bundleLabels = byIndex('#over g.blbl');
// Each arrow, and each bundle's line, has a wide line over it to tap,
// unseen, shown or hidden as its own is.
const hitOf = (path) => {
  const hit = path.cloneNode(false);
  hit.classList.add('hit');
  hit.removeAttribute('marker-end');
  path.after(hit);
  return hit;
};
const edgeHits = edgePaths.map((p) => p && hitOf(p));
for (const g of bundleLines) if (g) hitOf(g.querySelector('path'));
const nodes = {};
for (const p of S.pages) {
  const n = document.createElement('div');
  n.className = 'node';
  n.dataset.id = p.id;
  n.style.left = p.x + 'px'; n.style.top = p.y + 'px'; n.style.width = p.width + 'px';
  const s = drawn(p.states[0]);
  const marks =(p.memo ? '<span class="mark">ⓘ</span>' : '') + (p.links.length ? `<span class="mark">↗ ${p.links.length}</span>` : '');
  n.innerHTML = `<div class="img" style="height:${p.height}px">${s.image ? `<img src="${esc(s.image)}" alt="${esc(p.label)}" loading="lazy">` : ''}</div><div class="label"><span>${esc(p.label)}</span><small></small></div>${marks ? `<div class="marks">${marks}</div>` : ''}`;
  n.title = T(p.states.length === 1 ? 'statesOfOne' : 'statesOf', { page: p.label, count: p.states.length });
  // In the state it shows (where an arrow arrived): what is looked at stays.
  n.addEventListener('click', () => {
    if (moved) return;
    const i = shownState[p.id] ?? 0;
    const hash = `#map/${encodeURIComponent(p.id)}${i ? '/' + encodeURIComponent(p.states[i].name) : ''}`;
    if (location.hash === hash) route(); else location.hash = hash;
  });
  // Twice: the state it shows, large.
  n.addEventListener('dblclick', () => enlarge(p.id));
  canvas.insertBefore(n, $('#over'));
  nodes[p.id] = n;
}
// The sections, to go into from the whole map, where their names are too
// small to read: a name of a size to read, whatever the map's.
const islandChips = S.sections.filter((s) => s.name).map((s) => {
  const chip = document.createElement('button');
  chip.className = 'island-chip';
  chip.textContent = s.name;
  chip.title = T('section');
  chip.style.left = s.x + 'px'; chip.style.top = s.y + 'px';
  chip.addEventListener('click', (e) => { e.stopPropagation(); if (!moved) show({ x: s.x - 24, y: s.y - 24, width: s.width + 48, height: s.height + 48 }, true); });
  canvas.appendChild(chip);
  return chip;
});
// Each label's background, at the size the browser draws its text: all
// measured first, then all set. Only while the map is shown; again when
// what a label shows changes.
let measured = false;
function backgrounds() {
  if (current !== 'map') { measured = false; return; }
  const groups = [...$('#over').querySelectorAll('g')];
  const boxes = groups.map((g) => g.querySelector('text').getBBox());
  groups.forEach((g, i) => {
    const b = boxes[i];
    const r = g.querySelector('rect');
    const empty = b.width === 0;
    r.setAttribute('x', b.x - 4); r.setAttribute('y', b.y - 2);
    r.setAttribute('width', empty ? 0 : b.width + 8); r.setAttribute('height', empty ? 0 : b.height + 4);
  });
  measured = true;
}
// How much the map shows, and what its lines are.
const levels = ['pages', 'flow', 'actions'];
$('#levels').setAttribute('role', 'group');
$('#levels').setAttribute('aria-label', T('show'));
$('#levels').innerHTML = `<span>${esc(T('show'))}</span>${levels.map((l) =>
  `<button data-level="${l}" aria-pressed="false">${esc(T('level_' + l))}</button>`).join('')}`;
// The arrows back can be hidden: on a large app they are many, and their
// dashed line says what they do.
$('#legend').innerHTML = [
  edges.some((e) => e.kind !== 'pop') ? `<span class="key e-sheet"><i></i>${esc(T('legendSheet'))}</span>` : '',
  edges.some((e) => e.kind === 'pop') ? `<button class="key e-sheet" id="backToggle" aria-pressed="true" title="${esc(T('backToggle'))}"><i class="dash"></i>${esc(T('legendBack'))}</button>` : '',
  entries.length ? `<span class="key e-entry"><i class="dot"></i>${esc(T('legendEntries'))}</span>` : '',
].join('');
if (!edges.length && !entries.length) $('#bar').style.display = 'none';
// How tall what is under the map is, for the card on a phone to sit above it.
const fitBar = () => map.style.setProperty('--bar-h', $('#bar').offsetHeight + 'px');
// The pages alone (to look at the screens), with the arrows (to see how they
// lead to each other), or with what each arrow says (the default). Kept in
// the address (?show=) to pass around, and for the viewer.
let level = (() => {
  let saved = null;
  try { saved = localStorage.getItem('contact_sheet.show'); } catch {}
  const asked = new URLSearchParams(location.search).get('show') ?? saved;
  return levels.includes(asked) ? asked : 'actions';
})();
function setLevel(l, { remember = true } = {}) {
  level = l;
  map.dataset.level = l;
  for (const b of $('#levels').querySelectorAll('[data-level]')) b.setAttribute('aria-pressed', b.dataset.level === l);
  requestAnimationFrame(fitBar);
  if (!remember) return;
  try { localStorage.setItem('contact_sheet.show', l); } catch {}
  const url = new URL(location.href);
  if (l === 'actions') url.searchParams.delete('show'); else url.searchParams.set('show', l);
  history.replaceState(null, '', url);
}
$('#levels').addEventListener('click', (e) => {
  const b = e.target.closest('[data-level]');
  if (b) setLevel(b.dataset.level);
});
setLevel(level, { remember: false });
// The arrows back, shown (the default) or hidden. Kept in the address
// (?back=hide) to pass around, and for the viewer.
function setBack(on, { remember = true } = {}) {
  map.classList.toggle('no-back', !on);
  $('#backToggle')?.setAttribute('aria-pressed', on);
  if (!remember) return;
  save('contact_sheet.back', on);
  const url = new URL(location.href);
  if (on) url.searchParams.delete('back'); else url.searchParams.set('back', 'hide');
  history.replaceState(null, '', url);
}
setBack(new URLSearchParams(location.search).get('back') === 'hide' ? false : load('contact_sheet.back', true), { remember: false });
$('#backToggle')?.addEventListener('click', () => setBack(map.classList.contains('no-back')));

let view = { x: 0, y: 0, k: 1 };
const apply = () => {
  canvas.style.transform = `translate(${view.x}px, ${view.y}px) scale(${view.k})`;
  // Far out, the sections' names stand out to go into.
  canvas.style.setProperty('--inv', 1 / view.k);
  canvas.classList.toggle('far', islandChips.length >= 4 && view.k < 0.45);
};
// Moves the map to show [box] (in map pixels) whole, gliding there; clear
// of the [left], [right], [top] and [bottom] pixels a panel takes.
function show(box, glide, { left = 0, right = 0, top = 0, bottom = 0 } = {}) {
  const m = map.getBoundingClientRect();
  if (!m.width) return;
  top = Math.min(top, m.height * 2 / 3);
  right = Math.min(right, m.width / 2);
  const w = m.width - left - right, h = Math.max(m.height - top - bottom, m.height / 3);
  const k = Math.min(w / box.width, h / box.height, 1.6);
  view = { k, x: left + (w - box.width * k) / 2 - box.x * k, y: top + (h - box.height * k) / 2 - box.y * k };
  canvas.classList.toggle('moving', glide);
  apply();
  if (glide) setTimeout(() => canvas.classList.remove('moving'), 460);
}
const whole = () => ({ x: 0, y: 0, width: S.canvas.width, height: S.canvas.height });
// Whether the panels sit beside what the map shows, or across it (a phone):
// as the CSS lays them out.
const wide = () => !matchMedia('(max-width: 640px)').matches;
// Where the map moves what it shows to, clear of the card.
const clearOfCard = (card) => wide() ? { right: card.offsetWidth + 24 } : { bottom: card.offsetHeight + $('#bar').offsetHeight + 32 };
function zoom(f, cx, cy) {
  const m = map.getBoundingClientRect();
  cx ??= m.width / 2; cy ??= m.height / 2;
  const k = Math.max(0.1, Math.min(4, view.k * f));
  view.x = cx - (cx - view.x) * (k / view.k);
  view.y = cy - (cy - view.y) * (k / view.k);
  view.k = k; apply();
}
$('#zin').onclick = () => zoom(1.25);
$('#zout').onclick = () => zoom(0.8);
$('#fit').onclick = () => go('map');

// Brings out the pages [near], the arrows [edgeOn] and the deep links
// [entryOn] say, the page [sel] chosen; the rest faint. Nothing near: all
// as drawn.
function highlight(near, edgeOn, entryOn, sel) {
  canvas.classList.toggle('focusing', near.size > 0);
  for (const [nid, n] of Object.entries(nodes)) {
    n.classList.toggle('near', near.has(nid));
    n.classList.toggle('sel', nid === sel);
  }
  edges.forEach((e, i) => {
    const on = edgeOn(i);
    edgePaths[i]?.classList.toggle('near', on);
    edgeHits[i]?.classList.toggle('near', on);
    edgeLabels[i]?.classList.toggle('near', on);
  });
  entries.forEach((en, i) => {
    const on = entryOn(i);
    entryLines[i].classList.toggle('near', on);
    entryLabels[i].classList.toggle('near', on);
  });
  // A bundle, with any arrow in it.
  bundles.forEach((b, i) => {
    const on = b.edges.some(edgeOn);
    bundleLines[i]?.classList.toggle('near', on);
    bundleLabels[i]?.classList.toggle('near', on);
  });
}
// The pages [ids] with their labels, and room around them, in map pixels.
function around(ids) {
  const boxes = [...ids].map((nid) => pageById[nid]);
  const lh = S.canvas.labelHeight;
  const x0 = Math.min(...boxes.map((q) => q.x)), y0 = Math.min(...boxes.map((q) => q.y));
  const x1 = Math.max(...boxes.map((q) => q.x + q.width)), y1 = Math.max(...boxes.map((q) => q.y + q.height + lh));
  const pad = 72;
  return { x: x0 - pad, y: y0 - pad, width: x1 - x0 + pad * 2, height: y1 - y0 + pad * 2 };
}

// Which state each page shows on the map: its first, unless another is
// chosen (beside the page, or as where an arrow arrives); its name under
// the page's then, so whoever looks knows which.
const shownState = {};
function showState(id, i) {
  const p = pageById[id];
  const s = p.states[i];
  if (!s) return;
  shownState[id] = i;
  const n = nodes[id];
  const d = drawn(s);
  n.querySelector('.img').innerHTML = d.image ? `<img src="${esc(d.image)}" alt="${esc(p.label)}">` : '';
  n.querySelector('.label small').textContent = i ? s.name : '';
  n.classList.toggle('other-state', i > 0);
}
const stateIndex = (id, name) => pageById[id].states.findIndex((s) => s.name === name);
// All pages back in their first state.
function firstStates() {
  for (const id of Object.keys(shownState)) showState(id, 0);
}
// The state of [id] chosen beside it, by name; null for its first, when it
// has more than one but none was chosen.
const chosen = (id) => pageById[id].states.length > 1 ? pageById[id].states[shownState[id] ?? 0].name : null;
// Whether [e] can happen in the state [state] of its page (null: any): one
// its `when` names, of values of the conditions its `if` allows.
const can = (e, state) => {
  if (!state) return true;
  const s = pageById[e.from].states.find((x) => x.name === state);
  return (!e.when.length || e.when.includes(state))
    && Object.entries(s?.if ?? {}).every(([c, v]) => !e.if[c] || e.if[c].includes(v));
};
const statesHtml = (p) => p.states.length < 2 ? '' : `<div class="card-states" aria-label="${esc(T('states'))}">${p.states.map((s, i) =>
  `<button data-state="${i}" aria-pressed="${(shownState[p.id] ?? 0) === i}">${drawn(s).image ? `<img src="${esc(drawn(s).image)}" alt="">` : ''}<span>${esc(s.name)}</span></button>`).join('')}</div>`;
// The transitions out of and into [p], as sentences, those out in the state
// shown; each leads to the page at its other end.
const sentences = (p) => {
  const state = shownName(p.id);
  const goes = (out[p.id] ?? []).filter((e) => can(e, state));
  const comes = into[p.id] ?? [];
  const item = (e, other, from, state) => `<li><a data-go="map/${esc(other)}">${sentence(e, { from, state })}</a></li>`;
  // In a tab bar, its tabs: a switch to each other one, and to the tab
  // shown again where that goes back to its first page.
  const bar = barOfPage[p.id];
  const own = tabItem[p.id] ? [p.id] : p.tab;
  const tabs = !bar ? [] : bar.pages.flatMap((t) => {
    // In several tabs, which is shown is not known here: each a tap.
    const again = own.length === 1 && own.includes(t.page);
    if (again && (t.page === p.id || bar.retap !== 'first')) return [];
    const when = Object.keys(t.if).length
      ? esc(T('inState', { state: Object.values(t.if).map(states).join(T('conditionAnd')) })) : '';
    const words = again ? T('tapAgain', { text: tabText(t) }) : tapWords(t);
    return [`<li><a data-go="map/${esc(t.page)}">${when}${esc(words)} → <b>${esc(label(t.page))}</b></a></li>`];
  });
  return (goes.length || tabs.length ? `<h4>${esc(T('fromHere'))}</h4><ul class="says">${goes.map((e) => item(e, e.to, false, state)).join('')}${tabs.join('')}</ul>` : '')
    + (comes.length ? `<h4>${esc(T('toHere'))}</h4><ul class="says">${comes.map((e) => e.anywhere
      ? item(e, e.to, T('fromAnywhere'), null) : item(e, e.from, true, null)).join('')}</ul>` : '');
};
// The state [id] is shown in, by name.
const shownName = (id) => pageById[id].states[shownState[id] ?? 0].name;

// The page chosen on the map, and the pages next to it: the map moves to
// show them, the rest faint. In the state chosen beside it: only the arrows
// out that can happen in it, and the pages they arrive at in their states.
let focused = null;
let routed = null;
function focus(id, glide, { state } = {}) {
  const p = pageById[id];
  if (focused !== (p ? id : null) || picked) firstStates();
  focused = p ? id : null;
  routed = null;
  picked = null;
  $('#route').classList.remove('on');
  const card = $('#card');
  if (!focused) { highlight(new Set(), () => false, () => false, null); card.classList.remove('on'); show(whole(), glide); return; }
  if (state != null) {
    // Another state of the page: the pages its arrows arrived at, back first.
    firstStates();
    if (stateIndex(id, state) >= 0) showState(id, stateIndex(id, state));
  }
  const here = shownName(id);
  const near = new Set([focused]);
  // What the map moves to show: an arrow in a bundle is drawn only at its
  // end, so its far page is left to the card.
  const frame = new Set([focused]);
  const on = new Set();
  edges.forEach((e, i) => {
    const drawnHere = e.bundle == null;
    // An edge from every page is the page it goes to's, not each page's.
    if (e.from === focused && !e.anywhere && can(e, here)) {
      on.add(i); near.add(e.to);
      if (drawnHere) frame.add(e.to);
      // Of the states it can arrive in, the first.
      const then = arrival(e, here)[0];
      if (then && e.to !== focused) showState(e.to, Math.max(0, stateIndex(e.to, then)));
    }
    if (e.to === focused) {
      on.add(i);
      if (!e.anywhere) near.add(e.from);
      if (drawnHere) frame.add(e.from);
    }
  });
  highlight(near, (i) => on.has(i), (i) => entries[i].to === focused, focused);
  card.innerHTML = `<h3>${esc(p.label)}</h3><div class="meta">${esc(p.section)}</div>${tabMeta(p)}<div class="meta dev">${codeMeta(p)}</div>${statesHtml(p)}${memoHtml(p)}${linksHtml(p)}${sentences(p)}
    <div class="actions"><button class="link" id="enlarge">${esc(T('enlarge'))}</button><button class="link" data-go="list/${esc(p.id)}">${esc(T('inList'))}</button><button class="link" data-detail="${esc(p.id)}">${esc(T('detail'))}</button></div>`;
  card.classList.add('on');
  $('#enlarge').onclick = () => enlarge(focused);
  // The pages beside the card, at the right; on a phone, where it lies
  // across the bottom, above it.
  show(around(frame), glide, clearOfCard(card));
}
// An arrow tapped on the map, or its label (a bundle's: each arrow in it):
// what it is, as a sentence, in the card, with the pages at its ends.
let picked = null;
function pick(list, glide) {
  focused = null;
  routed = null;
  picked = list;
  firstStates();
  $('#route').classList.remove('on');
  const ends = new Set(list.flatMap((i) => [edges[i].from, edges[i].to]));
  highlight(ends, (i) => list.includes(i), () => false, null);
  const card = $('#card');
  card.innerHTML = `<h3>${esc(T('legendSheet'))}</h3><ul class="says">${list.map((i) => `<li>${sentence(edges[i], { from: true })}</li>`).join('')}</ul>
    <div class="actions">${[...ends].map((id) => `<button class="link" data-go="map/${esc(id)}">${esc(label(id))}</button>`).join('')}</div>`;
  card.classList.add('on');
  show(around(ends), glide, clearOfCard(card));
}
// A state chosen beside the page: the map shows it, and its address says it.
$('#card').addEventListener('click', (e) => {
  const b = e.target.closest('[data-state]');
  if (!b || !focused) return;
  const p = pageById[focused];
  const i = +b.dataset.state;
  history.replaceState(null, '', `#map/${encodeURIComponent(p.id)}${i ? '/' + encodeURIComponent(p.states[i].name) : ''}`);
  focus(focused, true, { state: p.states[i].name });
});
// The state [id] shows on the map, large.
function enlarge(id) {
  const p = pageById[id];
  const s = p.states[shownState[id] ?? 0];
  const d = drawn(s);
  if (d.image) zoomTo(d.image, [p.label, s.name, variantName()].filter(Boolean).join(' · '));
}

// --- the route between two pages, as the app's navigator goes (its back
// included), from a state and the history the app's start reaches it with:
// lib/src/route.dart, compiled to JavaScript and inlined above as
// contactSheetRouter. Made once, when a route is first asked for ---
let router = null;
// The route: { start: [frame], valuation: { condition: value }, steps:
// [{ edge, from, to, set }] or null }, a frame { page, state }, edge null
// for the back.
const routeOf = (from, state, to, valuation) => {
  router ??= contactSheetRouter(document.getElementById('sheet').textContent);
  return JSON.parse(router(from, state ?? null, to, valuation ? JSON.stringify(valuation) : null));
};
// The address of a route: #route/<from>[/<state>]/<to>, then a
// /<condition>=<value> for each value chosen (an `=` is escaped in names).
function goRoute(from, to, state, valuation) {
  const values = Object.entries(valuation ?? {}).map(([c, v]) => `/${encodeURIComponent(c)}=${encodeURIComponent(v)}`).join('');
  const hash = `#route/${encodeURIComponent(from)}/${state != null ? encodeURIComponent(state) + '/' : ''}${encodeURIComponent(to)}${values}`;
  if (location.hash === hash) route(); else location.hash = hash;
}
function showRoute(from, to, glide, state, valuation) {
  from = pageById[from] ? from : S.pages[0].id;
  to = pageById[to] ? to : (S.pages.find((p) => p.id !== from) ?? S.pages[0]).id;
  focused = null;
  picked = null;
  routed = [from, to, state, valuation];
  $('#card').classList.remove('on');
  const found = routeOf(from, state, to, valuation);
  const stack = found.start;
  const start = stack[stack.length - 1];
  const steps = from === to ? null : found.steps;
  // Each page along it in the state it arrives in.
  firstStates();
  showState(from, stateIndex(from, start.state));
  for (const st of steps ?? []) showState(st.to.page, stateIndex(st.to.page, st.to.state));
  const said = (st) => {
    if (st.edge != null) return sentence(edges[st.edge], { from: true, state: st.from.state, sets: st.set });
    const from = `<b>${esc(label(st.from.page))}</b>: `;
    const t = tabItem[st.tab];
    // A switch arrives where the tab was left; tapping it again, at its first.
    if (st.move === 'switch') {
      return `${from}${esc(tapWords(t))} → <b>${esc(label(st.to.page))}</b>${st.to.page !== st.tab ? esc(T('asLeft')) : ''}`;
    }
    if (st.move === 'retap') {
      return `${from}${esc(T('tapAgain', { text: tabText(t) }))} → <b>${esc(label(st.to.page))}</b>`;
    }
    return `${from}${esc(T('backTo', { page: label(st.to.page) }))}${setting(st.set)}`;
  };
  const options = (sel) => S.pages.map((p) => `<option value="${esc(p.id)}"${p.id === sel ? ' selected' : ''}>${esc(p.label)}</option>`).join('');
  const states = pageById[from].states.length < 2 ? ''
    : `<span>${esc(T('states'))}</span><select id="routeState">${pageById[from].states.map((s) =>
      `<option value="${esc(s.name)}"${s.name === start.state ? ' selected' : ''}>${esc(s.name)}</option>`).join('')}</select>`;
  // The conditions' values it starts under: as the app's start reaches the
  // page, or as chosen; those its state is of, fixed by it.
  const fixed = pageById[from].states.find((s) => s.name === start.state)?.if ?? {};
  const conditions = (S.conditions ?? []).map((c, i) => `<span>${esc(c.name)}</span><select data-condition="${i}"${fixed[c.name] != null ? ' disabled' : ''}>${c.values.map((v) =>
    `<option value="${esc(v)}"${v === found.valuation[c.name] ? ' selected' : ''}>${esc(v)}</option>`).join('')}</select>`).join('');
  // What a back along the route goes to: the pages under the start.
  const under = stack.length > 1
    ? `<p class="meta">${esc(T('routeUnder', { pages: stack.slice(0, -1).map((f) => label(f.page)).join(' › ') }))}</p>` : '';
  // The other tabs' histories, as left; and what was not searched.
  const left = (found.tabs ?? []).length ? `<p class="meta">${esc(T('routeTabs', {
    tabs: found.tabs.map((t) => t.frames.map((f) => label(f.page)).join(' › ')).join(T('arrivingSeparator')) }))}</p>` : '';
  const short = found.searched === false ? `<p class="meta">${esc(T('routeUnsearched'))}</p>`
    : found.bounded ? `<p class="meta">${esc(T('routeBounded'))}</p>` : '';
  const result = from === to ? `<p class="meta">${esc(T('routeSame'))}</p>`
    : !steps ? `<p class="meta">${esc(T('routeNone'))}</p>`
    : `<p class="meta">${esc(T(steps.length === 1 ? 'routeStepsOne' : 'routeSteps', { count: steps.length }))}</p><ol>${steps.map((st) => `<li>${said(st)}</li>`).join('')}</ol>`;
  const box = $('#route');
  box.innerHTML = `<button class="link close" id="routeClose">${esc(T('close'))}</button><h3>${esc(T('route'))}</h3>
    <div class="pick"><span>${esc(T('routeFrom'))}</span><select id="routeFrom">${options(from)}</select>${states}${conditions}
    <span>${esc(T('routeTo'))}</span><select id="routeTo">${options(to)}</select></div>
    <div class="row-actions"><button class="link" id="routeSwap">${esc(T('routeSwap'))}</button></div>${under}${left}${result}${short}`;
  box.classList.add('on');
  $('#routeFrom').onchange = $('#routeTo').onchange = () => goRoute($('#routeFrom').value, $('#routeTo').value);
  if ($('#routeState')) $('#routeState').onchange = () => goRoute(from, to, $('#routeState').value);
  for (const sel of box.querySelectorAll('[data-condition]')) sel.onchange = () => goRoute(from, to, state,
    Object.fromEntries([...box.querySelectorAll('[data-condition]:not([disabled])')].map((s) => [S.conditions[+s.dataset.condition].name, s.value])));
  $('#routeSwap').onclick = () => goRoute(to, from);
  $('#routeClose').onclick = () => go('map');
  const onPath = new Set((steps ?? []).flatMap((st) => st.edge != null ? [st.edge] : []));
  const near = new Set([from, to, ...(steps ?? []).map((st) => st.to.page)]);
  highlight(near, (i) => onPath.has(i), () => false, null);
  // Beside the panel, where the map is wide enough; on a phone, the panel
  // across the top, under it.
  show(around(near), glide, wide() ? { left: box.offsetWidth + 24 } : { top: box.offsetHeight + 24 });
}
$('#routeOpen').onclick = () => {
  const from = focused ?? S.pages[0]?.id;
  if (from) goRoute(from, S.pages.find((p) => p.id !== from)?.id ?? from);
};

// Dragged with one finger (or the mouse); two fingers pinch it larger or
// smaller around where they are.
let drag = null, moved = false, pinch = null;
const touches = new Map();
const panels = '.tools, #card, #route, .bar';
const apart = () => { const [a, b] = [...touches.values()]; return Math.hypot(a.x - b.x, a.y - b.y); };
map.addEventListener('pointerdown', (e) => {
  if (e.target.closest(panels)) return;
  touches.set(e.pointerId, { x: e.clientX, y: e.clientY });
  if (touches.size === 2) { drag = null; moved = true; pinch = { d: apart(), k: view.k }; return; }
  drag = { x: e.clientX, y: e.clientY, vx: view.x, vy: view.y }; moved = false;
});
window.addEventListener('pointermove', (e) => {
  if (touches.has(e.pointerId)) touches.set(e.pointerId, { x: e.clientX, y: e.clientY });
  if (pinch && touches.size === 2) {
    const [a, b] = [...touches.values()];
    const m = map.getBoundingClientRect();
    zoom(pinch.k * apart() / pinch.d / view.k, (a.x + b.x) / 2 - m.left, (a.y + b.y) / 2 - m.top);
    return;
  }
  if (!drag) return;
  const dx = e.clientX - drag.x, dy = e.clientY - drag.y;
  if (Math.abs(dx) + Math.abs(dy) > 3) { moved = true; map.classList.add('drag'); }
  view.x = drag.vx + dx; view.y = drag.vy + dy; apply();
});
const lift = (e) => {
  touches.delete(e.pointerId);
  if (touches.size < 2) pinch = null;
  drag = null; map.classList.remove('drag'); setTimeout(() => moved = false, 0);
};
window.addEventListener('pointerup', lift);
window.addEventListener('pointercancel', lift);
// A click on the map, off the pages, lets the chosen page, or arrow, go.
map.addEventListener('click', (e) => { if (!moved && (focused || picked) && !e.target.closest('.node, ' + panels)) go('map'); });
// An arrow, or its label, tapped: read in the card.
canvas.addEventListener('click', (e) => {
  if (moved) return;
  const t = e.target.closest('#under path.hit, #over g.lbl, #over g.blbl');
  if (!t) return;
  e.stopPropagation();
  const g = t.closest('[data-i]');
  const i = +g.dataset.i;
  pick(g.matches('g.bundle, g.blbl') ? bundles[i].edges : [i], true);
});
// Over a panel, the wheel scrolls it; elsewhere, it moves the map.
map.addEventListener('wheel', (e) => {
  if (e.target.closest(panels)) return;
  e.preventDefault();
  const m = map.getBoundingClientRect();
  if (e.ctrlKey || e.metaKey || Math.abs(e.deltaY) > Math.abs(e.deltaX) * 2 && !e.shiftKey) {
    zoom(Math.exp(-e.deltaY * 0.002), e.clientX - m.left, e.clientY - m.top);
  } else { view.x -= e.deltaX; view.y -= e.deltaY; apply(); }
}, { passive: false });

// --- list: one page under the other, with where it goes and comes from ---
const chip = (id, e) => {
  const img = drawn(pageById[id].states[0]).image;
  const words = edgeWords(e);
  return `<a class="chip" data-go="list/${esc(id)}">${img ? `<img src="${esc(img)}" alt="" loading="lazy">` : ''}<span>${esc(label(id))}</span>${words ? `<small>${words}</small>` : ''}</a>`;
};
// An item from every page is told once, coming from anywhere, and not among
// each page's own.
const out = {}, into = {}, links = {};
for (const e of once) { if (!e.anywhere) (out[e.from] ??= []).push(e); (into[e.to] ??= []).push(e); }
for (const en of entries) (links[en.to] ??= []).push(en);
const none = `<span class="meta">${esc(T('none'))}</span>`;
const sections = {};
for (const p of S.pages) (sections[p.section] ??= []).push(p);
// Drawn again when another variant is shown.
const renderList = () => $('#page-list').innerHTML = Object.entries(sections).map(([name, pages]) =>
  `<div class="group">${name ? `<h2>${esc(name)}</h2>` : ''}${pages.map((p) => {
    const goes = (out[p.id] ?? []).map((e) => chip(e.to, e)).join('');
    const comes = (into[p.id] ?? []).map((e) => e.anywhere ? `<span class="chip entry">${esc(T('fromAnywhere'))}</span>` : chip(e.from, e)).join('') + (links[p.id] ?? []).map((en) => `<span class="chip entry">${esc(en.via)}</span>`).join('');
    return `<article class="row" id="row-${esc(p.id)}" data-find="${esc(findText(p, false))}" data-find-dev="${esc(findText(p, true))}">
      <header><h3>${esc(p.label)}</h3><span class="meta dev">${codeMeta(p)}</span>
        ${p.sheetChanged.length ? `<span class="badge changed dev" title="${esc(p.sheetChanged.join('\n'))}">${esc(T('sheetChanged'))}</span>` : ''}
        <span class="actions"><button class="link" data-go="map/${esc(p.id)}">${esc(T('onMap'))}</button><button class="link" data-detail="${esc(p.id)}">${esc(T('detail'))}</button></span></header>
      ${memoHtml(p)}${linksHtml(p)}
      <div class="states">${p.states.map(stateHtml).join('')}</div>
      <div class="flows">
        <div><h4>${esc(T('goesTo'))}</h4><div class="chips">${goes || none}</div></div>
        <div><h4>${esc(T('comesFrom'))}</h4><div class="chips">${comes || none}</div></div>
      </div></article>`;
  }).join('')}</div>`).join('');
renderList();
// The search narrows the list, and the table, as it is typed.
function filter() {
  const q = $('#search').value.trim().toLowerCase();
  const table = $('#edge-table');
  table.classList.toggle('filtering', !!q);
  for (const r of table.querySelectorAll('tr[data-find]')) r.style.display = !q || findIn(r).includes(q) ? '' : 'none';
  let any = false;
  for (const g of document.querySelectorAll('#page-list .group')) {
    let shown = 0;
    for (const r of g.querySelectorAll('.row')) {
      const on = !q || findIn(r).includes(q);
      r.style.display = on ? '' : 'none';
      if (on) shown++;
    }
    g.style.display = shown ? '' : 'none';
    any ||= shown > 0;
  }
  $('#nomatch').style.display = any ? 'none' : 'block';
}
// Scrolls to the row of [id]: at once when the page is opened at it,
// gliding when moved to from within.
function toRow(id, glide) {
  const row = document.getElementById('row-' + id);
  if (!row) return;
  if (row.style.display === 'none') { $('#search').value = ''; filter(); }
  row.scrollIntoView({ behavior: glide ? 'smooth' : 'auto', block: 'start' });
  for (const r of document.querySelectorAll('.row.hit')) r.classList.remove('hit');
  row.classList.add('hit');
}

// --- table ---
const link = (id) => `<a data-go="list/${esc(id)}">${esc(label(id))}</a>`;
// Rows of [list] in [cols]. With [grouped], the rows of one page (the first
// column) follow each other and name it once (each names it while the
// search narrows them); each row says what the search finds it by.
function edgeRows(list, cols, grouped) {
  if (!list.length) return `<p class="meta">${esc(T('none'))}</p>`;
  let last;
  return `<div class="scroll"><table><thead><tr>${cols.map((c) => `<th class="${c[2] ?? ''}">${c[0]}</th>`).join('')}</tr></thead><tbody>${
    list.map((e) => {
      const first = cols[0][1](e);
      const again = grouped && first === last;
      last = first;
      const find = e.from ? ` data-find="${esc(findEdge(e, false))}" data-find-dev="${esc(findEdge(e, true))}"` : '';
      return `<tr class="${grouped ? (again ? 'again' : 'group') : ''}"${find}>${cols.map((c) => `<td class="${c[2] ?? ''}">${c[1](e)}</td>`).join('')}</tr>`;
    }).join('')}</tbody></table></div>`;
}
// What the user does, in the screen's words (a text, a semantics label, the
// back, anything else said). What only the code names (a key, a widget
// class) is for developers, as is how the sheet writes it.
function action(e) {
  if (!e.trigger) return '—';
  const how = e.trigger.split(':', 1)[0];
  const code = `<span class="dev"> <code>${esc(e.trigger)}</code></span>`;
  if (how === 'key' || how === 'type') return `<span class="plain-only">—</span>${code}`;
  return esc(how === 'back' ? T('back') : e.trigger.slice(how.length + 1)) + code;
}
// A redirect and a back tell anyone something; push, go and replace only
// how the code keeps its pages.
const kindWords = (e) => e.kind === 'redirect' || e.kind === 'pop'
  ? esc(T('kind_' + e.kind)) : `<span class="dev">${esc(T('kind_' + e.kind))}</span>`;
const COLS = {
  from: [esc(T('colFrom')), (e) => e.anywhere ? esc(T('fromAnywhere')) : link(e.from)],
  to: [esc(T('colTo')), (e) => link(e.to) + arriving(e, null)],
  trigger: [esc(T('colTrigger')), action],
  when: [esc(T('colWhen')), (e) => esc(needs(e).length ? needs(e).join(T('conditionAnd')) : T('whenAny'))],
  kind: [esc(T('colKind')), kindWords],
  code: [esc(T('colCode')), (e) => e.source ? `<code>${esc(e.source)}</code>` : '—', 'dev'],
  via: [esc(T('colVia')), (e) => esc(e.via)],
};
// The deep links, apart from the transitions between pages.
const entryRows = (list, cols) => list.length ? `<h2>${esc(T('entries'))}</h2>${edgeRows(list, cols)}` : '';
// Read as "on this page, in this state, doing this, leads there": by page,
// in the sheet's order.
const pageOrder = Object.fromEntries(S.pages.map((p, i) => [p.id, i]));
const rowOrder = (e) => e.anywhere ? -1 : pageOrder[e.from];
$('#edge-table').innerHTML = edgeRows([...once].sort((a, b) => rowOrder(a) - rowOrder(b)),
  [COLS.from, COLS.when, COLS.trigger, COLS.to, COLS.kind, COLS.code], true)
  + entryRows(entries, [COLS.to, COLS.via, COLS.code]);

// --- tree: the pages top to bottom, as a site map draws an app; each under
// the page the fewest steps from the app's start first reach it from ---
const tree = S.tree;
const treeById = Object.fromEntries(tree.pages.map((t) => [t.page, t]));
const treeView = $('#tree-view'), treeCanvas = $('#tree-canvas'), treeSizer = $('#tree-sizer');
// An arrow's words part by part, as the map draws them: what only the code
// names and how it keeps its pages, for developers.
const partsHtml = (e) => [
  e.labelCode ? `<span class="dev">${esc(e.labelCode)}${e.labelParts.length ? ' / ' : ''}</span>` : '',
  e.labelParts.map((p) => `<span class="l-${esc(p.part)}">${esc(p.text)}</span>`).join(' / '),
  e.labelKind ? `<span class="dev">${e.labelCode || e.labelParts.length ? ' / ' : ''}${esc(e.labelKind)}</span>` : '',
].join('');
// Each tree's root, to tell the trees not reached from the app's start.
const rootOf = (t) => { while (t.parent) t = treeById[t.parent]; return t.page; };
let treeNodes = {};
// Drawn again when another variant is shown.
function renderTree() {
  const lines = tree.pages.filter((t) => t.line).map((t) => {
    const pts = [];
    for (let i = 0; i < t.line.length; i += 2) pts.push(t.line[i] + ',' + t.line[i + 1]);
    return `<path d="M${pts.join(' L')}"/>`;
  }).join('');
  const words = tree.pages.filter((t) => t.labelAt).map((t) => {
    const e = t.edge != null ? edges[t.edge] : null;
    const cls = e ? (e.labelParts.length ? '' : ' dev') : ' tab';
    return `<div class="tlabel${cls}" style="left:${t.labelAt[0]}px;top:${t.labelAt[1]}px">${e ? partsHtml(e) : esc(t.label)}</div>`;
  }).join('');
  // Over the trees after the app's: they are not reached from its start.
  const outside = new Set(tree.outside);
  const apart = tree.pages.filter((t) => outside.has(rootOf(t)));
  const heading = apart.length
    ? `<div class="tree-outside" style="left:${Math.min(...apart.map((t) => t.x))}px;top:${tree.pages[0].y - 40}px">${esc(T('treeOutside'))}</div>` : '';
  treeCanvas.style.width = tree.width + 'px';
  treeCanvas.style.height = tree.height + 'px';
  treeCanvas.innerHTML = `<svg width="${tree.width}" height="${tree.height}">${lines}</svg>${heading}${words}`;
  treeNodes = {};
  for (const t of tree.pages) {
    const p = pageById[t.page];
    const s = drawn(p.states[0]);
    const n = document.createElement('div');
    n.className = 'node';
    n.style.left = t.x + 'px'; n.style.top = t.y + 'px'; n.style.width = t.width + 'px';
    n.innerHTML = `<div class="img" style="height:${t.height}px">${s.image ? `<img src="${esc(s.image)}" alt="${esc(p.label)}" loading="lazy">` : ''}</div><div class="label"><span>${esc(p.label)}</span><small></small></div>`;
    n.title = T(p.states.length === 1 ? 'statesOfOne' : 'statesOf', { page: p.label, count: p.states.length });
    // Its details, over the tree.
    n.addEventListener('click', () => go('page', t.page));
    treeCanvas.appendChild(n);
    treeNodes[t.page] = n;
  }
}
renderTree();
// Larger or smaller: the whole width to begin with, not too small to read.
let tk = 1, treeFitted = false;
function zoomTree(k, cx, cy) {
  const r = treeView.getBoundingClientRect();
  cx ??= r.width / 2; cy ??= r.height / 2;
  const at = { x: (treeView.scrollLeft + cx) / tk, y: (treeView.scrollTop + cy) / tk };
  tk = Math.max(0.2, Math.min(2, k));
  treeCanvas.style.transform = `scale(${tk})`;
  treeSizer.style.width = tree.width * tk + 'px';
  treeSizer.style.height = tree.height * tk + 'px';
  treeView.scrollLeft = at.x * tk - cx;
  treeView.scrollTop = at.y * tk - cy;
}
const fitTree = () => zoomTree(Math.max(0.4, Math.min(1, treeView.clientWidth / tree.width)), 0, 0);
$('#tzin').onclick = () => zoomTree(tk * 1.25);
$('#tzout').onclick = () => zoomTree(tk * 0.8);
$('#tfit').onclick = () => { fitTree(); treeView.scrollTo(0, 0); };
// A pinch, or the wheel with Ctrl or Cmd, zooms; the wheel alone scrolls.
treeView.addEventListener('wheel', (e) => {
  if (!e.ctrlKey && !e.metaKey) return;
  e.preventDefault();
  const r = treeView.getBoundingClientRect();
  zoomTree(tk * Math.exp(-e.deltaY * 0.002), e.clientX - r.left, e.clientY - r.top);
}, { passive: false });
// The page [id] chosen in the tree: scrolled to, and marked.
function showTree(id, glide) {
  if (!treeFitted && treeView.clientWidth) { fitTree(); treeFitted = true; }
  for (const n of treeCanvas.querySelectorAll('.node.sel')) n.classList.remove('sel');
  const t = treeById[id];
  if (!t) return;
  treeNodes[id].classList.add('sel');
  treeView.scrollTo({
    left: (t.x + t.width / 2) * tk - treeView.clientWidth / 2,
    top: t.y * tk - 80,
    behavior: glide ? 'smooth' : 'auto',
  });
}

// --- detail ---
function openPanel(html) {
  $('#panel').innerHTML = `<button class="link close" id="close">${esc(T('close'))}</button>${html}`;
  $('#detail').classList.add('on');
  $('#close').onclick = closePage;
}
function openPage(id) {
  const p = pageById[id];
  if (!p) return;
  openPanel(`<h2 style="margin-top:0;color:var(--text)">${esc(p.label)}</h2>
    <p class="meta">${esc(p.section)}</p><p class="meta dev">${codeMeta(p)}</p>
    ${memoHtml(p)}${linksHtml(p)}
    ${p.sheetChanged.length ? `<p class="meta dev"><span class="badge changed">${esc(T('sheetChanged'))}</span> ${p.sheetChanged.map((f) => `<code>${esc(f)}</code>`).join(' ')}</p>` : ''}
    <div class="states">${p.states.map((s) => `<div>${stateHtml(s)}${
      Object.keys(s.uses).length ? `<div class="meta dev">${Object.entries(s.uses).map(([k, v]) => `${esc(k)}: ${esc(v)}`).join(' · ')}</div>` : ''}</div>`).join('')}</div>
    ${p.dependencies.length ? `<div class="dev"><h2>${esc(T('dependencies'))}</h2><table><tbody>${p.dependencies.map((d) => `<tr><td>${esc(d.name)}</td><td>${d.target ? `<code>${esc(d.target)}</code>` : '—'}</td><td>${d.source ? `<code>${esc(d.source)}</code>` : '—'}</td></tr>`).join('')}</tbody></table></div>` : ''}
    <h2>${esc(T('outgoing'))}</h2>${edgeRows(out[id] ?? [], [COLS.when, COLS.trigger, COLS.to, COLS.kind, COLS.code])}
    <h2>${esc(T('incoming'))}</h2>${edgeRows(into[id] ?? [], [COLS.from, COLS.when, COLS.trigger, COLS.kind, COLS.code])}
    ${entryRows(links[id] ?? [], [COLS.via, COLS.code])}`);
}
// Closed, the address is the view's under it again.
function closePage() {
  if (!$('#detail').classList.contains('on')) return;
  $('#detail').classList.remove('on');
  if (location.hash.startsWith('#page/')) {
    const id = decodeURIComponent(location.hash.slice('#page/'.length));
    history.replaceState(null, '', current === 'table' ? '#table' : `#${current}/${encodeURIComponent(id)}`);
  }
}
$('#detail').addEventListener('click', (e) => { if (e.target.id === 'detail') closePage(); });

// --- an image, large ---
function zoomTo(src, caption) {
  const z = $('#zoom');
  z.querySelector('img').src = src;
  z.querySelector('div').textContent = caption;
  z.classList.add('on');
}
const zoomImage = (img) => zoomTo(img.src, img.dataset.zoom);
$('#zoom').onclick = () => $('#zoom').classList.remove('on');

// --- what a click does, wherever it is ---
document.addEventListener('click', (e) => {
  const target = e.target.closest('[data-go], [data-detail], img[data-zoom]');
  if (!target) return;
  // The view, then the page's id, whole: an id may hold a /.
  if (target.dataset.go) {
    const to = target.dataset.go, at = to.indexOf('/');
    closePage();
    if (at < 0) go(to); else go(to.slice(0, at), to.slice(at + 1));
  }
  else if (target.dataset.detail) go('page', target.dataset.detail);
  else zoomImage(target);
});
// Escape closes what is on top: the image, the details, then the card or
// the route on the map.
document.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  if ($('#zoom').classList.contains('on')) $('#zoom').classList.remove('on');
  else if ($('#detail').classList.contains('on')) closePage();
  else if (current === 'map' && (focused || routed || picked)) go('map');
});

// --- views and their addresses: #map, #map/<page>, #map/<page>/<state>,
// #route/<from>/<to>, #route/<from>/<state>/<to>, #list/<page>,
// #page/<page> (its details, over the view), #table ---
const views = ['map', 'tree', 'list', 'table'];
let current = null;
function go(v, id) {
  const hash = '#' + v + (id ? '/' + encodeURIComponent(id) : '');
  if (location.hash === hash) route(); else location.hash = hash;
}
function route() {
  const [v, ...rest] = location.hash.slice(1).split('/');
  const decode = (r) => { try { return decodeURIComponent(r); } catch { return r; } };
  // A route's conditions are the parts with an `=`, which names escape.
  const ids = rest.filter((r) => !r.includes('=')).map(decode);
  const valuation = Object.fromEntries(rest.filter((r) => r.includes('=')).map((r) => r.split('=', 2).map(decode)));
  // The route is drawn on the map; a page's details open over the view
  // shown, or over the list.
  const name = v === 'route' ? 'map' : v === 'page' ? current ?? 'list' : views.includes(v) ? v : 'map';
  const first = current !== name;
  current = name;
  document.body.dataset.view = name;
  for (const b of document.querySelectorAll('nav button')) b.setAttribute('aria-selected', b.dataset.tab === name);
  for (const s of document.querySelectorAll('main > section')) s.classList.toggle('on', s.id === 'sec-' + name);
  if (v === 'page') {
    openPage(ids[0]);
    if (first && name === 'list') requestAnimationFrame(() => toRow(ids[0], false));
    return;
  }
  $('#detail').classList.remove('on');
  if (name === 'map') requestAnimationFrame(() => {
    if (!measured) backgrounds();
    fitBar();
    // A route from a page in a state names three: #route/<from>/<state>/<to>.
    if (v === 'route') {
      const chosen = Object.keys(valuation).length ? valuation : undefined;
      if (ids.length > 2) showRoute(ids[0], ids[2], !first, ids[1], chosen); else showRoute(ids[0], ids[1], !first, undefined, chosen);
    } else focus(ids[0] ?? null, !first, { state: ids[1] });
  });
  if (name === 'tree') requestAnimationFrame(() => {
    if (!treeFitted && treeView.clientWidth) { fitTree(); treeFitted = true; }
    if (ids[0]) showTree(ids[0], !first);
    else for (const n of treeCanvas.querySelectorAll('.node.sel')) n.classList.remove('sel');
  });
  if (name === 'list') { if (ids[0]) requestAnimationFrame(() => toRow(ids[0], !first)); else if (first) window.scrollTo(0, 0); }
}
for (const b of document.querySelectorAll('nav button')) b.onclick = () => go(b.dataset.tab);
window.addEventListener('hashchange', route);
let resizing = false;
window.addEventListener('resize', () => {
  if (resizing) return;
  resizing = true;
  requestAnimationFrame(() => {
    resizing = false;
    fitHeader();
    if (current !== 'map') return;
    fitBar();
    if (routed) showRoute(...routed.slice(0, 2), false, ...routed.slice(2));
    else if (picked) pick(picked, false);
    else focus(focused, false);
  });
});
// On paper, every image, not only those scrolled to.
window.addEventListener('beforeprint', () => { for (const img of document.querySelectorAll('img[loading="lazy"]')) img.loading = 'eager'; });

// The search: as typed, the list narrows; a page chosen goes to it.
$('#search').addEventListener('input', filter);
$('#search').addEventListener('change', () => {
  const q = $('#search').value.trim().toLowerCase();
  if (!q) return;
  // The table stays, narrowed; elsewhere, to the page found.
  if (current === 'table') return;
  const hit = S.pages.find((p) => p.label.toLowerCase() === q) ?? S.pages.find((p) => findText(p, forDev()).includes(q));
  if (hit) go(current, hit.id);
});
// Developers' information, shown or not: only CSS changes, and the labels'
// backgrounds follow their words.
const code = $('#code');
function setCode(on) {
  document.body.classList.toggle('plain', !on);
  save('contact_sheet.code', on);
  // What the search finds follows what is shown.
  filter();
}
// The variant shown: every image follows; the map's boxes stay the first
// variant's. Kept in the address (?variant=) to pass around, and for the
// viewer.
function setVariant(i) {
  variant = i;
  canvas.classList.toggle('contain', i > 0);
  treeCanvas.classList.toggle('contain', i > 0);
  try { localStorage.setItem('contact_sheet.variant', variantName()); } catch {}
  const url = new URL(location.href);
  if (i) url.searchParams.set('variant', variantName()); else url.searchParams.delete('variant');
  history.replaceState(null, '', url);
  for (const p of S.pages) showState(p.id, shownState[p.id] ?? 0);
  renderList();
  renderTree();
  filter();
  if (current === 'map' && focused) focus(focused, false, { state: chosen(focused) ?? undefined });
  if ($('#detail').classList.contains('on') && location.hash.startsWith('#page/')) openPage(decodeURIComponent(location.hash.slice('#page/'.length)));
}
if (variants.length > 1) {
  const pick = $('#variant');
  pick.innerHTML = variants.map((v, i) => `<option value="${i}">${esc(v.name)}</option>`).join('');
  pick.value = String(variant);
  pick.onchange = () => setVariant(+pick.value);
  $('#variant-pick').hidden = false;
  canvas.classList.toggle('contain', variant > 0);
  treeCanvas.classList.toggle('contain', variant > 0);
}
code.checked = load('contact_sheet.code', false);
setCode(code.checked);
code.onchange = () => { setCode(code.checked); requestAnimationFrame(backgrounds); };
route();
</script>
</body>
</html>
''';
