import 'dart:convert';

import 'package:contact_sheet/src/html_js.g.dart';
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
  'noPreview': m.htmlNoPreview,
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
  'notes': m.htmlNotes,
  'noteMemo': m.htmlNoteMemo,
  'noteToggle': m.htmlNoteToggle,
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
  'routeAtLeast': m.htmlRouteAtLeast('{count}'),
  'routeUnsearched': m.htmlRouteUnsearched,
  'setting': m.htmlSetting('{values}'),
  'fromHere': m.htmlFromHere,
  'toHere': m.htmlToHere,
  'enlarge': m.htmlEnlarge,
  'section': m.htmlSection,
  'stateSeparator': m.stateSeparator,
  'variant': m.htmlVariant,
  'notInVariant': m.htmlNotInVariant('{variant}'),
  'held': m.htmlHeld,
  'heldAny': m.htmlHeldAny,
  'heldAbout': m.htmlHeldAbout,
  'heldNone': m.htmlHeldNone,
  'heldBusy': m.htmlHeldBusy,
  'routeBusy': m.htmlRouteBusy,
  'failed': m.htmlFailed('{error}'),
  'levelsAbout': m.htmlLevelsAbout,
  'notesAbout': m.htmlNotesAbout,
  'legendAbout': m.htmlLegendAbout,
};

/// `index.html` of an export: one file that reads [sheet] (`sheet.json`)
/// from a JSON block inside it (so it works opened from disk or served
/// anywhere), with the images next to it in `images/`, and holds the map's
/// drawing, as `map.svg` draws it, from [map]. [strings] are its own words.
/// Its script and style are `lib/src/html/app.js` and `app.css`, inlined
/// ([appJs], [appCss]).
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
  // Each variant's map, laid out at the sizes of its screens: which drawing
  // each variant is, those laid out alike drawn once. The first variant's is
  // the one drawn below and `sheet.json`'s: null here.
  String sizes(SheetMap laid) =>
      [for (final page in laid.sheet.pages) laid.boxOf(page)].join();
  final drawings = <Object?>[null];
  final drawn = {sizes(map): 0};
  final variants = [0];
  for (final variant in map.sheet.variants.skip(1)) {
    final laid = map.laidOutAs(variant);
    final key = sizes(laid);
    if (!drawn.containsKey(key)) {
      drawn[key] = drawings.length;
      drawings.add({
        ...laid.laidOut,
        'under': mapDefs + mapUnder(laid),
        'over': mapOver(laid),
      });
    }
    variants.add(drawn[key]!);
  }
  final filled = {
    'TITLE': const HtmlEscape().convert('${sheet['app']}'),
    'LANG': const HtmlEscape().convert('${sheet['locale']}'),
    'MAP_CSS': mapCss,
    'APP_CSS': appCss,
    'MAP_DEFS': mapDefs,
    'MAP_UNDER': mapUnder(map),
    'MAP_OVER': mapOver(map),
    'SHEET_JSON': block(sheet),
    'MAPS_JSON': block({'variants': variants, 'drawings': drawings}),
    'STRINGS_JSON': block(strings),
    // Compiled from Dart; it holds no `</script` (test/route_test.dart).
    'ROUTE_JS': routeJs,
    // tool/gen_html.dart holds it to no `</script`.
    'APP_JS': appJs,
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
__APP_CSS__</style>
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
    <div class="bar" id="bar"><button id="bar-open" aria-expanded="false" aria-controls="bar"><span data-t="show"></span> ▾</button><div class="levels" id="levels"></div><div class="levels" id="held" hidden></div><div class="levels" id="notes" hidden></div><div class="legend" id="legend"></div></div><div id="card"></div><div id="route"></div></div></section>
  <section id="sec-tree"><div class="tree-wrap"><div class="tools"><button id="tzin" data-title="zoomIn">＋</button><button id="tzout" data-title="zoomOut">－</button><button id="tfit" data-title="fit">⤢</button></div>
    <div id="tree-view"><div id="tree-sizer"><div id="tree-canvas"></div></div></div></div></section>
  <section id="sec-list"><div class="wrap"><p id="nomatch" data-t="noMatch"></p><div id="page-list"></div></div></section>
  <section id="sec-table"><div class="wrap" id="edge-table"></div></section>
</main>
<div id="detail"><div class="panel" id="panel"></div></div>
<div id="zoom"><img alt=""><div></div></div>
<script id="sheet" type="application/json">__SHEET_JSON__</script>
<script id="maps" type="application/json">__MAPS_JSON__</script>
<script id="strings" type="application/json">__STRINGS_JSON__</script>
<script id="route-js">__ROUTE_JS__</script>
<script>
__APP_JS__</script>
</body>
</html>
''';
