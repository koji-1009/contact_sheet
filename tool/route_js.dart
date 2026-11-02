// The route's search (lib/src/route.dart) for index.html: compiled to
// JavaScript by tool/gen_route_js.dart into lib/src/route_js.g.dart, which
// the page inlines. It gives the page one function:
//
//   contactSheetRouter(sheetJson) -> route(from, state, to, valuation) -> JSON
//
// sheetJson is sheet.json's text; state may be null; valuation is a JSON
// object of the conditions' values chosen, or null; the JSON is a Route's.
import 'dart:convert';
import 'dart:js_interop';

import 'package:contact_sheet/src/route.dart';

@JS('contactSheetRouter')
external set _router(JSFunction router);

void main() {
  _router = (String sheet) {
    final router = Router.fromJson(jsonDecode(sheet) as Map<String, Object?>);
    return (String from, String? state, String to, String? valuation) {
      final chosen = valuation == null
          ? const <String, String>{}
          : (jsonDecode(valuation) as Map<String, Object?>)
                .cast<String, String>();
      return jsonEncode(router.route(from, state, to, chosen).toJson());
    }.toJS;
  }.toJS;
}
