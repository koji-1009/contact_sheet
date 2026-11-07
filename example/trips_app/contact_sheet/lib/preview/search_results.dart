import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';

/// The results of a search, over the search page.
const results = '/explore/search/results?q=Kyoto';

@Preview(name: 'Found', size: phone, wrapper: guest)
Widget searchResults() => startAt(results);

@Preview(name: 'No match', size: phone, wrapper: guest)
Widget searchResultsNone() =>
    startAt('/explore/search/results?q=Hot%20springs');
