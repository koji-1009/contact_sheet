import 'dart:convert';
import 'dart:io';

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

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) => Process.run(
    executable,
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
