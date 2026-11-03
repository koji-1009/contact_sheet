// The documents for AI agents that the command prints, in English whatever
// the user's language. Each mirrors a file under `doc/`, kept byte-identical
// by test/docs_test.dart: edit both.

/// `contact_sheet agent`: the step-by-step playbook, `doc/agent.md`.
const agentText = r'''
# contact_sheet — agent playbook

Contact Sheet draws a Flutter app as a map: every page as an image, every transition as an arrow.
The images are `@Preview`s, shot by shutter.
Your task: write the app's **transition structure** (the sheet, `contact_sheet/sheet.yaml`) by reading its code, naming a `@Preview` for each state of each page, and make the map with `contact_sheet export`.

The previews come first from the app itself: a team that uses shutter or the Widget Previewer has a `@Preview` per page already. Use those.
Where a page, or a state of it, has none, write the preview in the **sheet package** (`contact_sheet/`, a small Flutter package inside the app's repository that imports the app).
Do not add previews, or anything else, to the app: whether the app keeps previews of its own is the team's choice.

`contact_sheet manual` is the reference: every field of the sheet, what the map holds, the runs, the exit codes.

## The steps

Run the commands in the app's directory.

1. `contact_sheet init`: writes an empty `contact_sheet/sheet.yaml`.
2. Read the app: its router, its pages, and its `@Preview`s (search for `@Preview(`; a `@MultiPreview` subclass counts too).
3. For the pages and states the app has no preview of: `contact_sheet init --package` writes the sheet package's skeleton, then write the previews there (see "Previews in the sheet package"). In `contact_sheet/`: `flutter pub get` and `flutter analyze`.
4. Write `sheet.yaml` (see "Writing the sheet"). Then `contact_sheet lint`: what the sheet itself shows may be missing (a page no arrow leads to, a state nothing leaves from or arrives in, unless what the page loads decides it, a condition's value nothing gives) or written twice. Hints, not errors: look at each.
5. `contact_sheet export`: has shutter shoot the previews the sheet names and writes the map to `contact_sheet/map/`. A mistake in `sheet.yaml` is told with where it is. A state that could not be shot is told with shutter's error and where it points: fix the sheet package's preview, or tell the user about the app's, and export again; `--only <page id>` shoots that page's previews alone and keeps the other images, and `--strict` fails while any state has no image. Look at `contact_sheet/map/map-dev.svg`: every page has its image, every transition its arrow. `map.svg` is the same for the people outside the code: an arrow's label without what only the code names.
6. `contact_sheet basis`: records the app as the sheet was written from it (`contact_sheet/basis.json`).

Later, to bring the sheet up to date: `contact_sheet changed --by-page` lists the app's files changed since the basis, by the pages the sheet names them for, then those on no page (a page the sheet does not have yet may be among them).
Update the sheet for them (pages, edges, dependencies, the sheet package's previews and fakes they touch), keep the rest as it is, export, and record the basis again.

## Previews in the sheet package

Only for what the app has no preview of, or where the app's cannot show it: a page that needs the pages under it (its back button), a state reached through a redirect, a page that reads the router in `build`.

1. **Dependencies** (`contact_sheet/pubspec.yaml`). Add the app's own dependencies that the fakes and previews use directly (`flutter_riverpod`, `go_router`, ...), at the versions the app uses.
2. **Fakes** (`lib/fakes/`). Implement the app's repositories / API clients with fixed data, so pages render without a network. Prefer the repository layer over HTTP. If the app's previews have fakes, use theirs.
3. **States** (`lib/fakes/states.dart`). Public top-level functions `Widget name(Widget child)` that put the app's DI on the fakes: `ProviderScope(overrides: ...)`, `MultiProvider`, `MultiBlocProvider`, re-registering GetIt, an `InheritedWidget`, whatever the app uses. Previews do not go through the app's `main`: what `main` sets up is provided here or in the fakes. The preview function runs before its wrapper: do not read what the wrapper sets up from the function.
4. **Previews** (`lib/preview/<page>.dart`, one page per file). A public top-level function that builds the page, with one `@Preview` per state (`wrapper:` one of the states, `size:` always set, the device the map shows it on). In the app's own `MaterialApp` (its `theme`, `localizationsDelegates`, `supportedLocales`, `builder`; `debugShowCheckedModeBanner: false`). To show it as the app does, start it the way the app does:
   - go_router: `MaterialApp.router(routerConfig: GoRouter(initialLocation: ..., routes: <the app's routes>, redirect: <the app's redirect>))`.
   - auto_route: `MaterialApp.router(routerConfig: AppRouter().config(deepLinkBuilder: (_) => DeepLink([ProductDetailRoute(id: 'p1')])))`.
   - Navigator 1.0: `MaterialApp(onGenerateRoute: <the app's>, initialRoute: '/item', ...)`, or the app's `routes` with `initialRoute`.

   If the app pushes the page over another one (`context.push`, `Navigator.push`), start it over that page, so its back button shows as in the app: with go_router, push the location on a stack made by `router.configuration.findMatch(...)`; with Navigator 1.0, `onGenerateInitialRoutes` returning the page below and the page (an app that names no routes still needs `onGenerateRoute: (_) => null`: without `home`, `routes` or `onGenerateRoute` the `MaterialApp` has no navigator, and the shot comes out blank). A small `startAt(location, from:)` in `lib/preview/` keeps the previews short (see Contact Sheet's examples).
5. **Plugins.** shutter renders the previews in `flutter test`, where no plugin has an implementation: a call to one throws `MissingPluginException`. Replace what calls plugins with fakes.

## Writing the sheet

```yaml
dependencies:            # what pages read that the previews replace
  - name: AuthRepository
    target: authRepositoryProvider      # what the previews override
    source: lib/data/auth_repository.dart
conditions:              # what the app keeps across pages, shown on them or not
  - name: Login
    values: [Guest, Logged in]          # the first is what the app launches with
    source: lib/data/auth_repository.dart
pages:
  - id: home
    label: Home
    section: Shopping                    # a heading pages are grouped under
    widget: HomePage                     # the page widget's class
    source: lib/features/home_page.dart  # its file, relative to the app
    path: /                              # the route's path, as declared
    dependencies: [AuthRepository]
    memo: |                              # optional, for the people reading
      The product list. Guests can shop from here.
    links:                               # optional
      - label: Spec
        url: https://example.com/specs/home
    states:                              # one per @Preview; the first is drawn on the map
      - name: Guest
        if: {Login: Guest}               # the page's look while the condition has this value
        preview: lib/features/home_page_preview.dart#home        # the app's
        uses: {AuthRepository: guest}            # the fake each one is in
      - name: Logged in
        if: {Login: Logged in}
        preview: lib/features/home_page_preview.dart#home@1      # its 2nd @Preview
        uses: {AuthRepository: logged in}
      - name: Loading
        preview: lib/features/home_page_preview.dart#home@2
        data: true                       # what the page loads decides it, not the arrow
  - id: login
    label: Log in
    states:
      - name: From checkout
        preview: contact_sheet/lib/preview/login.dart#login       # the sheet package's
      - name: From home
        preview: contact_sheet/lib/preview/login.dart#loginFromHome
edges:
  - from: home
    to: product_detail
    trigger: other:Tap a product # text:, label:, other:<what>, back; key:, type:
    kind: push                   # push (default), go, replace, pop, redirect
    source: lib/features/home_page.dart
  - from: home
    to: login
    trigger: text:Log in
    when: Guest                  # the states of `from` it happens in: one, or [a, b]; none: any
    then: From home              # the state of `to` it arrives in, or {Guest: a, Member: b} by the state it leaves; none: the state of the name it leaves
    source: lib/features/home_page.dart
  - from: [home, product_detail] # one page, or several: the same transition from each
    to: cart
    trigger: label:Cart
    source: lib/features/app_bar.dart
  - from: product_detail
    to: login
    trigger: text:Buy
    if: {Login: Guest}           # the conditions' values it happens while, whatever `from` shows
    then: From checkout
    kind: redirect
    source: lib/router.dart
  - from: login
    to: checkout
    trigger: text:Log in
    when: From checkout
    set: {Login: Logged in}      # the values it gives: home shows Logged in from then on
    kind: go
    source: lib/features/login_page.dart
entries:                         # deep links into a page, from outside the app
  - to: product_detail
    via: /products/:id
    source: lib/router.dart
```

Each field, and how `preview` names a `@Preview`: `contact_sheet manual`, "The sheet".

- Read the router first: its routes give the pages and their paths, its redirects the guards. Write what the code says, including redirects and conditions far from the button (router redirects, listeners, guards).
- Put the app's start first (its home, or what opens first): the map starts from the first page.
- The map's labels stay short; a page tapped in the HTML reads each of its transitions as a sentence ("When Guest, tap “Log in” → Log in (From home)"), so write `trigger`, `when`, `then` and the conditions' names and values for the people outside the code.
- Name a `trigger` by the words on the screen: `text:` what a button says, `label:` the semantics label or tooltip of an icon button. A row of a list, or a text that changes (it has a name or an amount in it): `other:` and how a person would say it (`other:Tap a product`), not the data the state happens to show. `key:` and `type:` only when nothing on the screen says it: they are shown to developers only.
- Write one edge per outcome: if a guest is redirected, that is a separate edge with its own `if` (or `when`) and `kind: redirect`. One that happens in several states of its page names them all: `when: [Guest, Member]`; arriving in another state by the state it leaves, it is still one edge: `then: {Guest: A, Member: B}`. The same transition from several pages (the bottom tabs, a button in each page's app bar) is one edge: `from: [feed, search]`.
- What the app keeps across its pages (logged in, what is in the cart) is a `condition`, kept while pages that do not show it come between: a page whose look changes with it has a state of each value (`if: {Login: Guest}`), an edge that only happens for some values says them (`if:`), whatever its `from` shows, and an edge whose code changes it says what it gives (`set: {Login: Logged in}`, `set: {Cart: Empty}`). Do not give a page states that look the same only to carry a condition: write the condition. What several pages show alike is a condition; what one page loads (empty, loading, an error) is `data: true`.
- Where an edge arrives: its `then`; without it, in the state of `to` of the name it leaves (Full stays Full), if the conditions allow it; else in the state of `to` of the conditions' values, its first, or a `data` state. So a page of the conditions needs no `then`: home after logging in shows Logged in by its `if`. Write `then` where the code decides the state another way: a redirect that carries where the user came from, a page opened with an argument. The map shows the state an arrow arrives in at its end, and a route between two pages follows it and the conditions. `lint` tells a state nothing arrives in, a condition's value nothing gives, a page of the conditions with no state for some of their values, and an `if` no way through the app meets.
- A condition that changes without leaving the page (signing out in place) is an edge from the page to itself, with `set` and `kind: replace`: it is listed, not drawn, and the route takes it.
- A `MultiPreview` gives several `Preview`s from one annotation: a state names one by its place, `#notesPage@0.1` for the second the first annotation gives.
- `variants` (top level, optional): the ways every state is shot, switched between in the HTML, the first the map's. `{name: Android, platform: android}` shoots as Android (the default is iOS); `{name: Tablet, preview: Tablet}` takes, for each state, the `Preview` named `Tablet` that the state's annotation gives besides (a `MultiPreview` of devices the app has, or one you write in the sheet package). A state with no such `Preview` has no image in that variant.
- `kind` is what the move does to the history, and the route between two pages follows it: a `push` or a `redirect` puts `to` over `from`, and its back returns to `from`; a `replace` takes `from`'s place; a `go` starts the history again (nothing under `to`). A pop (`kind: pop`, drawn dashed) only when it tells something the back of a push does not: an action that goes back (saving, deleting: `trigger: text:Save`, with `then` for the state it lands in; without `to` when it goes back to whichever page opened it, a form opened from several), or a back that goes elsewhere than the page under it (a nested route reached by `go`, whose back goes to its parent). Do not write the back to the page under it, nor a redirect's back: it goes to the page where the user tapped, which the redirect's push already says.
- A dialog or a bottom sheet: judge whether it is a transition at all, not by how Flutter shows it (a route on the `Navigator` is how Flutter does it). A plain confirmation or choice that only goes on: nothing to write. One a reader should see, with outcomes that lead apart: a state of the page under it (a preview with it open), entered by an edge to itself with `then`, its buttons edges `when` that state; where the back asks first (discard changes?), that edge has `trigger: back`, and takes the back's place. Full-screen, a flow of its own, or opened alike from many pages: a page.
- Tabs that each keep their own history (go_router's `StatefulShellRoute`, a `UITabBarController` with a navigation controller per tab) are a bar in `tabs`: each branch's first route is a tab's `page`, its `trigger` the tab's words; the branch's other routes are pages with `tab:` (the tabs they are shown in); a route shown over the whole bar (its `parentNavigatorKey` the root navigator's, or outside the shell) has none. `retap: first` where tapping the tab shown goes back to its first page (`goBranch(i, initialLocation: i == currentIndex)`; iOS does). Do not write the switches between tabs as edges: the bar does them. A bar that switches pages in place and keeps no history is not one: write its tabs as edges with `kind: replace`.
- What can happen on every page (a session that expires, a forced update) is one edge `from: '*'`, with `if` for when (not `when`): drawn once, from outside.
- Screens outside the app (signing in through the browser, a payment sheet, sharing, the OS settings) are not pages: write the step as one edge from the button to where the app comes back, with what it gives (`set: {Login: Logged in}`), and another for each other outcome (cancelled). Nor are written: the pages a deep link builds under its page, pops through several pages to one in between, the browser's back and forward.
- `entries`: the links the code handles on purpose (ones it publishes, a notification it opens), not every route a link could name; `then` where the link decides the state the page opens in (`/login?from=/checkout`); `if` where it opens the page only for some values of the conditions (the link the router sends a guest elsewhere with is another entry, to that page).
- `memo` and `links`: write them when the code or the repository tells them. People write these by hand too: keep the ones you did not write as they are.

`basis.json` is written by `contact_sheet basis`. Do not edit it.
''';

