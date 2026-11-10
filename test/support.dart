import 'dart:io';

import 'package:contact_sheet/src/process.dart';
import 'package:test/test.dart';

/// Real git; anything else answered as done, and kept with the directory
/// it was run in.
class Tools implements ProcessRunner {
  final commands = <List<String>>[];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (executable == 'git') {
      return await Process.run(
        'git',
        arguments,
        workingDirectory: workingDirectory,
      );
    }
    commands.add([executable, ...arguments, '@$workingDirectory']);
    return ProcessResult(0, 0, '', '');
  }
}

/// git with [args] in [dir], as a user whose commits are not signed.
void git(String dir, List<String> args) {
  final result = Process.runSync('git', [
    '-c',
    'user.name=t',
    '-c',
    'user.email=t@example.com',
    '-c',
    'commit.gpgsign=false',
    ...args,
  ], workingDirectory: dir);
  expect(result.exitCode, 0, reason: '${result.stderr}');
}
