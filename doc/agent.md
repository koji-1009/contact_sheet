# contact_sheet — agent playbook

Contact Sheet draws a Flutter app as a map: every page as an image, every transition as an arrow.
The images are `@Preview`s, shot by shutter.
Your task: find out and think through the screen transitions that actually happen in the app, write them as its **transition structure** in the sheet's schema (the sheet, `contact_sheet/sheet.yaml`), naming a `@Preview` for each state of each page, and make the map with `contact_sheet export`.
Refer to what tells how the app works, such as its code and its specifications. Write what happens: where they differ, the code is what the app does.

The previews come first from the app itself: a team that uses shutter or the Widget Previewer has a `@Preview` per page already. Use those.
Where a page, or a state of it, has none, write the preview in the **sheet package** (`contact_sheet/`, a small Flutter package inside the app's repository that imports the app).
Do not add previews, or anything else, to the app: whether the app keeps previews of its own is the team's choice.

`contact_sheet manual` is the reference: every field of the sheet, what the map holds, the runs, the exit codes.

## The steps

Run the commands in the app's directory.

1. `contact_sheet init`: writes an empty `contact_sheet/sheet.yaml`.
2. Look into what tells how the app works, such as its code (its router, its pages, and its `@Preview`s: search for `@Preview(`; a `@MultiPreview` subclass counts too) and its specifications.
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
  - id: product_detail                   # each page the edges name, with a state at least
    label: Product
    states: [{name: Standard, preview: contact_sheet/lib/preview/product.dart#product}]
  - id: cart
    label: Cart
    states: [{name: Standard, preview: contact_sheet/lib/preview/cart.dart#cart}]
  - id: checkout
    label: Checkout
    states: [{name: Standard, preview: contact_sheet/lib/preview/checkout.dart#checkout}]
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

- Read the router first: its routes give the pages and their paths, its redirects the guards. Write what the app does, including redirects and conditions far from the button (router redirects, listeners, guards).
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
- `memo`: what you found about the page that its image and arrows do not show. `links`: where more is written about it, such as its specification. People write these by hand too: keep the ones you did not write as they are.

`basis.json` is written by `contact_sheet basis`. Do not edit it.
