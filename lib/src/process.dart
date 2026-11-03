import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Runs commands. Tests give a fake one.
abstract interface class ProcessRunner {
  /// Runs [executable] to its end: its exit code and output.
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  });
}

class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  /// `flutter` as shutter finds it, that the two use one SDK: in
  /// `FLUTTER_ROOT` when it is set, else on the PATH.
  static String _resolve(String executable) {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (executable != 'flutter' || root == null || root.isEmpty) {
      return executable;
    }
    return p.join(root, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) => Process.run(
    _resolve(executable),
    arguments,
    workingDirectory: workingDirectory,
    // A name that is not UTF-8 (Linux allows it) as replacement characters,
    // not an error.
    stdoutEncoding: const Utf8Codec(allowMalformed: true),
    stderrEncoding: const Utf8Codec(allowMalformed: true),
    // On Windows, `flutter` is a script, run through cmd.
    runInShell: Platform.isWindows,
  );
}
