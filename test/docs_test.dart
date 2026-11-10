import 'package:contact_sheet/src/docs.dart';
import 'package:contact_sheet/src/lint.dart';
import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/sheet.dart';
import 'package:test/test.dart';

/// The playbook's sheet is the first one an agent copies: one the command
/// reads, and one lint has nothing to say of.
void main() {
  final yaml = RegExp(
    r'## Writing the sheet\n\n```yaml\n(.*?)```',
    dotAll: true,
  ).firstMatch(agentText)![1]!;
  final m = Messages.of('en');

  test('the playbook\'s sheet is one the command reads', () {
    final sheet = Sheet.parse(yaml, m);
    expect(sheet.pages.map((p) => p.id), contains('product_detail'));
  });

  test('lint has nothing to say of the playbook\'s sheet', () {
    expect(lintSheet(Sheet.parse(yaml, m), m), isEmpty);
  });
}
