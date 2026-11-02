import 'dart:io';

import 'package:crypto/crypto.dart';

/// The files lib/src/route_js.g.dart is compiled from.
const routeSources = ['lib/src/route.dart', 'tool/route_js.dart'];

/// Their content's hash, as lib/src/route_js.g.dart records it: when it is
/// another, the JavaScript is not theirs, and tool/gen_route_js.dart is to
/// be run again. Run from the repository's root.
String routeSourcesHash() => sha256.convert([
  for (final path in routeSources)
    ...File(path).readAsStringSync().replaceAll('\r\n', '\n').codeUnits,
]).toString();
