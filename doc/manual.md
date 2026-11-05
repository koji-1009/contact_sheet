# sheet manual

`sheet agent` is the step-by-step playbook; this is the reference.

## What Contact Sheet draws

The map of a Flutter app: each state of each page as an image, each transition as an arrow, each deep link as an arrow from outside.
It is drawn from the app's **sheet**, `contact_sheet/sheet.yaml`, the app's transition structure as data: the screen transitions that actually happen in it, written by an AI agent from what tells how the app works, such as its code and its specifications, and kept in git with the app.
Contact Sheet draws the sheet as it is: it does not check it against the app, and it changes nothing in the app.

## Where the images come from

Each state names a `@Preview`.
The app's own previews are shot in the app; the previews the app does not have are written in the **sheet package** (`contact_sheet/`, a plain Flutter package that imports the app and does not depend on Contact Sheet; `sheet init --package` writes its skeleton) and shot there.
shutter shoots them as a library, in `flutter test`, drawn as iOS: nothing else to install.
`flutter pub get` runs first in each project, unless its package config is newer than its pubspec and lock file.

## The sheet

Three lists of what is drawn, the conditions the app keeps across them, its tab bars, one for reference, the tags its pages have, and the variants it is shot in. Paths are relative to the app, with `/`.

### `pages`

