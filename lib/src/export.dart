import 'dart:convert';
import 'dart:io';

import 'package:contact_sheet/src/basis.dart';
import 'package:contact_sheet/src/html.dart';
import 'package:contact_sheet/src/lint.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:contact_sheet/src/messages.g.dart';
import 'package:contact_sheet/src/process.dart';
import 'package:contact_sheet/src/repo.dart';
import 'package:contact_sheet/src/runs.dart';
import 'package:contact_sheet/src/sheet.dart';
import 'package:contact_sheet/src/svg.dart';
import 'package:io/io.dart' show ExitCode;
import 'package:path/path.dart' as p;
import 'package:shutter/shutter.dart';

/// shutter's `shot` as the export calls it; a test plays it.
typedef Shoot = Future<ShotRun> Function(
  String projectDir,
  ShotSubject subject, {
  ShotPlatform platform,
  void Function(ShotProgress event)? onProgress,
});

/// The export of an app's map, into `contact_sheet/map/` (with the sheet it
/// is drawn from), or into a folder of its own elsewhere:
///
/// - `index.html`: the map and the list of the pages, the table of the
///   transitions; one file, the images next to it in `images/`;
/// - `map.svg`: the whole map as one picture, images included, its labels
///   what anyone reads; `map-dev.svg`, what developers read too;
/// - `sheet.json`: what `index.html` is drawn from, for other tools and AI
///   agents.
///
/// The images are shutter's shots of the previews the sheet names, drawn as
/// iOS rather than as Android, the platform `flutter test` runs as: the
/// app's own, shot in the app, and the sheet package's, shot there.
class SheetExport {
  SheetExport(
    this.repo, {
    this.runner = const SystemProcessRunner(),
    this.shoot = shot,
    required this.m,
    Messages? words,
    this.log = _silent,
    void Function(String line)? warn,
  }) : words = words ?? m,
       warn = warn ?? log;

  final SheetRepo repo;
  final ProcessRunner runner;
  final Shoot shoot;

  /// What the export tells, in the command's language.
  final Messages m;

  /// The map's words: its labels and `index.html`'s.
  final Messages words;

  /// Gets what is done.
  final void Function(String line) log;

  /// Gets what went wrong: what could not be shot, and why, and what
  /// `flutter pub get` said when it failed (to [log] unless given).
  final void Function(String line) warn;

  static void _silent(String line) {}

  /// The name of the folder an export is written in.
  String get folderName => '${repo.displayName}_contact_sheet';

  /// Where it is written for [folder], a folder chosen for it: in a folder
  /// of its own there ([folderName]), since writing it replaces its
  /// `images/`; or in [folder] itself when that is one written before.
  String dirIn(String folder) {
    final dir = p.normalize(p.absolute(folder));
    return p.basename(dir) == folderName ? dir : p.join(dir, folderName);
  }

  /// The sheet, read from `contact_sheet/sheet.yaml`. Throws an
  /// [ExportException] saying what is wrong with it.
  Sheet readSheet() {
    if (!repo.sheetFile.existsSync()) {
      throw ExportException(m.noSheet, ExitCode.noInput.code);
    }
    try {
      return Sheet.parse(repo.sheetFile.readAsStringSync(), m);
    } on SheetException catch (e) {
      throw ExportException(e.message, ExitCode.data.code);
    }
  }

  /// Writes the export, and returns where (in the sheet package's `map/`,
  /// [SheetRepo.mapDir], or for [folder]: see [dirIn]) and how many states
  /// have no image. The runs of shutter's it makes are deleted once their
  /// images are in the map.
  ///
  /// With [only], the previews of those pages alone are shot; the other
  /// pages keep the images the map there has of them, if it has.
  Future<({String dir, int missing})> run([
    String? folder,
    Set<String> only = const {},
  ]) async {
    final sheet = readSheet();
    for (final id in only) {
      if (!sheet.pages.any((p) => p.id == id)) {
        throw ExportException(m.exportUnknownPage(id), ExitCode.usage.code);
      }
    }
    for (final finding in lintSheet(sheet, m)) {
      log(finding);
    }
    final out = folder == null ? repo.mapDir : dirIn(folder);
    final runs = ExportRuns(repo);
    final kept = Directory.systemTemp.createTempSync('contact_sheet_');
    try {
      // What changed since the basis, and which commit the app is at, read
      // while the previews are shot.
      final drift = _drift();
      final at = currentCommit(runner, repo);
      final (shots, failed) = await _shootAll(sheet, runs, only);
      if (only.isNotEmpty) {
        shots.addAll(_keep(sheet, out, only, kept.path));
      }
      final (:commit, :branch) = await at;
      final map = SheetMap(
        sheet,
        shots: shots,
        failed: failed,
        m: words,
        drift: await drift,
        release: (version: repo.appVersion, commit: commit, branch: branch),
      );
      final missing = _tellMissing(map, only);
      _write(out, map);
      return (dir: out, missing: missing);
    } finally {
      runs.deleteAll();
      kept.deleteSync(recursive: true);
    }
  }

