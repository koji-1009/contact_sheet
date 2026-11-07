import 'dart:io';

import 'package:contact_sheet/contact_sheet.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory app;
  setUp(() => app = Directory.systemTemp.createTempSync('repo_'));
  tearDown(() => app.deleteSync(recursive: true));

  test('the app is called by its package name, its version as written; by '
      'its directory where its pubspec cannot be read', () {
    final pubspec = File(p.join(app.path, 'pubspec.yaml'))
      ..writeAsStringSync('name: shop\nversion: 1.2.0+3\n');
    final repo = SheetRepo(app.path);
    expect(repo.displayName, 'shop');
    expect(repo.appVersion, '1.2.0+3');
    // A version YAML reads as a number is still its text.
    pubspec.writeAsStringSync('name: shop\nversion: 2.0\n');
    expect(SheetRepo(app.path).appVersion, '2.0');
    for (final broken in ['name: [shop', '- a list', '']) {
      pubspec.writeAsStringSync(broken);
      final repo = SheetRepo(app.path);
      expect(repo.appName, isNull, reason: broken);
      expect(repo.displayName, p.basename(app.path));
    }
  });
}
