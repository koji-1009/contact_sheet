import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

/// The command as it is run, end to end: its streams and exit codes.
void main() {
  // What it tells is in English, whatever the machine's language.
  Future<TestProcess> contactSheet(List<String> args) =>
      TestProcess.start('dart', ['run', 'bin/contact_sheet.dart', ...args]);

  test('--version prints the version and exits 0', () async {
    final process = await contactSheet(['--version']);
    await expectLater(process.stdout, emits(startsWith('contact_sheet ')));
    await process.shouldExit(0);
  });

  test('a wrong use goes to stderr, with the usage, and exits 64', () async {
    final process = await contactSheet(['draw']);
    await expectLater(
      process.stderr,
      emitsThrough(contains('Could not find a command named "draw"')),
    );
    await process.shouldExit(64);
  });

  test('init on a directory with no app says so and exits 66', () async {
    await d.dir('empty').create();
    final process = await contactSheet(['init', d.path('empty')]);
    await expectLater(
      process.stderr,
      emits('There is no pubspec.yaml in ${d.path('empty')}'),
    );
    await process.shouldExit(66);
  });
}
