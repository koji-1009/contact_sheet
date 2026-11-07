import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/search_results.dart';
import 'package:trips_app_sheet/preview/start.dart';

@Preview(name: 'Filters', size: phone, wrapper: guest)
Widget filters() =>
    startAt('/explore/search/results/filters?q=Kyoto', from: results);