| Field | | What |
| --- | --- | --- |
| `id` | required | The page's name in the sheet: what edges, entries and addresses use |
| `label` | required | Its name on the map |
| `section` | | A heading pages are grouped under: an island on the map, in the order the sheet first names each section |
| `widget` | | The page widget's class |
| `source` | | Its file |
| `path` | | The route's path, as declared |
| `route` | | With typed routes, the route class (go_router_builder's `GoRouteData` subclass); write `path` too |
| `dependencies` | | Names from the top-level `dependencies` it reads |
| `memo` | | For the people reading the map: shown beside the page |
| `tags` | | By the name of one of the `tags`, the page's value of it: text (`Analytics: home_view`), which goes in the tag's `url`; a link of its own (`{label: Home spec, url: ...}`); or a list of them. Shown with the memo; linked when `https:`, `http:` or `mailto:` |
| `states` | required | One per `@Preview`, in order: the first is drawn on the map |
| `tab` | | With `tabs`, the tabs it is shown in, by their first pages (`feed`, or `[feed, search]`): pushed from a page of one of them, it goes on that tab's history. None: over the whole bar (settings, a full-screen dialog) |

The first page is where the map starts: the pages are laid out left to right by how far the arrows take them from it.

A state:

| Field | | What |
| --- | --- | --- |
| `name` | required | The state's name |
| `preview` | required | The `@Preview` it is (below) |
| `uses` | | For reference: the fake each dependency is in, `{name: fake}` |
| `data` | | `true` when what the page loads decides it (empty, loading, an error), not the arrow it comes by: an arrow or deep link that says no state may arrive in it, as in the page's first |
| `if` | | The values of the `conditions` it is the page's look in, one each (`{Login: Member}`): in it, the app has them, and an arrow that says no state arrives in it while they hold. None: any values |

`preview` names a `@Preview` as shutter names it: `<file>#<declaration>@<n>.<k>`.

- `<file>`: relative to the app; `contact_sheet/...` for the sheet package's.
- `<declaration>`: `fn` for a top-level function, `Class.method`, `Class.new` for an unnamed constructor, `Class.named`.
- `@<n>`: the annotation's place among every annotation on that declaration, from 0 (`@0` may be left out). Another annotation before it (`@visibleForTesting`) counts.
- `.<k>`: of the `Preview`s the annotation gives (a `MultiPreview` gives several, in the order its `transform()` returns them), which, from 0 (`.0` may be left out): shutter's runtime part of the shot id.

### `edges`

| Field | | What |
| --- | --- | --- |
| `from` | required | A page id, or a list of them (`[feed, search]`): the same transition from each, as the bottom tabs or a button in each page's app bar; or `'*'`: from every page but `to`, as a session that expires anywhere (with `if`, not `when`), drawn once, from outside |
| `to` | required | A page id. A `pop` may leave it out (not from `'*'`): back to the page under it, whichever opened it (`text:Save` on a form opened from several pages), an edge to each page it can be put over |
| `trigger` | | What the user does: `text:` a `Text`, `label:` a semantics label, `key:` a `ValueKey<String>`, `type:` a widget class (as shutter names a target), `back` (the app bar's back or the system's), or `other:<what>` for anything else (a swipe, a timer). None when nothing does: the router alone |
| `when` | | The states of `from` it happens in: one, or a list (`[Guest, Member]`); none: any. With a list of `from`s, a state each of them has |
| `if` | | The values of the `conditions` it happens while, whatever `from` shows: `{Login: Guest}`, or a list of values (`{Login: [Guest, Banned]}`); a condition not named: any. Two edges for one action that leads apart by a condition (a redirect for a guest) each say theirs |
| `set` | | The values it gives the `conditions`, one each (`{Login: Member}`, `{Cart: Empty}`): what the code changes on the way. A `then` naming a state of the conditions gives theirs too |
| `then` | | The state of `to` it arrives in: one, or one by the state of `from` it leaves (`{Guest: From home, Member: Signed in}`, its keys among `when`'s states). None, or none for the state it leaves: the state of `to` of that state's name, as what the user does not change stays (a full cart stays full), if the conditions after it allow it; else not said: `to`'s first state, its `data` states, and its states of the conditions, those the conditions after it allow |
| `kind` | | How the code moves, what it does to the history: `push` (the default) and `redirect` put `to` over `from`, `replace` takes `from`'s place, `go` starts the history again, `pop` (drawn dashed) takes `from` off |
| `tab` | | For a `go` to a page shown in several tabs: the tab it opens it in, by its first page; none: the tab shown, if it is one of them, else the first |
| `source` | | Where in the code |

An edge's label on the map: its trigger, its `when`, its `if`'s values, and its `kind` unless the line tells it (a push; a pop, dashed).
`key:` and `type:` name what only the code names, and `go` and `replace` only how the code keeps its pages: in the HTML they are shown only to developers (below), and they are not in `map.svg`.
A page tapped in the HTML reads each of its transitions as a sentence: in which state and while which values, doing what (`text:` and `label:` as "tap “…”", `other:` as written, `back` as going back), it leads where, arriving in which state (as `then` says it; a state kept by its name goes unsaid), giving which values (its `set`).
Where it arrives is what the map shows at an arrow's end for the state chosen on its page, and what the route between two pages follows; where it is not said, the map shows the first of those it can arrive in, and the route takes the one the conditions are then, the first or any `data` state.
Every page put over another (a `push`, a `redirect`) goes back to it, by its back, in the state of the name it left (full above, full below), else in its own, each if the conditions now allow it, else as not said (logged in above, the page under shows logged in): that back is not written. A `pop` is written where it says more: an action that goes back (`text:Save`), with the state it lands in by `then` and the values it gives by `set`, or a back that goes elsewhere than the page under it. Anything written with `trigger: back` (such a pop, or a confirmation shown first: an edge to itself with `then`) takes the place of that back where it happens.

What the sheet does not say: a state changing within a page (an empty cart filled) is not a transition, as a page's states are how it starts; an edge from a page to itself is listed, not drawn. Where a condition changes on a page without leaving it (signing out in place), that edge to itself with `set` and `kind: replace` says it, for the route. A dialog or a sheet over a page is, as the agent judges it, nothing to write (a plain confirmation), a state of that page (its preview with the dialog open, entered by an edge to itself with `then`, its buttons edges `when` that state), or a page (full-screen, a flow of its own, or opened alike from many pages): how Flutter shows it (a route on the `Navigator`) does not decide it.

What the sheet does not draw, nor the route follow:

- screens outside the app (a sign-in in the browser, a payment sheet, the share sheet, the OS settings): write the step as one edge, from the button to where the app comes back, with what it gives (`set`), and one for each other outcome (cancelled);
- the pages a deep link or a notification builds under its page: its back is the page's (a written back to its parent, where the router has one);
- pops through several pages to one in between (`popUntil`); to the history's first, write `go`;
- the browser's back, forward and reload: the route is the app's own history;
- arrows that change with the screen's size (a list and its detail side by side on a tablet): the map's are the first variant's.

### `conditions`

What the app keeps across its pages, that a page between may not show: being logged in, what is in the cart. A page's states are how it looks; a condition is what the app knows the while, the same for every page, and a pop does not bring an older value back.
States name the values they are of (`if`), edges the values they happen while (`if`) and give (`set`), deep links those they open while (`if`): the route follows them, and an arrow that says no state arrives in the state of the values then. What several pages show alike is a condition; what one page loads (empty, loading) is `data`.

| Field | | What |
| --- | --- | --- |
| `name` | required | How the sheet calls it (`Login`) |
| `values` | required | Its values; the first is what the app launches with (`[Guest, Member]`) |
| `source` | | Where the app keeps it |

### `tabs`

Tab bars whose tabs each keep their own history: go_router's `StatefulShellRoute`, a `UITabBarController` with a navigation controller in each tab. A bar that switches pages in place and keeps no history is not one: write its tabs as edges with `kind: replace`.
Switching tabs is not written as an edge: the bar does it, from every page shown in its tabs, and finds each tab as it was left (at its first page, the first time). A page pushed from a page in a tab, and shown in that tab (its `tab`), goes on that tab's history; one that is not goes over the whole bar, which does not switch until it is gone. A `replace` by a page not shown in the tab goes over the bar too, the tab's page kept under it. A `pop` that lands on another page than the one under it takes that page's place, in the tab's history if that page was in it, whichever page it is. A `go` to a page in a tab opens it alone in that tab's history, the other tabs as they were; a `go` elsewhere leaves the bar.

| Field | | What |
| --- | --- | --- |
| `pages` | required | Its tabs, in order: `page`, the tab's first page; `trigger` (required), what switches to it, in the screen's words; `if`, the values of the conditions it can be switched to while |
| `retap` | | `first`: tapping the tab shown again goes back to its first page; `stay` (the default): it does nothing |
| `source` | | Where the app declares it |

With a bar, `lint` tells an `if` no way through the app meets only where the moves with the histories left out cannot meet it either: it may leave one untold.

### `entries`

Deep links into a page, from outside the app: none of the app's pages.

| Field | | What |
| --- | --- | --- |
| `to` | required | A page id |
| `via` | required | The link, as the code handles it (`/products/:id`) |
| `then` | | The state of `to` it opens in, where the code decides it (`/login?from=/checkout`); none: not said |
| `if` | | The values of the `conditions` it opens `to` while, as an edge's; none: any, as a link may come at any time. A link the router takes elsewhere for a guest is another entry, to that page |
| `tab` | | For a page shown in several tabs: the tab it opens it in |
| `source` | | Where in the code |

### `dependencies`

For reference: what pages read that their previews replace.

| Field | | What |
| --- | --- | --- |
| `name` | required | What pages and states call it |
| `target` | | What the previews override (`authRepositoryProvider`) |
| `source` | | Its file |

### `tags`

What the pages are tagged with, set alike for every page: where each page's analytics are, its design, its spec, who owns it. A page gives each tag it has its value (its `tags`). In the HTML, a page's values are shown with its memo, beside it when it is chosen and on the map above it; under the map ("With"), each tag, the memo and the transitions as sentences can be hidden, so that the map shows, say, its arrows and the analytics alone.

| Field | | What |
| --- | --- | --- |
| `name` | required | What the pages and the HTML call it (`Analytics`) |
| `url` | | Where a page's value is, `{value}` in it the value, what a URL cannot hold escaped (a space, a letter not ASCII) and its `/`, `?` and `#` kept, so a value may be a path (`https://analytics.example.com/screens/{value}`; the app on the web, `https://app.example.com{value}`, a page's value `/products/p1`); none: a page's value is text, or a link of its own |

### `variants`

The ways every state is shot, switched between in the HTML; the first is the map's (its boxes, `map.svg`). None: one, as iOS.

| Field | | What |
| --- | --- | --- |
| `name` | required | What the HTML calls it (`Android`, `Tablet`) |
| `platform` | | `ios` (the default) or `android`: how shutter draws it |
| `preview` | | The name of the `Preview` each state is in this variant, among those its annotation gives (a `MultiPreview` of devices); none: the one the state names. A state whose annotation gives none of that name has no image in it |

Each platform the variants name is one more shot of every preview.

## The map

`sheet export` writes it to `contact_sheet/map/`; with `--out <folder>`, to `<app>_contact_sheet/` in that folder (or that folder itself, when it is named so).
Each export replaces `images/`.

- `index.html`: one file, the images in `images/` next to it, to be opened from disk or served anywhere. Three views of the same pages: the map, the tree (the pages top to bottom, as a site map draws an app) and the list (one page under the other, by section, each with its states and the pages it goes to and comes from), with the table of the transitions (by page: in which state, doing what, it leads where), the route between two pages, a page's details, search, and each image opening large.
  - The map: a page chosen brings the map to it and the pages next to it, with its states, and its memo, tags and transitions (as sentences) as they are shown with the pages, beside it. A state chosen there is shown on the map, with only the arrows that can happen in it, and the pages they arrive at in the state they arrive in; its name is under the page's. Twice on a page, its image large. An arrow tapped, or its label, says what it is, as a sentence, beside the map, with the pages at its ends; a label's parts read apart (what is done, the states and the conditions' values it needs, a redirect). It opens where the app starts, its first page with its section, as large as its words read (whole, where the whole map reads so); ⤢ shows it whole, and nothing else moves it there: a page or a route let go leaves the map where it is. From far out, the sections' names to go into. A page's image is loaded once the map shows it, large enough to make out, or chosen, next to the page chosen, or on the route.
  - The route between two pages: the fewest steps from one to the other as the app's navigator goes, each as a sentence. It follows the states (from a state, only what can happen in it), the conditions (`if`, `set`) and the history (`kind`, and the back of every page put over another). It starts with the history the fewest steps from the app's launch (the first page in its first state the conditions' first values allow) reach the first page with, in the state and under the conditions' values chosen beside it (those reached, by default; a value the state is of, fixed by it); the pages under it, where a back goes, are named. Its fewest steps are exact: a shortest path in the pushdown system the history makes, its stack the pages and its control the conditions' values, each page entered under each value summarised once. In a tab bar of `tabs`, a switch finds a tab as it was left, and the other tabs' histories are named beside the route; a route found is the fewest of all (searched again past the three pages of a tab's history kept exactly, where a tab left deeper might have made it shorter). There, the histories can be too many to search to the end (each tab's multiplied together): the route then says the app may have a route, or a shorter one, than it shows; and one none is found to may still go through a tab left deeper.
  - The tree: each page under the page from which the fewest steps from the app's start first reach it, by a transition forward or a tab of its bar, its children in the sheet's order and the words of what reaches it on its branch. A transition back, one from every page, or one from a page to itself, is no branch: the map and a page's sentences tell those. The pages nothing from the start reaches are trees of their own, after it, said so. Scrolled, larger or smaller, opening as the map does (whole where it reads so, else as large as it reads, at the app's start; ⤢ shows it whole); a page tapped opens its details.
  - Search: pages by their names, memo, states, tags (their names and values) and what is done on them (a button's words find its page); the table narrows as it is typed.
  - Addresses: `#map/<page id>`, `#map/<page id>/<state>`, `#route/<from>/<to>`, `#route/<from>/<state>/<to>`, each route followed by `/<condition>=<value>` for each value chosen, `#tree/<page id>`, `#list/<page id>`, `#page/<page id>` (its details), `#table`; with variants, `?variant=<name>` before them, `?show=pages` or `?show=flow` for how much the map shows, `?back=hide` for the arrows back hidden, and `?hide=says`, `?hide=memo` or `?hide=tag:<name>`, once for each, for what is not shown with the pages.
  - How much the map shows, chosen under it: the pages alone, with the arrows, or with what each arrow says (the default); and the arrows back, shown or hidden (tapping "Back" in the legend). A page chosen, or a route, shows its own arrows whatever, and what they say as much as the rest: beside the map, they are sentences. What is shown with the pages ("With"), on the map above each page and beside a page chosen: its transitions as sentences, its memo, each tag, each shown (the default) or hidden.
  - Variants: chosen in the header ("Shown as"), every image follows; the map and the tree are laid out again, each page's box its screen at the scale the first variant's is drawn at.
  - It says which app it was drawn from (its version and branch; its commit for developers), when it was exported, and, with a basis, how many changes of its code the sheet names for no page. What only developers read (the code's names, files, fakes, `go` and `replace`) is shown when "For developers" is ticked. Light or dark as the browser is set; on a phone, one column; printed, the list or the table.
- With `--svg`, `map.svg`: the whole map as one picture, the images in it, to be passed around alone, the labels what anyone reads, each page a link to it in `index.html`; `map-dev.svg`, with what developers read too. Without it, those an export before wrote are deleted.

The layout: each section is an island of its own. In it, the flow runs left to right from where it comes in (the first page, an arrow from another section, a deep link, in that order); the pages nothing in the section leads to are a row under the rest. The islands are laid in rows. Three or more arrows from other sections into one page that say the same (and all go back, dashed, or none) are drawn as one short arrow into it, `<label> ×<n>`; those from every page always, `<label> From any page`. A tab's first page has its bar drawn under it, its own tab lit; the first pages of one bar's tabs stand in one column.
- `sheet.json`: what they are drawn from, for other tools and AI agents.
- `images/`: each state's shot, drawn at a pixel ratio of 1.5 (`--pixel-ratio`: 2 as sharp as a phone, 1 smaller), as WebP (lossless: as shutter drew it, in fewer bytes than its PNG; a side longer than a WebP's can be, 16383 pixels, made smaller), named by its shot id (`sheet-` before it for the sheet package's, then `android-` for an Android variant's). The SVGs hold them so too.

A state shutter could not draw has no image: its error is told by the command and shown in the HTML (`error` in `sheet.json`); so is one whose preview file does not exist, is not under `lib/`, or has no `@Preview`, and one whose image cannot be read.
The export goes on for the rest.

### `sheet.json`

`schemaVersion` (1) changes when what is there does.
Top level: `app`, `locale`, `generatedAt`, `conditions` (`name`, `values`, `source`), `tabs` (each `pages`, with `page`, `trigger` and `if`; `retap`, `first` or `stay`; `source`), `tags` (`name`, `url`), `variants` (`name`, `platform`, `preview`; one, unnamed, when the sheet names none), `release` (`version`, the app's pubspec's; `commit` and `branch`, where git knows them), `basis` (when there is one: `commit`, `found`, `changed`, `unmapped`: what changed in `lib/` that the sheet names for no page, nor as a preview), `canvas` (`width`, `height`, `labelHeight`), `sections` (`name` and its island's box), `pages`, `edges`, `entries`, `bundles`, `tree`.

- A page: the sheet's fields (`tab` a list, empty for none; `tags` a list, in the order written, of `tag`, `label` and `url`: the value in its tag's `url`, the page's own, or null), its `dependencies` in full, `sheetChanged` (its files changed since the basis), its box as the first variant lays the map out (`x`, `y`, `width`, `height`; its label is the bottom `labelHeight` of it), and `states`: `name`, `preview`, `project` (`app` or `sheet`, the sheet package), `uses`, `data`, `if` (`{}` for none), and as the first variant draws it, `shot` (shutter's id), `width`, `height`, `image` (relative to `sheet.json`, or null), `error` (or null); `variants`: those five in each variant, in order.
- An edge: `key`, which transition it is, the same from one export to the next while its pages, trigger, `when`, `if` and kind stay (`home>cart label:Cart push`, `cart>checkout text:Buy [Full] {Login=Member} push`; ` #2` after one written twice); the sheet's fields, one edge for each page a list of `from`s names (every page for `'*'`; `anywhere` true then) and, for a pop without `to`, for each page it can be over (`under` true); `item`, its place in the sheet's `edges` (`when` a list, empty for any state; `if` a list of values by condition, `{}` for none; `set`, `{}` for none; `tab` or null; `then` as written: a state, a map by the state it leaves, or null); `arrive`, the states of `to` it can arrive in from each state of `from` its `when` names (all, without one), under any values of the conditions it can happen while (one where said or kept by its name; else `to`'s first, its `data` states and its states of the conditions, those the values allow; a pop back to the page under it, in the state that page can be in there; empty for a state no values let it happen in); `label` (as a developer reads it), its three parts in order (`labelCode`: what only the code names; `labelPlain`: what anyone reads; `labelKind`: `go` or `replace`), `labelParts` (what anyone reads part by part: `text`, and `part`, `does`, `when` or `kind`), and either `curve` (a cubic Bézier's 4 points, flattened) and `labelAt`, or `bundle`: the bundle it is drawn in; neither for an edge from a page to itself, which is not drawn.
- An entry: `key` (`product_detail</products/:id`, then its `if` as an edge's), the sheet's fields (`then` or null; `if`, `{}` for none; `tab` or null), `line` (2 points, flattened) and `labelAt`.
- A bundle: `to`, `edges` (their places in `edges`), `label`, `line` and `labelAt`.
- The tree: `width`, `height`, `outside` (the roots of the trees nothing from the app's start reaches) and `pages`, in the sheet's order: `page`, its box, `parent` (null for a root), `depth`, what reaches it (`edge`, its place in `edges`, or `tab`, the tab's first page; both null for a root), and for one with a parent `line` (its branch's points, flattened) and, where it has words, `label` and `labelAt`.

## Basis and changes

`sheet basis` records the app as it is now as what the sheet was written against, in `contact_sheet/basis.json`: the commit, and the files that differed from it then (changed, or not in git yet) with their content's hash. Do not edit it.
`sheet changed` lists the app's files changed since then (the sheet package's own are not the app's changes).
The map marks a page, for developers, when one of its files changed: its `source`, its dependencies' sources, the sources of its edges out and of the deep links into it.
A mark is a hint: a change does not make the sheet wrong.

## Runs

shutter writes each shot into a run (`.dart_tool/shutter/runs/` of the project it shoots in).
Once the images are in the map, the export deletes the runs it made, so the team's own runs in the app stay as they were.
The WebP made of each shot is kept in `contact_sheet/.dart_tool/contact_sheet/webp/`, named by its PNG's hash: an export encodes only the shots that changed, and one of every page (without `--only`) deletes the rest.
`sheet prune` deletes what an interrupted export left: every run in the sheet package, and in the app only those an export listed (`contact_sheet/.dart_tool/contact_sheet/runs`) or left half made, cut short while shutter shot it (a run with no manifest that was not there before the export shot).

## What goes into the app's git

| Path | In git |
| --- | --- |
| `contact_sheet/sheet.yaml`, `contact_sheet/basis.json` | yes |
| The sheet package (`contact_sheet/pubspec.yaml`, `analysis_options.yaml`, `lib/`) | yes |
| `contact_sheet/map/` | as the team chooses |
| `contact_sheet/.dart_tool/` | no (`init --package` adds it to the app's `.gitignore` unless `.dart_tool/` is ignored already) |

## Exit codes

| Code | When |
| --- | --- |
| 0 | Done |
| 64 | A wrong use: the message and the usage on stderr; `export --only`: the sheet has no such page |
| 65 | `sheet.yaml` cannot be read (said with where); `changed`: the basis's commit is not in the repository; `export --strict`: a state has no image |
| 66 | No `pubspec.yaml` in the directory; no `sheet.yaml`; `changed`: no basis yet |
| 69 | `export`: no `flutter` to run (`FLUTTER_ROOT`, else the PATH), `flutter pub get` failed, or shutter cannot run |
| 70 | An unexpected error (`--verbose` tells where it came from) |
| 78 | `basis`: not a git repository; `export`: the app or the sheet package is not set up for shutter (no `flutter_test` in `dev_dependencies`) |

## Commands

| Command | What |
| --- | --- |
| `agent` | Print the playbook for AI agents |
| `manual` | Print this reference |
| `init [--package]` | Write an empty sheet; with `--package`, the sheet package's skeleton too |
| `export [--out <folder>] [--only <page id>]... [--locale <en\|ja>] [--strict] [--svg] [--pixel-ratio <ratio>]` | Shoot the previews the sheet names and write the map; `--only`, those pages' alone, the others keeping their images; `--locale`, in that language; `--strict`, failing while a state has no image; `--svg`, with `map.svg` and `map-dev.svg`; `--pixel-ratio`, the images drawn at it (1.5 by default) |
| `lint` | Tell what the sheet itself shows may be missing or written twice |
| `basis` | Record the app as the sheet was written against |
| `changed [--by-page]` | List the app's files changed since the basis; `--by-page`, by the pages the sheet names them for |
| `prune` | Delete the runs of shutter's Contact Sheet left |

Each but `agent` and `manual` runs on the app directory given last, the current one by default.
`sheet help <command>` tells a command's options; `--version`, the version.

## What `lint` tells

Hints, not errors, each saying what to look at; `export` tells them too.

- Pages: one no arrow leads to from the first page and no deep link opens; the first page with no state of the conditions' first values.
- States: one none of the page's arrows leaves from; one nothing arrives in (not `data`); two of the same values of the conditions; a page with no state of some values.
- Edges: one written twice; one written again in other states (one edge, `when` both's, `then` by the state it leaves); a `when` state of other values than the `if`; an `if` no way through the app meets there.
- Conditions: a value nothing names; one nothing gives, not the first.
- Deep links: one written twice.
- Tags: one no page has; one that three quarters of the pages or more have, and some do not.
- Tabs: a bar of one tab; an edge between two tabs of a bar (the bar switches them); a page opened from a tab it is not shown in, or from over the bar; a go or a deep link to a page in several tabs that names none.
