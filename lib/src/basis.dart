import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/src/process.dart';
import 'package:contact_sheet/src/repo.dart';
import 'package:contact_sheet/src/sheet.dart';

/// What the app was when an AI agent read it to write the sheet: its commit,
/// and the files that differed from it then (changed, or not in git yet),
/// relative to the app, with the git blob hash of their content ('' for a
/// file deleted). Written by `contact_sheet basis` into
/// `contact_sheet/basis.json`, in git with the sheet: whoever exports later
/// sees what changed since.
typedef SheetBasis = ({String commit, Map<String, String> files});

final _commit = RegExp(r'^[0-9a-f]{7,64}$');

/// The basis of [repo]'s sheet, if one was recorded and can be read.
SheetBasis? readBasis(SheetRepo repo) {
  if (!repo.basisFile.existsSync()) return null;
  try {
    final Object? json = jsonDecode(repo.basisFile.readAsStringSync());
    if (json
        case {
          'commit': final String commit,
          'files': final Map<String, Object?> files,
        }
        when _commit.hasMatch(commit)) {
      return (
        commit: commit,
        files: {
          for (final MapEntry(:key, :value) in files.entries)
            if (value is String) key: value,
        },
      );
    }
  } on FormatException {
    // Not ours, or a merge conflict: no basis.
  }
  return null;
}

/// Writes [basis] as what [repo]'s sheet was written against.
void writeBasis(SheetRepo repo, SheetBasis basis) {
  final files = basis.files.keys.toList()..sort();
  repo.basisFile
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
        'commit': basis.commit,
        'files': {for (final f in files) f: basis.files[f]},
      })}\n',
    );
}

/// What [repo]'s app is now, without the sheet package's files; null
/// outside a git repository (or before its first commit).
Future<SheetBasis?> currentBasis(ProcessRunner runner, SheetRepo repo) async {
  final git = _Git(runner, repo);
  try {
    final head = await git(['rev-parse', 'HEAD']);
    final commit = head.stdout.trim();
    if (head.exitCode != 0 || !_commit.hasMatch(commit)) return null;
    final changed = await git.changedFrom(commit);
    if (changed == null) return null;
    return (commit: commit, files: await git.blobHashes(changed));
  } on ProcessException {
    return null;
  }
}

/// The commit [repo]'s app is at and its branch (null when detached), or
/// nulls outside a git repository.
Future<({String? commit, String? branch})> currentCommit(
  ProcessRunner runner,
  SheetRepo repo,
) async {
  final git = _Git(runner, repo);
  try {
    final head = await git(['rev-parse', 'HEAD']);
    final commit = head.stdout.trim();
    if (head.exitCode != 0 || !_commit.hasMatch(commit)) {
      return (commit: null, branch: null);
    }
    final ref = await git(['rev-parse', '--abbrev-ref', 'HEAD']);
    final branch = ref.stdout.trim();
    return (
      commit: commit,
      branch: ref.exitCode == 0 && branch.isNotEmpty && branch != 'HEAD'
          ? branch
          : null,
    );
  } on ProcessException {
    return (commit: null, branch: null);
  }
}

/// The app's files (relative to it, sorted) whose content differs from what
/// [basis] says the agent read: from its commit, committed since or not, or
/// not in git yet; for the files it recorded, from the content recorded.
/// Without the sheet package's. Null when git does not know the commit, or
/// cannot be run.
Future<List<String>?> changedSince(
  ProcessRunner runner,
  SheetRepo repo,
  SheetBasis basis,
) async {
  final git = _Git(runner, repo);
  try {
    final changed = await git.changedFrom(basis.commit);
    if (changed == null) return null;
    final all = {...changed, ...basis.files.keys};
    // Those the agent read with changes of their own: changed only when
    // their content is not what it read.
    final now = await git.blobHashes(basis.files.keys.toList());
    all.removeWhere(
      (path) => basis.files.containsKey(path) && basis.files[path] == now[path],
    );
    return all.toList()..sort();
  } on ProcessException {
    return null;
  }
}

/// git in the app's directory, through a [ProcessRunner].
class _Git {
  _Git(this.runner, this.repo);

  final ProcessRunner runner;
  final SheetRepo repo;

  Future<({int exitCode, String stdout})> call(List<String> args) async {
    final result = await runner.run('git', args, workingDirectory: repo.root);
    return (exitCode: result.exitCode, stdout: '${result.stdout}');
  }

  /// The files that differ from [commit] (committed since or not) or are not
  /// in git, without the sheet package's. `-z`: names as they are.
  /// `--no-renames`: a file renamed is its old name gone and its new name
  /// added, so a sheet naming the old one sees it changed.
  Future<List<String>?> changedFrom(String commit) async {
    final diff = await this([
      'diff',
      '--name-only',
      '--no-renames',
      '--relative',
      '-z',
      commit,
      '--',
    ]);
    if (diff.exitCode != 0) return null;
    final untracked = await this([
      'ls-files',
      '--others',
      '--exclude-standard',
      '-z',
    ]);
    const skip = '${SheetState.sheetPackage}/';
    return {
      for (final out in [
        diff.stdout,
        if (untracked.exitCode == 0) untracked.stdout,
      ])
        for (final path in out.split('\x00'))
          if (path.isNotEmpty && !path.startsWith(skip)) path,
    }.toList();
  }

  /// The git blob hash of each of [paths] ('' for one that does not exist),
  /// as `git hash-object` gives it.
  Future<Map<String, String>> blobHashes(List<String> paths) async {
    final hashes = {for (final path in paths) path: ''};
    final existing = [
      for (final path in paths)
        if (File(pathIn(repo.root, path)).existsSync()) path,
    ];
    if (existing.isEmpty) return hashes;
    final result = await this(['hash-object', '--', ...existing]);
    if (result.exitCode != 0) return hashes;
    final lines = result.stdout.trim().split('\n');
    for (var i = 0; i < existing.length && i < lines.length; i++) {
      hashes[existing[i]] = lines[i].trim();
    }
    return hashes;
  }
}
