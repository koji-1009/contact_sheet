# AGENTS.md

For AI coding agents (Claude Code, Codex, ...) working on this repository.
Read [README.md](README.md) and [doc/development.md](doc/development.md) first.
[doc/agent.md](doc/agent.md) and [doc/manual.md](doc/manual.md) are a different thing: the playbook and the reference for the agent that writes a target app's sheet, which `sheet agent` and `sheet manual` print (the usage's footer points an agent to them).

## What matters

The core value is the map of every page: the sheet drawn with each state's image, shot from the app's `@Preview`s by shutter, and exported as HTML and JSON (and SVG with `export --svg`) to be opened without any tool.
It is for the people outside the code as much as for developers: product managers, designers, marketing, support.

Decisions already made; do not reintroduce what they removed:

- One package, `contact_sheet`, pure Dart, at the repository's root: the command, `sheet` (`bin/contact_sheet.dart`, so `dart run contact_sheet` runs it). No Flutter package of Contact Sheet's, no live app, no host, no launcher. Flutter draws only the app's previews, through shutter.
- shutter is a library dependency (`package:shutter/shutter.dart`): `sheet export` calls its `shot` for the previews the sheet names, drawn as iOS. Nothing else to install.
- The sheet is data: `contact_sheet/sheet.yaml` in the target app, read by the command (`lib/src/sheet.dart`, which says where a mistake is), written by an AI agent reading the app's code, following the playbook, and drawn as it is. There is no machine verification of the sheet against the app and no deterministic extraction; nothing is added to the target app.
- The previews are the app's own first (a team on shutter has one per page), shot in the app. Only what the app has no preview of is written in the sheet package (`contact_sheet/`, made by `init --package`), a plain Flutter package that imports the app and does not depend on Contact Sheet, shot there. A state's `preview` is relative to the app; `contact_sheet/...` is the sheet package's.
- What only developers read stays apart from what anyone reads: the code's names (`key:`, `type:` triggers), files, fakes, and `go` and `replace` are behind "For developers" in the HTML (`.dev`, hidden by CSS) and only in `map-dev.svg`, not in `map.svg`. The playbook has triggers written in the screen's words (`text:`, `label:`).
- The map's layout (`lib/src/layout.dart`) and its drawing (`mapUnder` and `mapOver` in `lib/src/svg.dart`) are shared by the HTML and the SVGs. Label sizes are estimated (`labelSize` in `lib/src/map.dart`): the text is drawn by whatever opens the map, and the HTML measures it again. The tree (`lib/src/tree.dart`) is laid out in Dart too, its pages the map's sizes, and drawn only in the HTML.
- The layout is for large apps (100+ pages): each section an island of its own, laid in rows; the arrows from other sections into one page that say the same are bundled, and one that would run through where another island's pages are is a jump (`MapLayout.jumps`: a short arrow out saying where it goes, and a bundle in). The map's labels stay short; a page tapped reads its transitions as sentences (`sentence` in `lib/src/html.dart`, its words in the ARB files).
- Variants (a platform, or the `Preview` of a name a `MultiPreview` gives) are switched in the HTML, which lays the map and the tree out again in the variant shown, each page's box its screen at the scale the first variant's is drawn at; `map.svg`, `map-dev.svg` and `sheet.json`'s boxes are the first variant's. A state names a `MultiPreview`'s nth `Preview` as shutter ids it (`@<n>.<k>`).
- A state is one `@Preview`, named by its page: how the page looks. What the app keeps across its pages, shown on them or not (signed in, the cart), is a condition (`conditions`), one valuation for the whole app: a state may be of values of them (`if`), a transition happens while some (`if`) and gives some (`set`, or its `then` state's). Where a transition arrives is its `then` (one state, or one by the state it leaves), else the state of `to` of the name it leaves if the conditions after it allow it, else `to`'s first, `data` and conditions' states those allow (`Router._arrive`; `arrive` in `sheet.json`, the union over the values, which the HTML follows). Never states duplicated to carry a condition. `from` may list pages: one edge from each, at the item's place (`SheetEdge.item`, what lint names); `'*'` is every page but `to` (`anywhere`, drawn once from outside). A pop without `to` goes back to the page under it: one edge to each page it can be put over (`under`), the route taking only the one under it. Anything written with `trigger: back` takes the place of the page's back. A dialog is a page, a state of the page under it, or nothing, as the agent judges it: not because Flutter puts it on the `Navigator`. Screens outside the app, the pages a deep link builds under its page and `popUntil` to a page in between are not supported. An edge's `key` is derived, never written.
- The route is the exact shortest path of the pushdown system `kind` makes (push and redirect push, replace replaces the top, go resets, pop and the unwritten back of every push pop; a written back pop overrides that back), its stack frames (page, state), its control the conditions' values (a pop keeps them; the page under lands as they allow): each frame entered under each valuation summarised once, then searched from the stack the fewest steps from the app's launch reach the first page with, under the values chosen. No bounded stack: a shortest route can need a page twice on it. Tabs that keep their own histories (`tabs`) are a shell at the bottom of the stack, never pushed, the tabs' histories in the finite control up to `Router.tabDepth` pages (with two histories and the conditions shared, reachability would not be decidable): a route found is searched again past the bound and is the fewest of all; the search is A* over a bound from the moves with the other tabs' histories left out (`_boundOf`: the tab shown's history exact, each other tab's one it can have been left with, a pop landing only on pages already shown: the tabs' states added up, not multiplied), and stops at `searchLimit` nodes, the route saying so (`searched`), as telling a page cannot be reached can take every history, as many as the tabs' multiplied together (PSPACE-hard). It is Dart (`lib/src/route.dart`), tested against a search over every stack (`test/route_test.dart`), and the HTML runs it compiled to JavaScript (`lib/src/route_js.g.dart`, inlined): no route logic is written in the page's JavaScript.
- `sheet.json`'s `schemaVersion` stays 1 until the first release; after it, it changes when what is there does.

## Layout

| Path | What |
| --- | --- |
| `bin/contact_sheet.dart` | The entry point: nothing but `runCli` |
| `lib/contact_sheet.dart` | What the package exports |
| `lib/src/commands.dart` | The commands (`package:args`' `CommandRunner<int>`), exit codes from `package:io`'s `ExitCode` |
| `lib/src/version.dart` | Generated from the pubspec's `version` by `dart run build_runner build`: `--version` |
| `lib/src/sheet.dart` | `sheet.yaml`, read |
| `lib/src/repo.dart` | Where things are in the target app |
| `lib/src/export.dart` | The export: the shots (the app's and the sheet package's, at once), made WebP, then `sheet.json`, `index.html`, `images/`, and with `--svg` `map.svg` and `map-dev.svg` |
| `lib/src/map.dart` | The sheet with its shots: the arrows' labels, `sheet.json` |
| `lib/src/layout.dart` | Where pages, arrows, bundles and labels go |
| `lib/src/tree.dart` | The tree: the pages top to bottom, each under the page the app's start first reaches it from; `tree` in `sheet.json`, drawn by the HTML |
| `lib/src/route.dart` | The route between two pages, as the navigator goes: what the HTML's route runs |
| `tool/route_js.dart`, `lib/src/route_js.g.dart` | It for the HTML: compiled to JavaScript by `dart run tool/gen_route_js.dart`, with the hash of what it was compiled from (`tool/route_sources.dart`: which files, and their hash) |
| `lib/src/svg.dart`, `lib/src/html.dart` | The drawing and its palette (light and dark); `index.html`, its words from the ARB files |
| `lib/src/runs.dart` | The runs of shutter's an export made in the app, deleted after it or by `prune` |
| `lib/src/basis.dart`, `lib/src/process.dart` | The basis and what changed since, from git; running flutter and git |
| `lib/src/scaffold.dart` | `sheet init` |
| `lib/src/lint.dart` | `sheet lint`, and the hints `export` tells: what the sheet itself shows may be missing or written twice |
| `lib/src/l10n/*.arb`, `lib/src/messages.g.dart` | The command's words; generated from them by `dart run tool/gen_messages.dart` |
| `doc/agent.md`, `doc/manual.md` | For the AI agent writing a sheet: the playbook and the reference |
| `doc/development.md` | For people working on this repository: running it from a clone, the checks, the examples |
| `lib/src/docs.dart` | `doc/agent.md` and `doc/manual.md`, as the command prints them: kept the same by `test/docs_test.dart`, so edit both |
| `test/` | `support.dart`: flutter answered as done, git run for real; `export_test.dart` fakes shutter's `shot`; `bin_test.dart` runs the command itself |
| `example/*_app/` | The example apps; `contact_sheet/` in each holds its sheet (and, for shop_app, tabs_app and trips_app, its sheet package) |
| `CHANGELOG.md` | What each version changed, for its users |
| `.github/` | CI: the checks below (`analyze.yml`), the examples' maps exported and on GitHub Pages (`deploy.yml`, `pages/index.html` their top page), Dependabot for the actions |

## Rules

- Answer the owner in Japanese. README, AGENTS.md and `doc/` are in English.
- Read the actual code (dependencies too) before claiming anything. Mark what you could not verify.
- Do what was asked; report what you find beyond it instead of changing it.
- No words in code: the command's and the HTML's are in `lib/src/l10n/*.arb` (then `dart run tool/gen_messages.dart`). The playbook and the reference stay in English.
- Paths: `package:path` in the command; `/` in anything shared through git.
- A command line as `dart-lang/skills`' `dart-build-cli-app` has it: `bin/` thin, the logic in `lib/src/`; what it gives on stdout, what went wrong (and the usage, after a wrong use) on stderr; an exit code returned, never `exit()`.
- A change its users see goes in `CHANGELOG.md`, under the version it comes with.
- After changing the pubspec's `version`, run `dart run build_runner build`.
- After changing `lib/src/route.dart` or `tool/route_js.dart`, run `dart run tool/gen_route_js.dart`: `test/route_test.dart` fails while the JavaScript is not theirs.
- Dart 3.13 or later.

## Check your work

Each on its own:

```sh
dart format lib bin tool test example
dart analyze
dart test
```

And `flutter analyze` in each `example/<app>/`, and in its `contact_sheet/` where it is a package.

The export, end to end, with shutter; look at `index.html` (light and dark, and at a phone's width), `map.svg` and `map-dev.svg` when you change what is drawn:

```sh
dart run contact_sheet export example/shop_app --out <folder> --svg
```