/// `contact_sheet manual`: the reference, `doc/manual.md`.
const manualText = r'''
# contact_sheet manual

`contact_sheet agent` is the step-by-step playbook; this is the reference.

## What Contact Sheet draws

The map of a Flutter app: each state of each page as an image, each transition as an arrow, each deep link as an arrow from outside.
It is drawn from the app's **sheet**, `contact_sheet/sheet.yaml`, the app's transition structure as data, written by an AI agent reading the app's code and kept in git with the app.
Contact Sheet draws the sheet as it is: it does not check it against the app, and it changes nothing in the app.

## Where the images come from

Each state names a `@Preview`.
The app's own previews are shot in the app; the previews the app does not have are written in the **sheet package** (`contact_sheet/`, a plain Flutter package that imports the app and does not depend on Contact Sheet; `contact_sheet init --package` writes its skeleton) and shot there.
shutter shoots them as a library, in `flutter test`, drawn as iOS: nothing else to install.
`flutter pub get` runs first in each project, unless its package config is newer than its pubspec and lock file.

## The sheet

Three lists of what is drawn, the conditions the app keeps across them, its tab bars, one for reference, and the variants it is shot in. Paths are relative to the app, with `/`.

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
| `links` | | `label` and `url` each, shown with the memo; linked when `https:`, `http:` or `mailto:` |
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
| `to` | required | A page id. A `pop` may leave it out: back to the page under it, whichever opened it (`text:Save` on a form opened from several pages), an edge to each page it can be put over |
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
| `pages` | required | Its tabs, in order: `page`, the tab's first page; `trigger`, what switches to it, in the screen's words; `if`, the values of the conditions it can be switched to while |
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

### `variants`

The ways every state is shot, switched between in the HTML; the first is the map's (its boxes, `map.svg`). None: one, as iOS.

| Field | | What |
| --- | --- | --- |
| `name` | required | What the HTML calls it (`Android`, `Tablet`) |
| `platform` | | `ios` (the default) or `android`: how shutter draws it |
| `preview` | | The name of the `Preview` each state is in this variant, among those its annotation gives (a `MultiPreview` of devices); none: the one the state names. A state whose annotation gives none of that name has no image in it |

Each platform the variants name is one more shot of every preview.

## The map

`contact_sheet export` writes it to `contact_sheet/map/`; with `--out <folder>`, to `<app>_contact_sheet/` in that folder (or that folder itself, when it is named so).
Each export replaces `images/`.

- `index.html`: one file, the images in `images/` next to it, to be opened from disk or served anywhere. Two views of the same pages: the map and the list (one page under the other, by section, each with its states and the pages it goes to and comes from), with the table of the transitions (by page: in which state, doing what, it leads where), the route between two pages, a page's details, search, and each image opening large.
  - The map: a page chosen brings the map to it and the pages next to it, with its memo, links, states and transitions (as sentences) beside it. A state chosen there is shown on the map, with only the arrows that can happen in it, and the pages they arrive at in the state they arrive in; its name is under the page's. Twice on a page, its image large. From far out, the sections' names to go into.
  - The route between two pages: the fewest steps from one to the other as the app's navigator goes, each as a sentence. It follows the states (from a state, only what can happen in it), the conditions (`if`, `set`) and the history (`kind`, and the back of every page put over another). It starts with the history the fewest steps from the app's launch (the first page in its first state the conditions' first values allow) reach the first page with, in the state and under the conditions' values chosen beside it (those reached, by default; a value the state is of, fixed by it); the pages under it, where a back goes, are named. Its fewest steps are exact: a shortest path in the pushdown system the history makes, its stack the pages and its control the conditions' values, each page entered under each value summarised once. In a tab bar of `tabs`, a switch finds a tab as it was left, and the other tabs' histories are named beside the route; a route found is the fewest of all (searched again past the three pages of a tab's history kept exactly, where a tab left deeper might have made it shorter). There, the histories can be too many to search to the end (each tab's multiplied together): the route then says the app may have a route, or a shorter one, than it shows; and one none is found to may still go through a tab left deeper.
  - Search: pages by their names, memo, states, links and what is done on them (a button's words find its page); the table narrows as it is typed.
  - Addresses: `#map/<page id>`, `#map/<page id>/<state>`, `#route/<from>/<to>`, `#route/<from>/<state>/<to>`, each route followed by `/<condition>=<value>` for each value chosen, `#list/<page id>`, `#page/<page id>` (its details), `#table`; with variants, `?variant=<name>` before them, and `?show=pages` or `?show=flow` for how much the map shows.
  - How much the map shows, chosen under it: the pages alone, with the arrows, or with what each arrow says (the default). A page chosen, or a route, shows its own arrows whatever.
  - Variants: chosen in the header ("Shown as"), every image follows; on the map, in the first variant's boxes, whole.
  - It says which app it was drawn from (its version and branch; its commit for developers), when it was exported, and, with a basis, how many changes of its code the sheet names for no page. What only developers read (the code's names, files, fakes, `go` and `replace`) is shown when "For developers" is ticked. Light or dark as the browser is set; on a phone, one column; printed, the list or the table.
- `map.svg`: the whole map as one picture, the images in it, the labels what anyone reads, each page a link to it in `index.html`; `map-dev.svg`, with what developers read too.

The layout: each section is an island of its own. In it, the flow runs left to right from where it comes in (the first page, an arrow from another section, a deep link, in that order); the pages nothing in the section leads to are a row under the rest. The islands are laid in rows. Three or more arrows from other sections into one page that say the same are drawn as one short arrow into it, `<label> ×<n>`; those from every page always, `<label> From any page`. A tab's first page has its bar drawn under it, its own tab lit; the first pages of one bar's tabs stand in one column.
- `sheet.json`: what they are drawn from, for other tools and AI agents.
- `images/`: each state's shot, named by its shot id (`sheet-` before it for the sheet package's).

A state shutter could not draw has no image: its error is told by the command and shown in the HTML (`error` in `sheet.json`); so is one whose preview file does not exist, is not under `lib/`, or has no `@Preview`.
The export goes on for the rest.

### `sheet.json`

`schemaVersion` (1) changes when what is there does.
Top level: `app`, `locale`, `generatedAt`, `conditions` (`name`, `values`, `source`), `tabs` (each `pages`, with `page`, `trigger` and `if`; `retap`, `first` or `stay`; `source`), `variants` (`name`, `platform`, `preview`; one, unnamed, when the sheet names none), `release` (`version`, the app's pubspec's; `commit` and `branch`, where git knows them), `basis` (when there is one: `commit`, `found`, `changed`, `unmapped`: what changed in `lib/` that the sheet names for no page, nor as a preview), `canvas` (`width`, `height`, `labelHeight`), `sections` (`name` and its island's box), `pages`, `edges`, `entries`, `bundles`.

- A page: the sheet's fields (`tab` a list, empty for none), its `dependencies` in full, `sheetChanged` (its files changed since the basis), its box (`x`, `y`, `width`, `height`; its label is the bottom `labelHeight` of it), and `states`: `name`, `preview`, `project` (`app` or `sheet`, the sheet package), `uses`, `data`, `if` (`{}` for none), and as the first variant draws it, `shot` (shutter's id), `width`, `height`, `image` (relative to `sheet.json`, or null), `error` (or null); `variants`: those five in each variant, in order.
- An edge: `key`, which transition it is, the same from one export to the next while its pages, trigger, `when`, `if` and kind stay (`home>cart label:Cart push`, `cart>checkout text:Buy [Full] {Login=Member} push`; ` #2` after one written twice); the sheet's fields, one edge for each page a list of `from`s names (every page for `'*'`; `anywhere` true then) and, for a pop without `to`, for each page it can be over (`under` true); `item`, its place in the sheet's `edges` (`when` a list, empty for any state; `if` a list of values by condition, `{}` for none; `set`, `{}` for none; `tab` or null; `then` as written: a state, a map by the state it leaves, or null); `arrive`, the states of `to` it can arrive in from each state of `from` it happens in, under any values of the conditions it can happen while (one where said or kept by its name; else `to`'s first, its `data` states and its states of the conditions, those the values allow; empty for a state it cannot happen in); `label` (as a developer reads it), its three parts in order (`labelCode`: what only the code names; `labelPlain`: what anyone reads; `labelKind`: `go` or `replace`), and either `curve` (a cubic Bézier's 4 points, flattened) and `labelAt`, or `bundle`: the bundle it is drawn in.
- An entry: `key` (`product_detail</products/:id`, then its `if` as an edge's), the sheet's fields (`then` or null; `if`, `{}` for none; `tab` or null), `line` (2 points, flattened) and `labelAt`.
- A bundle: `to`, `edges` (their places in `edges`), `label`, `line` and `labelAt`.

## Basis and changes

`contact_sheet basis` records the app as it is now as what the sheet was written against, in `contact_sheet/basis.json`: the commit, and the files that differed from it then (changed, or not in git yet) with their content's hash. Do not edit it.
`contact_sheet changed` lists the app's files changed since then (the sheet package's own are not the app's changes).
The map marks a page, for developers, when one of its files changed: its `source`, its dependencies' sources, the sources of its edges out and of the deep links into it.
A mark is a hint: a change does not make the sheet wrong.

## Runs

shutter writes each shot into a run (`.dart_tool/shutter/runs/` of the project it shoots in).
Once the images are copied into the map, the export deletes the runs it made, so the team's own runs in the app stay as they were.
`contact_sheet prune` deletes what an interrupted export left: every run in the sheet package, and in the app only those an export listed (`contact_sheet/.dart_tool/contact_sheet/runs`) or left half made, cut short while shutter shot it (a run with no manifest that was not there before the export shot).

## What goes into the app's git

| Path | In git |
| --- | --- |
| `contact_sheet/sheet.yaml`, `contact_sheet/basis.json` | yes |
| The sheet package (`contact_sheet/pubspec.yaml`, `analysis_options.yaml`, `lib/`) | yes |
| `contact_sheet/map/` | as the team chooses: mostly images |
| `contact_sheet/.dart_tool/` | no (`init --package` adds it to the app's `.gitignore` unless `.dart_tool/` is ignored already) |

## Exit codes

| Code | When |
| --- | --- |
| 0 | Done |
| 64 | A wrong use: the message and the usage on stderr; `export --only`: the sheet has no such page |
| 65 | `sheet.yaml` cannot be read (said with where); `changed`: the basis's commit is not in the repository; `export --strict`: a state has no image |
| 66 | No `pubspec.yaml` in the directory; no `sheet.yaml`; `changed`: no basis yet |
| 69 | `flutter pub get` failed; `export`: shutter cannot run (no Flutter SDK) |
| 70 | An unexpected error (`--verbose` tells where it came from) |
| 78 | `basis`: not a git repository; `export`: the app or the sheet package is not set up for shutter (no `flutter_test` in `dev_dependencies`) |

## Commands

| Command | What |
| --- | --- |
| `agent` | Print the playbook for AI agents |
| `manual` | Print this reference |
| `init [--package]` | Write an empty sheet; with `--package`, the sheet package's skeleton too |
| `export [--out <folder>] [--only <page id>]... [--locale <en\|ja>] [--strict]` | Shoot the previews the sheet names and write the map; `--only`, those pages' alone, the others keeping their images; `--locale`, in that language; `--strict`, failing while a state has no image |
| `lint` | Tell what the sheet itself shows may be missing or written twice |
| `basis` | Record the app as the sheet was written against |
| `changed [--by-page]` | List the app's files changed since the basis; `--by-page`, by the pages the sheet names them for |
| `prune` | Delete the runs of shutter's Contact Sheet left |

Each but `agent` and `manual` runs on the app directory given last, the current one by default.
`contact_sheet help <command>` tells a command's options; `--version`, the version.
''';