  /// The images the map at [out] has of the pages not [only], in each
  /// variant it drew, as shots (named as they were), copied into [into]
  /// first: the export replaces `images/`; and the errors it has of them,
  /// as shots that failed.
  Map<String, ShotResult> _keep(
    Sheet sheet,
    String out,
    Set<String> only,
    String into,
  ) {
    final before = File(p.join(out, 'sheet.json'));
    if (!before.existsSync()) return const {};
    final Object? json;
    try {
      json = jsonDecode(before.readAsStringSync());
    } on FormatException {
      return const {};
    }
    final kept = <String, ShotResult>{};
    var images = 0;
    // The variants it drew: their platforms, and the Preview they name.
    final variants = <(VariantPlatform, String?)>[
      if (json case {'variants': final List<Object?> vs})
        for (final v in vs)
          if (v case {'platform': final String platform})
            (
              VariantPlatform.values.asNameMap()[platform] ??
                  VariantPlatform.ios,
              v['preview'] as String?,
            ),
    ];
    final ids = {for (final page in sheet.pages) page.id};
    if (json case {'pages': final List<Object?> pages}) {
      for (final page in pages) {
        if (page
            case {'id': final String id, 'states': final List<Object?> states}
            when ids.contains(id) && !only.contains(id)) {
          for (final state in states) {
            if (state case {
              'project': final String project,
              'variants': final List<Object?> drawn,
            }) {
              for (final (i, d) in drawn.indexed) {
                if (i >= variants.length) break;
                if (d is! Map<String, Object?>) continue;
                final shot = d['shot'];
                if (shot is! String) continue;
                final (platform, preview) = variants[i];
                final key = shotKey(
                  inSheetPackage: project == 'sheet',
                  id: shot,
                  platform: platform,
                );
                // A variant's Preview is found by its name: one shot can be
                // two variants', one naming it and one not.
                final name = preview ?? kept[key]?.name ?? shot;
                final size = switch (d) {
                  {'width': final num w, 'height': final num h} => LogicalSize(
                    w.toDouble(),
                    h.toDouble(),
                  ),
                  _ => null,
                };
                if (d['error'] case final String error) {
                  kept[key] = ShotResult(
                    id: shot,
                    status: ShotStatus.error,
                    name: name,
                    size: size,
                    error: error,
                  );
                  continue;
                }
                if (d['image'] case final String image) {
                  final from = File(pathIn(out, image));
                  if (!from.existsSync()) continue;
                  final png = from.copySync(p.join(into, p.basename(image)));
                  if (kept[key]?.png == null) images++;
                  kept[key] = ShotResult(
                    id: shot,
                    status: ShotStatus.ok,
                    name: name,
                    size: size,
                    png: png.path,
                  );
                }
              }
            }
          }
        }
      }
    }
    log(m.exportKept(images));
    return kept;
  }

