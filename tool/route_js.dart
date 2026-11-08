// The route's search (lib/src/route.dart) for index.html: compiled to
// JavaScript by tool/gen_route_js.dart into lib/src/route_js.g.dart, which
// the page inlines. It gives the page two functions:
//
//   contactSheetRouter(sheetJson) -> route(from, state, to, valuation) -> JSON
//   contactSheetShown(sheetJson) -> shown(held) -> JSON
//
// sheetJson is sheet.json's text; state may be null; valuation and held are
// JSON objects of the conditions' values chosen (valuation may be null); the
// JSON is a Route's, and a RouteShown's.
import 'dart:convert';
import 'dart:js_interop';

import 'package:contact_sheet/src/route.dart';

@JS('contactSheetRouter')
external set _router(JSFunction router);

@JS('contactSheetShown')
external set _shown(JSFunction shown);

Map<String, String> _values(String? json) => json == null
    ? const {}
    : (jsonDecode(json) as Map<String, Object?>).cast<String, String>();

void main() {
  _router = (String sheet) {
    final router = Router.fromJson(jsonDecode(sheet) as Map<String, Object?>);
    return (String from, String? state, String to, String? valuation) {
      return jsonEncode(
        router.route(from, state, to, _values(valuation)).toJson(),
      );
    }.toJS;
  }.toJS;
  _shown = (String sheet) {
    final json = jsonDecode(sheet) as Map<String, Object?>;
    final entries = Router.entriesFromJson(json);
    return (String held) {
      final router = Router.fromJson(json, held: _values(held));
      return jsonEncode(router.shown(entries).toJson());
    }.toJS;
  }.toJS;
}
