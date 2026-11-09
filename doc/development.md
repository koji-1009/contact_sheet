# Working on Contact Sheet

## From a clone

`dart run contact_sheet <command>` in the clone runs the command without installing it.
`dart install 'contact_sheet@{path: <the clone>}'` installs it as it is.

## This repository

| Path | What |
| --- | --- |
| `bin/`, `lib/` | Package `contact_sheet`, pure Dart: the command, the sheet's reading, the map's layout, HTML, SVG and JSON, shutter's shots, the basis from git |
| `lib/src/l10n/` | The words (ARB): the command speaks English; the map, English or Japanese |
| `doc/` | The playbook and the reference for AI agents, as `agent` and `manual` print them; this page; `images/`, the README's and pub.dev's pictures (`flow.png` drawn from `flow.svg`) |
| `example/` | The example apps and their sheet packages |
| `test/`, `tool/` | The tests; the generators of the command's words from the ARB files, of the documents it prints from `doc/`, and of the HTML's route from `lib/src/route.dart`, compiled to JavaScript |
| `AGENTS.md` | For AI agents working on this repository |
| `CHANGELOG.md` | What each version changed |

## Checks

```sh
dart format lib bin tool test example
dart analyze
dart test
```

And `flutter analyze` in each example app, and in its `contact_sheet/` where it is a package (shop_app, tabs_app, trips_app).

## Generated files

Run the generator after changing what it is made from; CI fails while a generated file is not theirs:

| After changing | Run |
| --- | --- |
| `lib/src/l10n/*.arb` | `dart run tool/gen_messages.dart` |
| `doc/agent.md` or `doc/manual.md` | `dart run tool/gen_docs.dart` |
| `lib/src/html/app.js` or `lib/src/html/app.css` | `dart run tool/gen_html.dart` |
| The pubspec's `version` | `dart run build_runner build` |
| `lib/src/route.dart` or `tool/route_js.dart` | `dart run tool/gen_route_js.dart` |

## The examples

[example/README.md](../example/README.md) tells what each app and its sheet show.
To draw them:

```sh
dart run contact_sheet export example/shop_app
dart run contact_sheet export example/notes_app
dart run contact_sheet export example/tabs_app
dart run contact_sheet export example/trips_app
```

Each map is then in `example/<app>/contact_sheet/map/`.