  /// The previews' shots, by [shotKey]: the app's shot in the app and the
  /// sheet package's in it, at once, as each platform the variants are
  /// drawn as; with [only], those pages' alone. With them, the preview
  /// files shutter could not take (by the sheet's path), and why: the rest
  /// are shot all the same.
  Future<(Map<String, ShotResult>, Map<String, String>)> _shootAll(
    Sheet sheet,
    ExportRuns runs,
    Set<String> only,
  ) async {
    final failed = <String, String>{};
    Future<Iterable<MapEntry<String, ShotResult>>> shootIn(
      bool inSheetPackage,
      VariantPlatform platform,
    ) async {
      String inSheet(String file) =>
          inSheetPackage ? '${SheetState.sheetPackage}/$file' : file;
      final dir = inSheetPackage ? repo.sheetDir : repo.root;
      final files = <String>[];
      for (final file in {
        for (final page in sheet.pages)
          if (only.isEmpty || only.contains(page.id))
            for (final state in page.states)
              if (state.inSheetPackage == inSheetPackage) state.projectFile,
      }.toList()..sort()) {
        // What shutter would stop the whole run for, told of the file.
        if (!file.startsWith('lib/')) {
          failed[inSheet(file)] = m.exportNotInLib(inSheet(file));
        } else if (!File(pathIn(dir, file)).existsSync()) {
          failed[inSheet(file)] = m.exportNoFile(inSheet(file));
        } else {
          files.add(file);
        }
      }
      if (files.isEmpty) return const [];
      await _pubGet(dir, alsoWhen: [if (inSheetPackage) repo.pubspecFile]);
      log(m.exportShooting);
      // A run shutter stops for one file (one with no @Preview): each file
      // on its own, that one told and the others shot.
      Future<List<ShotResult>> shootFiles(List<String> files) async {
        // So that prune finds the run, should the shot be cut short.
        runs.shooting(dir);
        try {
          final run = await shoot(
            dir,
            PreviewFiles(files),
            platform: switch (platform) {
              VariantPlatform.ios => ShotPlatform.ios,
              VariantPlatform.android => ShotPlatform.android,
            },
            onProgress: (event) => log(event.message),
          );
          runs.add(run.dir);
          return run.shots;
        } on ShutterException catch (e) {
          final ofFile =
              e.exitCode == ExitCode.usage.code ||
              e.exitCode == ExitCode.noInput.code;
          if (!ofFile) {
            throw ExportException(m.shutterFailed(e.message), e.exitCode);
          }
          if (files.length == 1) {
            failed[inSheet(files.single)] = e.message;
            return const [];
          }
          return [
            for (final file in files) ...await shootFiles([file]),
          ];
        }
      }

      return [
        for (final result in await shootFiles(files))
          MapEntry(
            shotKey(
              inSheetPackage: inSheetPackage,
              id: result.id,
              platform: platform,
            ),
            result,
          ),
      ];
    }

    // Each platform in turn (a project shot twice at once would share its
    // build); the two projects at once.
    final shots = <String, ShotResult>{};
    for (final platform in {for (final v in sheet.variants) v.platform}) {
      final both = await Future.wait([
        shootIn(false, platform),
        shootIn(true, platform),
      ]);
      shots.addEntries(both.expand((s) => s));
    }
    return (shots, failed);
  }

  /// Tells which states have no image in which variant, and why (a page
  /// not [only] was not shot); returns how many states lack one in some
  /// variant.
  int _tellMissing(SheetMap map, Set<String> only) {
    var missing = 0;
    for (final page in map.sheet.pages) {
      for (final state in page.states) {
        var lacks = false;
        for (final variant in map.sheet.variants) {
          final shot = map.shotOf(state, variant);
          if (map.pngOf(state, variant) == null) lacks = true;
          // The state, and the variant when the sheet names several.
          final name = map.sheet.variants.length == 1
              ? state.name
              : '${state.name} · ${variant.name}';
          if (shot == null && only.isNotEmpty && !only.contains(page.id)) {
            warn(m.exportNotShot(page.label, name));
          } else if (shot == null) {
            final preview = variant.preview;
            warn(
              m.exportNoShot(
                page.label,
                name,
                preview == null ? state.preview : '${state.preview} ($preview)',
              ),
            );
          } else if (shot.status == ShotStatus.error) {
            warn(
              m.exportShotFailed(
                page.label,
                name,
                [?shot.at, ?shot.error].join(': '),
              ),
            );
          }
        }
        if (lacks) missing++;
      }
    }
    return missing;
  }

