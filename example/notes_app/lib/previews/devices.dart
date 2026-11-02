import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// A page as a phone and as a tablet shows it: one preview each, named
/// `Phone` and `Tablet` in every group, so a page's tablet preview is found
/// by its name.
final class Devices extends MultiPreview {
  const Devices({required this.group, required this.wrapper});

  /// The page's group in the previewer.
  final String group;

  /// The state the page is in.
  final WidgetWrapper wrapper;

  @override
  List<Preview> get previews => [
    Preview(group: group, name: 'Phone', size: const Size(390, 844), wrapper: wrapper),
    Preview(group: group, name: 'Tablet', size: const Size(1180, 820), wrapper: wrapper),
  ];
}
