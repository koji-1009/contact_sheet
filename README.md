# Contact Sheet

Every page of a Flutter app as one map: each state of each page as an image, each transition as an arrow.
The images are the app's own `@Preview`s, shot with [shutter](https://pub.dev/packages/shutter) (as a library, drawn as iOS).
The map is written as HTML, SVG and JSON, to be opened without any tool and shared with the people outside the code: product managers, designers, marketing, support.
The app's code is never changed.

An AI agent does the writing.
It reads the app's code and writes the app's **sheet** (`contact_sheet/sheet.yaml`), naming a `@Preview` for each state of each page, then turns it into the map with the `contact_sheet` command.
The previews are the app's own where it has them (a team on shutter or the Widget Previewer has one per page); for the pages and states it has none of, the agent writes them in the **sheet package**, a small Flutter package in `contact_sheet/` that imports the app.

The sheet is the app's transition structure as data, read from its code and kept in git with the app:

- pages: their widget and file, route path, and the states each one starts in (a `@Preview` each; those what it loads decides, such as empty or loading, marked);
- what the app keeps across its pages, shown on them or not (signed in, what is in the cart): its values, the states of a page each is the look of, the transitions that happen only for some (a redirect for a guest) and those that change it (logging in);
- transitions: from which pages (one, several: the bottom tabs, or every page: a session that expires), to which (or, saving a form, back to whichever page opened it), what the user does, in the screen's words (a button's text, a tooltip, back, "tap a product"), in which states, the state it arrives in (by the state it leaves, or, unsaid, the one of the same name, or the one of what the app keeps: signed in stays signed in), how the code moves (push, go, replace, pop, redirect) and where in the code;
- tab bars whose tabs each keep their own history (go_router's `StatefulShellRoute`, iOS's tab bar): the pages each tab shows, switched between as the bar does, each tab found as it was left;
- deep links, apart from the transitions: they come from no page, and may say the state they open in;
- for reference: what each page depends on that its previews replace, and which fake each state uses;
- for the people reading the map, optional: a memo on each page and links to more about it, written by the AI or by hand;
- optional, the variants every state is shot in, to switch between in the HTML: as iOS or Android, and as the other sizes a `MultiPreview` of devices gives (phone, tablet, desktop).

Contact Sheet draws the sheet as it is: it does not check it against the app.

## Requirements

