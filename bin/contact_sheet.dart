import 'dart:io';

import 'package:contact_sheet/contact_sheet.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(
    args,
    words: Messages.of(Platform.localeName),
    out: stdout.writeln,
    err: stderr.writeln,
  );
}