  void _write(String out, SheetMap map) {
    Directory(out).createSync(recursive: true);
    final images = Directory(p.join(out, 'images'));
    if (images.existsSync()) images.deleteSync(recursive: true);
    images.createSync();
    // Each page's first state in the first variant, for the SVGs, which
    // hold its image.
    final firsts = <SheetState, List<int>>{};
    for (final page in map.sheet.pages) {
      for (final state in page.states) {
        for (final variant in map.sheet.variants) {
          final png = map.pngOf(state, variant);
          final name = map.imageNameOf(state, variant);
          if (png == null || name == null) continue;
          final file = File(p.join(images.path, name));
          // Two states, or two variants, may share an image: written once,
          // and in the SVGs for each page whose first it is.
          final List<int> bytes;
          if (file.existsSync()) {
            bytes = file.readAsBytesSync();
          } else {
            bytes = File(png).readAsBytesSync();
            file.writeAsBytesSync(bytes);
          }
          if (state == page.states.first &&
              variant == map.sheet.variants.first) {
            firsts[state] = bytes;
          }
        }
      }
    }
    final data = map.json(app: repo.displayName);
    File(p.join(out, 'sheet.json')).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
    );
    File(p.join(out, 'index.html'))
        .writeAsStringSync(exportHtml(data, htmlStrings(words), map));
    for (final (name, plain) in [('map.svg', true), ('map-dev.svg', false)]) {
      File(p.join(out, name)).writeAsStringSync(
        exportSvg(map, (state) => firsts[state], plain: plain),
      );
    }
  }

  /// What the app changed since the sheet's basis, if it has one.
  Future<SheetDrift?> _drift() async {
    final basis = readBasis(repo);
    if (basis == null) return null;
    return (
      commit: basis.commit,
      changed: await changedSince(runner, repo, basis),
    );
  }

  /// `flutter pub get` in [dir], unless its packages were got after its
  /// pubspec (and its lock file, and [alsoWhen]) last changed, or it was run
  /// since they did: pub leaves its package config as it was when nothing
  /// changes, so a pubspec touched (by a checkout) stays newer than it.
  Future<void> _pubGet(String dir, {List<File> alsoWhen = const []}) async {
    final config = File(p.join(dir, '.dart_tool', 'package_config.json'));
    final sources = [
      File(p.join(dir, 'pubspec.yaml')),
      File(p.join(dir, 'pubspec.lock')),
      ...alsoWhen,
    ];
    String stampOf() => [
      for (final s in sources)
        s.existsSync() ? s.lastModifiedSync().microsecondsSinceEpoch : 0,
    ].join(' ');
    final stamps = _PubGetStamps(repo);
    if (config.existsSync()) {
      final got = config.lastModifiedSync();
      if (!sources.any(
            (s) => s.existsSync() && s.lastModifiedSync().isAfter(got),
          ) ||
          stamps[dir] == stampOf()) {
        return;
      }
    }
    const args = ['pub', 'get'];
    log('\$ flutter ${args.join(' ')}');
    final ProcessResult result;
    try {
      result = await runner.run('flutter', args, workingDirectory: dir);
    } on ProcessException catch (e) {
      // No flutter to run: as shutter tells it, unavailable.
      throw ExportException(m.noFlutter(e.message), ExitCode.unavailable.code);
    }
    if (result.exitCode != 0) {
      for (final line in '${result.stdout}${result.stderr}'.split('\n')) {
        if (line.trim().isNotEmpty) warn(line);
      }
      throw ExportException(
        m.commandFailed('flutter ${args.join(' ')}', result.exitCode),
        ExitCode.unavailable.code,
      );
    }
    stamps[dir] = stampOf();
  }
}

/// When `flutter pub get` last ran in each project, as the times of the
/// files it reads then: in `contact_sheet/.dart_tool/contact_sheet/`, with
/// the export's other records.
class _PubGetStamps {
  _PubGetStamps(this.repo);

  final SheetRepo repo;

  File get _file =>
      File(p.join(repo.sheetDir, '.dart_tool', 'contact_sheet', 'pub_get'));

  Map<String, Object?> _read() {
    try {
      final Object? json = jsonDecode(_file.readAsStringSync());
      return json is Map<String, Object?> ? json : {};
    } on FileSystemException {
      return {};
    } on FormatException {
      return {};
    }
  }

  String? operator [](String dir) => switch (_read()[dir]) {
    final String stamp => stamp,
    _ => null,
  };

  void operator []=(String dir, String stamp) {
    final all = _read()..[dir] = stamp;
    _file
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(all));
  }
}

/// An export that failed, with what to tell and the exit code to end with
/// (sysexits).
class ExportException implements Exception {
  ExportException(this.message, this.exitCode);
  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