- Flutter 3.47 or later (Dart 3.13 or later).
- An AI agent to write the sheet: any that runs commands, such as [Claude Code](https://claude.com/claude-code) or [Codex](https://github.com/openai/codex).

shutter comes with the command: nothing else to install.

## Getting started

1. Install the command (`dart install` compiles it to a native binary on the PATH):

   ```sh
   dart install contact_sheet
   ```

2. In the app's directory, ask the AI agent to run `contact_sheet agent` and follow it. `contact_sheet -h` points an agent there too.
3. Open `contact_sheet/map/index.html`.

From a clone of this repository, `dart install 'contact_sheet@{path: <the clone>}'` installs it as it is, and `dart run contact_sheet <command>` in the clone runs it without installing.

## Commands

| Command | What |
| --- | --- |
| `contact_sheet agent` | Prints the playbook for the AI agent: turn the app's previews into the map ([doc/agent.md](doc/agent.md)) |
| `contact_sheet manual` | Prints the reference: the sheet's fields, the map, the runs, the exit codes ([doc/manual.md](doc/manual.md)) |
| `contact_sheet init` | Writes an empty sheet (`contact_sheet/sheet.yaml`); with `--package`, the sheet package's skeleton too |
| `contact_sheet export` | Shoots the previews the sheet names with shutter and writes the map into `contact_sheet/map/`. `--out <folder>`: into `<app>_contact_sheet/` there. `--only <page id>`: those pages' previews alone, the others keeping their images. `--locale <en\|ja>`: the map in that language, not the machine's. `--strict`: fails while a state has no image (for CI) |
| `contact_sheet lint` | Tells what the sheet itself shows may be missing (a page no arrow leads to, a state nothing leaves from or arrives in) or written twice |
| `contact_sheet basis` | Records the app as it is now as what the sheet was written against (`contact_sheet/basis.json`) |
| `contact_sheet changed` | Lists the app's files changed since then: the sheet may need bringing up to date for them. `--by-page`: by the pages the sheet names them for, then those on no page |
| `contact_sheet prune` | Deletes the runs of shutter's that Contact Sheet left: the sheet package's, and those an interrupted export left in the app |

Each but `agent` and `manual` runs on the app directory given last, the current one by default.
`contact_sheet help <command>` (or `<command> --help`) tells a command's options; `contact_sheet --version`, the version; `--verbose`, where an unexpected error came from.

The exit codes are sysexits':

| Code | When |
| --- | --- |
| 0 | Done |
| 64 | A wrong use: the message and the usage on stderr; `export --only`: no such page |
| 65 | The sheet cannot be read (said with where); `changed`: git does not have the basis's commit; `export --strict`: a state has no image |
| 66 | No app (`pubspec.yaml`) or no sheet; `changed`: no basis yet |
| 69 | `flutter pub get` failed |
| 70 | An unexpected error |
| 78 | `basis`: not a git repository |
| shutter's | shutter could not shoot |

## The map

`contact_sheet/map/` holds:

- `index.html`: one file, the images in `images/` next to it, to be opened from disk or served anywhere (a static host, CI's artifacts).
- `map.svg`: the whole map as one picture, the images in it, its labels what anyone reads, each page a link to it in `index.html`; `map-dev.svg`, with what developers read too.
- `sheet.json`: what they are drawn from (with `schemaVersion`), for other tools and AI agents.

`index.html` has two views of the same pages, and more:

- **The map**: each section an island, the flow left to right in it; a large app's islands in rows, their names to go into from far out. A page chosen (on the map, or by searching) brings the map to it and the pages next to it, the rest faint, with its memo, links and states beside it, and its transitions as sentences ("When Guest, tap “Log in” → Log in (From home)"). A state chosen there is shown on the map with only the arrows that can happen in it, and the pages they arrive at in the state they arrive in. Twice on a page, its image large.
- **The list**: one page under the other, by section, each with all its states and the pages it goes to and comes from, which lead to theirs.
- **The transitions**: a table by page: in which state, doing what, it leads where.
- **The route** between two pages: the fewest steps from one to the other as the app's navigator goes (the back of every page put over another included), following the states and what the app keeps across its pages (a guest is sent to log in, even from a page that does not show it), and the tabs' own histories (a tab switched back to as it was left), each as a sentence; it starts as the app's start reaches the first page, in the state and with what the app keeps chosen, and names the pages under it.
- **Search**: pages by their names, memo, states, links and what is done on them (a button's words find the page it is on); the table narrows as it is typed.
- **Addresses** to pass around, for each view, page, state, route and page's details: `index.html#map/checkout`, `#map/home/Member`, `#route/home/checkout`, `#route/home/Member/checkout`, `#route/cart/checkout/Login=Member`, `#list/checkout`, `#page/checkout`, `#table`.
- **Which app and how current**: the app's version and branch, when the map was exported, and, with a basis, how many of its code changes the sheet names for no page (a page the map does not have yet may be among them).
- **How much the map shows**: the pages alone (to look at the screens), with the arrows (to see how they lead to each other), or with what each arrow says (the default), chosen under the map (`?show=pages` or `?show=flow` in the address); a page chosen, or a route, shows its own arrows whatever.
- **Variants**, where the sheet names them: iOS or Android, phone or tablet, chosen in the header (`?variant=Android` in the address); every image follows.
- **For developers**, when ticked: the code's names, files, fakes and commit, how the code keeps its pages (go, replace). Without it, the map reads in the screen's words.
- Light or dark as the browser is set, one column on a phone (pinch to zoom the map), and the list or the table on paper.

A state shutter could not draw has no image: its error is told by the command and shown in the HTML.
The pages whose files changed since the sheet's basis are marked for developers: a hint, as a change does not make the sheet wrong.

## What goes into the app's git

| Path | What | In git |
| --- | --- | --- |
| `contact_sheet/sheet.yaml` | The sheet | yes |
| `contact_sheet/basis.json` | What the sheet was written against | yes |
| `contact_sheet/pubspec.yaml`, `analysis_options.yaml`, `lib/` | The sheet package, when the app lacks previews: how those pages start in each state | yes |
| `contact_sheet/map/` | The map | as you choose |
| `contact_sheet/.dart_tool/` | Generated, with the sheet package's shots | no |

`contact_sheet init --package` adds `contact_sheet/.dart_tool/` to the app's `.gitignore` unless it ignores `.dart_tool/` already.
The app's own previews are shot in the app, the sheet package's in it; once their images are copied into `map/`, the export deletes the runs of shutter's it made, so the team's own runs in the app stay as they were.
`contact_sheet prune` deletes any an interrupted export left.

The map is mostly images: in the shop example (12 states) it is 1.1 MB, of which `images/` is 408 KB and `map.svg` and `map-dev.svg` 324 KB each, as they hold the images too.
If that is too much for the app's git, add `contact_sheet/map/` to its `.gitignore`, and export where the map is to be shared (`--out <folder>`), or have CI export it.

## Examples

Three apps, each with its sheet written as the playbook says, one for each place the previews can come from:

| App | Navigation | State | Previews |
| --- | --- | --- | --- |
| `example/shop_app` | go_router: a redirect for guests, a deep link, pages pushed over others | riverpod | none in the app: all in the sheet package, started through the app's router |
| `example/notes_app` | Navigator 1.0: named routes with arguments, a new note as a full-screen dialog | an `InheritedNotifier` | all the app's own, one file per page (`lib/pages/*_preview.dart`), each a `MultiPreview` of a phone and a tablet: no sheet package. Shot in three variants: iPhone, Android, tablet |
| `example/tabs_app` | Bottom tabs, `Navigator.push` without route names | a global service locator | the app's for the tabs and the post; the sheet package's for signing in, a full-screen dialog over the profile tab |

To draw them, from this repository:

```sh
dart run contact_sheet export example/shop_app
dart run contact_sheet export example/notes_app
dart run contact_sheet export example/tabs_app
```

Each map is then in `example/<app>/contact_sheet/map/`.

## This repository

| Path | What |
| --- | --- |
| `bin/`, `lib/` | Package `contact_sheet`, pure Dart: the command, the sheet's reading, the map's layout, HTML, SVG and JSON, shutter's shots, the basis from git |
| `lib/src/l10n/` | The words (ARB): the command speaks English; the map, English or Japanese |
| `doc/` | The playbook and the reference for AI agents, as `agent` and `manual` print them |
| `example/` | The example apps and their sheet packages |
| `test/`, `tool/` | The tests; the generators of the command's words from the ARB files, and of the HTML's route from `lib/src/route.dart`, compiled to JavaScript |
| `AGENTS.md` | For AI agents working on this repository |
| `CHANGELOG.md` | What each version changed |

## Tests

```sh
dart test
```

And `flutter analyze` in each example app, and in its `contact_sheet/` where it is a package (shop_app, tabs_app).

## Issues and license

Report problems and ideas in [the issues](https://github.com/koji-1009/contact_sheet/issues).
Contact Sheet is under the MIT license ([LICENSE](LICENSE)).
