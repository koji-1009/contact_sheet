import 'dart:io';

import 'package:contact_sheet/contact_sheet.dart';
import 'package:contact_sheet/src/docs.dart';
import 'package:test/test.dart';

/// What `agent` and `manual` print is what `doc/` holds: the command carries
/// its documents in the binary, where `doc/` is not.
void main() {
  for (final (file, text) in [
    ('doc/agent.md', agentText),
    ('doc/manual.md', manualText),
  ]) {
    test('$file is what the command prints', () {
      expect(text, File(file).readAsStringSync());
    });
  }

  test('the playbook\'s sheet is one the command reads', () {
    final yaml = RegExp(
      r'## Writing the sheet\n\n```yaml\n(.*?)```',
      dotAll: true,
    ).firstMatch(agentText)![1]!;
    final sheet = Sheet.parse(yaml, Messages.of('en'));
    expect(sheet.pages.map((p) => p.id), contains('product_detail'));
  });
}
