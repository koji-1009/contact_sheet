# sheet manual

`sheet agent` is the playbook, step by step. This is the reference: every field of the sheet, what the map holds, and the commands.

## What Contact Sheet draws

The map of a Flutter app: each state of each page as an image, each transition between pages as an arrow, and each deep link as an arrow from outside the app.

The map is drawn from the app's **sheet**, `contact_sheet/sheet.yaml`: the app's transition structure written as data, the screen transitions that actually happen in it. An AI agent writes it from what tells how the app works, such as its code and its specifications, and the team keeps it in git with the app.

Contact Sheet draws the sheet as it is written. It does not check the sheet against the app, and it changes nothing in the app.

## Where the images come from

Each state names one `@Preview`, and its image is that preview, shot by shutter.

- The app's own previews are shot in the app.
- The previews the app does not have are written in the **sheet package**, `contact_sheet/`, and shot there. It is a plain Flutter package that imports the app and does not depend on Contact Sheet; `sheet init --package` writes its skeleton.

shutter shoots them as a library, in `flutter test`, drawn as iOS: there is nothing else to install. Before shooting, `flutter pub get` runs in each project, unless its package config is newer than its pubspec and lock file.

The text is drawn in the app's fonts. Cupertino text is drawn in SF Pro on macOS and in Roboto elsewhere, and the characters those fonts lack (CJK, emoji) in the machine's own fonts. So the images depend on the machine that exports them: export the map on one kind of machine, macOS for it to look as an iPhone does.

## The sheet

### What goes where

Each field of the sheet is there for one of four things, and each kind of information has one place:

| For | Fields | What reads it |
| --- | --- | --- |
| What Contact Sheet computes | `pages` (`id`, `states` with their `if` and `data`, `tab`, `parent`, `path`, `params`), `edges`, `entries`, `conditions`, `tabs`, each state's `preview`, the `source` fields | The route between two pages, the state an arrow arrives in, the layout, the images, the marks of what changed, the tags' links |
| What the map tells its readers | `label`, `section`, `memo`, `variants`, `locale` | Anyone |
| What developers read | `widget`, `route`, `source`, `path`, `dependencies`, `uses`, and the triggers `key:` and `type:` | Shown in the HTML only under "For developers" |
| Where each page is elsewhere | `tags` | Anyone: links to the team's other tools |

The sheet also holds lint's hints looked at and kept as they are (`checked`).

Paths in the sheet are relative to the app, with `/`.

### `pages`

| Field | | What |
| --- | --- | --- |
| `id` | required | The page's name in the sheet: what edges, entries and the map's addresses use |
| `label` | required | Its name on the map |
| `section` | | A heading pages are grouped under. Each section is an island on the map, in the order the sheet first names it |
| `states` | required | Its looks, each a `@Preview` (below). The first is the one drawn on the map |
| `tab` | | With `tabs`: the tabs the page is shown in, by their first pages (`feed`, or `[feed, search]`). Pushed from a page in one of them, it goes on that tab's history. Without it, the page covers the whole bar (settings, a full-screen dialog) |
| `parent` | | The page its route is nested under (with go_router, `/explore` for `/explore/hotels/:id`). When nothing is under the page, after a `go` or a deep link, its back goes to the parent, as the router builds the pages of the path under it; the parent shows in the state of the name the page was in, else as not said. Pushed, the page goes over the page it is pushed from, as any push |
| `path` | | The route's path as declared, its parameters included (`/products/:id`). A tag's `url` can be made of it (`{path}`) |
| `params` | | The values of the path's parameters, as the page's previews show it (`{id: p1}`): what `{path}` is filled with. A state may give its own |
| `memo` | | For the people reading the map: shown with the page |
| `tags` | | Its values of the top-level `tags` (see `tags`) |
| `widget` | | For developers: the page widget's class |
| `source` | | For developers: the page's file. When it changes, the page is marked (see "Basis and changes") |
| `route` | | For developers, with typed routes: the route class (go_router_builder's `GoRouteData` subclass). Write `path` too |
| `dependencies` | | For developers: the names of the top-level `dependencies` the page reads |

The first page is where the app starts: the map lays the pages out left to right by how far the arrows take them from it.

A state:

| Field | | What |
| --- | --- | --- |
| `name` | required | The state's name. The same name on two pages is taken as the same state (see "The back") |
| `preview` | | The `@Preview` it is (below). Left out while that preview is not written yet: the state is drawn without an image, saying so, and the export tells it (`--strict` fails). So the map can show the pages and transitions before every preview is written |
| `if` | | The values of the `conditions` this look is of, one each (`{Login: Member}`). In this state the app has those values, and an arrow that says no state arrives in it while they hold. None: any values |
| `data` | | `true` when what the page loads decides the state (empty, loading, an error), not the arrow it comes by. An arrow or a deep link that says no state may arrive in it, as in the page's first |
| `params` | | The values of the path's parameters in this state, over the page's (`{id: p2}`) |
| `tags` | | Its own values of tags, in place of the page's values of those tags (the design of the signed-in look). `[]` for none in this state. The tags it does not name are the page's |
| `uses` | | For developers: what each dependency's fake holds in it, in a few words (`{AuthRepository: guest}`) |

`preview` names a `@Preview` as shutter names it: `<file>#<declaration>@<n>.<k>`.

- `<file>`: relative to the app; `contact_sheet/...` for the sheet package's.
- `<declaration>`: `fn` for a top-level function, `Class.method`, `Class.new` for an unnamed constructor, `Class.named`.
- `@<n>`: the annotation's place among every annotation on that declaration, from 0 (`@0` may be left out). Another annotation before it (`@visibleForTesting`) counts.
- `.<k>`: which of the `Preview`s the annotation gives, from 0 (`.0` may be left out). A `MultiPreview` gives several, in the order its `transform()` returns them. This is shutter's runtime part of the shot id.

### `edges`

| Field | | What |
| --- | --- | --- |
| `from` | required | The page it happens on. A list of pages (`[feed, search]`) for the same transition from each: the bottom tabs, a button in every page's app bar. `'*'` for every page but `to`, as a session that expires anywhere (say when with `if`, not `when`): drawn once, from outside |
| `to` | required | The page it leads to. A `pop` may leave it out (not from `'*'`) to go back to whichever page is under it (`text:Save` on a form opened from several pages): it is then an edge to each page it can be put over |
| `trigger` | | What the user does: `text:` a `Text`; `label:` a semantics label; `key:` a `ValueKey<String>`; `type:` a widget class (as shutter names a target); `back`, the app bar's back or the system's; `other:<what>` for anything else (a swipe, a timer). None when the user does nothing: the router alone |
| `when` | | The states of `from` it happens in: one, or a list (`[Guest, Member]`). None: any. With a list of `from`s, a state each of them has |
| `if` | | The values of the `conditions` it happens while, whatever `from` shows: `{Login: Guest}`, or several values (`{Login: [Guest, Banned]}`). A condition not named: any of its values. Where one action leads apart by a condition (a redirect for a guest), write an edge for each, each with its `if` |
| `set` | | The values it gives the `conditions`, one each (`{Login: Member}`, `{Cart: Empty}`): what the code changes on the way. A `then` naming a state with an `if` gives that state's values too |
| `then` | | The state of `to` it arrives in: one, or one for each state of `from` it leaves (`{Guest: From home, Member: Signed in}`, its keys among `when`'s states). Without it, see "Where an arrow arrives" |
| `kind` | | What the move does to the history: `push` (the default) and `redirect` put `to` over `from`; `replace` takes `from`'s place; `go` starts the history again, with `to` alone (its back then goes to its `parent`, where it has one); `pop` takes `from` off, and is drawn dashed |
| `tab` | | For a `go` to a page shown in several tabs: the tab it opens the page in, by its first page. None: the tab shown, if it is one of them, else the first |
| `source` | | For developers: where in the code. When it changes, the page it leaves is marked |

An edge's `key` (which transition it is, in `sheet.json`) is not written: Contact Sheet derives it.

#### Where an arrow arrives

An arrow arrives in:

1. the state its `then` names;
2. else the state of `to` of the name of the state it leaves, as what the user does not change stays (a full cart stays full), if the conditions after it allow that state;
3. else, as not said: `to`'s first state, its `data` states, and its states of the conditions, those the conditions after it allow.

On the map, an arrow's end shows the state it arrives in from the state chosen on its page; where it is not said, the first of those it can arrive in. The route between two pages takes the one the conditions' values are then: the first state, or any `data` state.

#### The back

Every page put over another (by a `push` or a `redirect`) goes back to the page under it by its back, and that back is not written. The page under shows in the state of the name the page above was in (full above, full below), else in the state it was in, each if the conditions now allow it, else as not said (logged in above, the page under shows logged in).

With nothing under it, a page's back goes to its `parent`, where it has one, and otherwise nowhere.

Write a `pop` only where it says more than that back:

- an action that goes back (`text:Save`), with the state it lands in (`then`) and the values it gives (`set`);
- a back that goes elsewhere than the page under it.

Anything written with `trigger: back` takes the place of the page's back where it happens: such a pop, or a confirmation shown first (an edge from the page to itself with `then`).

A state's name means the same on every page: the same name on two pages is taken as the same state, by an arrival and by a back alike. So a generic name (Default) is given only where that holds.

#### What is a transition, and what is not

- A state changing within a page (an empty cart filled) is not a transition: a page's states are how it starts.
- An edge from a page to itself is listed, not drawn. Where a condition changes on a page without leaving it (signing out in place), such an edge says it, with `set` and `kind: replace`, for the route.
- A dialog or a bottom sheet over a page is one of three things, as the agent judges it: nothing to write (a plain confirmation); a state of that page (its preview with the dialog open, entered by an edge to itself with `then`, its buttons edges `when` that state); or a page (full-screen, a flow of its own, or opened alike from many pages). How Flutter shows it (a route on the `Navigator`) does not decide it.

The sheet does not draw, and the route does not follow:

- screens outside the app (a sign-in in the browser, a payment sheet, the share sheet, the OS settings): write the step as one edge from the button to where the app comes back, with what it gives (`set`), and one for each other outcome (cancelled);
- pops through several pages to one in between (`popUntil`); to the history's first page, write `go`;
- the browser's back, forward and reload: the route is the app's own history;
- arrows that change with the screen's size (a list and its detail side by side on a tablet): the map's are the first variant's.

#### How an edge reads

An arrow's label on the map: its trigger, its `when`, its `if`'s values, and its `kind` unless the line tells it (a push; a pop, dashed). `key:` and `type:` name what only the code names, and `go` and `replace` only how the code keeps its pages: in the HTML they are shown only to developers, and they are not in `map.svg`.

A page tapped in the HTML reads each of its transitions as a sentence: in which state and while which values, doing what (`text:` and `label:` as "tap “…”", `other:` as written, `back` as going back), it leads where, arriving in which state (as `then` says it; a state kept by its name goes unsaid), and giving which values (its `set`).

### `conditions`

What the app keeps across its pages, which a page between may not show: being logged in, what is in the cart. A page's states are how it looks; a condition is what the app knows meanwhile. It is one value for the whole app at a time, and a pop does not bring an older value back.

States name the values they are of (`if`); edges, the values they happen while (`if`) and the values they give (`set`); deep links, the values they open while (`if`). The route follows them, and an arrow that says no state arrives in the state of the values then.

What several pages show alike is a condition. What one page loads (empty, loading, an error) is a state with `data`.

| Field | | What |
| --- | --- | --- |
| `name` | required | How the sheet calls it (`Login`) |
| `values` | required | Its values. The first is what the app launches with (`[Guest, Member]`) |
| `source` | | Where the app keeps it |

### `tabs`

Tab bars whose tabs each keep their own history: go_router's `StatefulShellRoute`, a `UITabBarController` with a navigation controller in each tab. A bar that switches pages in place and keeps no history is not one: write its tabs as edges with `kind: replace`.

Switching tabs is not written as an edge: the bar does it from every page shown in its tabs, and finds each tab as it was left (at its first page, the first time).

- A page pushed from a page in a tab, and shown in that tab (its `tab`), goes on that tab's history. One not shown in it goes over the whole bar, which cannot switch until that page is gone.
- A `replace` by a page not shown in the tab goes over the bar too, the tab's page kept under it.
- A `pop` that lands on another page than the one under it takes that page's place: in the tab's history if that page was in it, whichever page it is.
- A `go` to a page in a tab opens it alone in that tab's history, the other tabs as they were. A `go` elsewhere leaves the bar.

| Field | | What |
| --- | --- | --- |
| `pages` | required | Its tabs, in order, each with `page`, the tab's first page; `trigger` (required), what switches to it, in the screen's words; and `if`, the values of the conditions it can be switched to while |
| `retap` | | `first`: tapping the tab shown again goes back to its first page. `stay` (the default): it does nothing |
| `source` | | Where the app declares it |

With a bar, `lint` cannot always tell an `if` no way through the app meets: it tells one only where the moves, with the other tabs' histories left out, cannot meet it either.

### `entries`

Deep links into a page from outside the app, from none of its pages.

| Field | | What |
| --- | --- | --- |
| `to` | required | The page it opens |
| `via` | required | The link, as the code handles it (`/products/:id`) |
| `then` | | The state of `to` it opens in, where the code decides it (`/login?from=/checkout`). None: not said |
| `if` | | The values of the `conditions` it opens `to` while, as an edge's. None: any, as a link may come at any time. A link the router takes elsewhere for a guest is another entry, to that page |
| `tab` | | For a page shown in several tabs: the tab it opens the page in |
| `source` | | For developers: where in the code |

### `tags`

Tags link a page, or one of its states, to what the team keeps about it elsewhere: its analytics, its design, its specification, its address on the web, who owns it. The sheet names each tag once, at the top level, with where its values lead; the pages, and states where theirs differ, give their values. Contact Sheet shows tags and links them; it computes nothing with them.

What is not a tag: what decides where the user can go (a condition, a state's `if`), a note for the readers (`memo`), where the code is (`source`, `widget`), how the screen looks (a state).

| Field | | What |
| --- | --- | --- |
| `name` | required | What the pages and the HTML call it (`Analytics`) |
| `url` | | Where a value leads. `{value}` in it is the page's value (`https://analytics.example.com/screens/{value}`); `{path}` is the page's `path`, its parameters filled by `params` (`https://app.example.com{path}`). A url with `{path}` and without `{value}` needs no value written: every page with a `path` has the tag, its value the path filled. None: each value is text, or a link of its own |

In a url, a value is escaped as a URL takes it: what a URL cannot hold (a space, a letter not ASCII) is escaped, and its `/`, `?` and `#` are kept, so a value may be a path. A parameter's value is escaped whole, its `/` too. A path with a parameter that has no value in `params` is shown as declared, without a link, and `lint` tells it.

A page gives, by a tag's name:

- a value (`Analytics: home_view`), which goes in the tag's `url`;
- a link of its own (`{label: Home spec, url: https://...}`), whatever the tag's `url`;
- or a list of them.

A state gives the same, for the tags whose values in it differ from its page's (`Design: home_signed_in`); `[]` for none in it. In that state, those values take the place of the page's; the other tags are the page's. Its `params` fill the path for it.

In the HTML, the tags of the state shown are shown with the memo: beside the page when it is chosen, and on the map above it. A page in the list and its details show the page's, and under each state its own. Under the map ("With"), each tag, the memo and the transitions as sentences are chosen to be shown (at first, the memo and the sentences, no tag), so that the map shows, say, its arrows and the analytics alone. Only `https:`, `http:` and `mailto:` values are links.

### `dependencies`

For developers: what pages read that their previews replace. Shown, not checked.

| Field | | What |
| --- | --- | --- |
| `name` | required | What pages and states call it |
| `target` | | What the previews override (`authRepositoryProvider`) |
| `source` | | Its file. When it changes, the pages that read it are marked |

### `variants`

The ways every state is shot, switched between in the HTML. The first is the map's: its boxes, and `map.svg`'s. None: one, as iOS.

| Field | | What |
| --- | --- | --- |
| `name` | required | What the HTML calls it (`Android`, `Tablet`) |
| `platform` | | `ios` (the default) or `android`: how shutter draws it |
| `preview` | | The name of the `Preview` each state is in this variant, among those its annotation gives (a `MultiPreview` of devices). None: the one the state names. A state whose annotation gives none of that name has no image in this variant |

Each platform the variants name is one more shot of every preview.

### `locale`

The language of the map's own words (its buttons, headings and sentences): `en` (the default) or `ja`, for the people who read it. What the sheet says (labels, triggers, states, memos) is drawn as written. `export --locale` overrides it.

### `checked`

lint's hints that were looked at and are right as they are, each by the key lint gives under it (an empty cart that nothing but the back leaves): lint and the export do not tell them again. A key that is no hint any more is told, to be taken out.

```yaml
checked:
  - "nothing-leaves cart/Empty"
```

## The map

`sheet export` writes the map to `contact_sheet/map/`; with `--out <folder>`, to `<app>_contact_sheet/` in that folder (or to that folder itself, when it is named so). Each export replaces `images/`.

| File | What |
| --- | --- |
| `index.html` | The map to open: one file, its images in `images/` next to it, opened from disk or served anywhere |
| `images/` | Each state's shot |
| `sheet.json` | What they are drawn from, for other tools and AI agents |
| `map.svg`, `map-dev.svg` | With `--svg` only: the whole map as one picture |

### `index.html`

Three views of the same pages, and what goes with them:

- **The map.** Each page with its image, each transition an arrow.
  - A page chosen brings the map to it and to the pages next to it, as large as their arrows' words read (where they are too many for that, the page chosen stays in view), and shows beside it its states, its memo, its tags and its transitions as sentences, as far as those are shown with the pages.
  - A state chosen there is shown on the map, with only the arrows that can happen in it, and the pages they arrive at in the state they arrive in; its name is under the page's. A page tapped twice shows its image large.
  - An arrow tapped, or its label, says what it is, as a sentence, beside the map, with the pages at its ends; a label's parts read apart (what is done, the states and the values it needs, a redirect).
  - It opens where the app starts: its first page with its section at the top left, as large as its words read and no larger than drawn, or whole where the whole map reads so. ⤢ shows it whole; nothing else moves it there: a page or a route let go leaves the map where it is. From far out, the sections' names lead in.
  - A page's image is loaded once the map shows it large enough to make out, or when it is chosen, next to the page chosen, or on the route.
- **The tree.** The pages top to bottom, as a site map draws an app: each page under the page from which the fewest steps from the app's start first reach it, by a transition forward or a tab of its bar. It goes by the transitions alone, whatever states and conditions they need: a site map, not a route. A page's children are in the sheet's order, and its branch has the words of what reaches it. A transition back, one from every page, or one from a page to itself is no branch: the map and a page's sentences tell those. The pages nothing from the start reaches are trees of their own, after it, said so. It scrolls, zooms and opens as the map does; a page tapped opens its details.
- **The list.** One page under the other, by section, each with its states and the pages it goes to and comes from. With it, the table of every transition (by page: in which state, doing what, it leads where).

And in every view:

- **The route between two pages**: the fewest steps from one to the other as the app's navigator goes, each as a sentence (see "The route").
- **A page's details**, and each image opening large.
- **Search**: pages by their names, memo, states, tags (their names and values) and what is done on them (a button's words find its page). The table narrows as it is typed.
- **How much the map shows**, chosen under it: the pages alone, with the arrows, or with what each arrow says (the default); and the arrows back, shown or hidden (tapping "Back" in the legend). A page chosen, or a route, shows its own arrows whatever is chosen, and beside the map says them as sentences.
- **What is shown with the pages** ("With"), on the map above each page and beside a page chosen: its transitions as sentences, its memo and each tag, each shown or not (at first, the sentences and the memo, no tag). Above a page, they are one row no wider than it, those past it one `+<n>`, clear of the arrows and labels there; where those take all the room above, on the top edge of its image.
- **Variants**, chosen in the header ("Shown as"): every image follows, and the map and the tree are laid out again, each page's box its screen at the scale the first variant's is drawn at.
- **Where it is from**: which app it was drawn from (its version and branch; its commit, for developers), when it was exported, and, with a basis, how many changes to the app's code the sheet names for no page.
- **For developers**, ticked: what only developers read (the code's names, files, fakes, `go` and `replace`).
- Light or dark as the browser is set; on a phone, one column, where it is from behind the app's name, and what the map shows behind one button under it; printed, the list or the table.
- **Addresses**, to pass a view around:
  - `#map/<page id>`, `#map/<page id>/<state>`;
  - `#route/<from>/<to>`, `#route/<from>/<state>/<to>`, each followed by `/<condition>=<value>` for each value chosen;
  - `#tree/<page id>`, `#list/<page id>`, `#page/<page id>` (its details), `#table`;
  - before them: `?variant=<name>`, with variants; `?show=pages` or `?show=flow`, for how much the map shows; and `?with=<key>`, once for each of what is shown of the arrows back (`back`), the sentences (`says`), the memo (`memo`) and the tags (`tag:<name>`), `?with=` alone for none of them; without it, the arrows back, the sentences and the memo.

### The route

The route follows the states (from a state, only what can happen in it), the conditions (`if`, `set`) and the history (`kind`, and the back of every page put over another).

It starts with the history the fewest steps from the app's launch reach the first page with, in the state and under the conditions' values chosen beside it. The launch is the first page, in its first state that the conditions' first values allow. The values default to those the launch reaches the page with; a value the state itself is of (its `if`) is that state's, whatever is chosen. The pages under the start, where its back goes, are named.

Its fewest steps are exact: a shortest path in the pushdown system the history makes, its stack the pages and its control the conditions' values, each page entered under each valuation summarised once.

In a tab bar of `tabs`, a switch finds a tab as it was left, and the other tabs' histories are named beside the route. A route found is the fewest of all: it is searched again past the three pages of a tab's history kept exactly, where a tab left deeper might have made it shorter. There, the histories can be too many to search to the end (each tab's multiplied together): the route then says the app may have a route, or a shorter one, than it shows. A page no route is found to may still be reached through a tab left deeper.

### The layout

- Each section is an island of its own. In it, the flow runs left to right from where it comes in: the first page, an arrow from another section, a deep link, in that order. The pages nothing in the section leads to are a row under the rest. The islands are laid in rows.
- Three or more arrows from other sections into one page that say the same (and all go back, dashed, or none does) are drawn as one short arrow into it, `<label> ×<n>`; those from every page always, `<label> From any page`.
- An arrow between sections that would run through where another island's pages are is a jump: a short arrow out of its page, `<label> → <page>`, and one into the page it goes to, bundled with those that say the same (`<label> ← <page>` for one alone).
- A tab's first page has its bar drawn under it, its own tab lit; the first pages of one bar's tabs stand in one column.

### The other files

- `map.svg`, with `--svg`: the whole map as one picture, the images in it, to be passed around alone. The labels are what anyone reads, and each page links to it in `index.html`. `map-dev.svg` has what developers read too. Without `--svg`, those an earlier export wrote are deleted.
- `images/`: each state's shot, drawn at a pixel ratio of 1.5 (`--pixel-ratio`: 2 is as sharp as a phone, 1 smaller), as lossless WebP: as shutter drew it, in fewer bytes than its PNG. A side longer than a WebP can be (16383 pixels) is made smaller. Each is named by its shot id, with `sheet-` before it for the sheet package's, then `android-` for an Android variant's. The SVGs hold them the same way.

A state shutter could not draw has no image: the command tells its error, and the HTML shows it (`error` in `sheet.json`). So does a state whose preview file does not exist, is not under `lib/`, or has no `@Preview`, and one whose image cannot be read. One whose preview is not written yet says so. The export goes on for the rest.

### `sheet.json`

`schemaVersion` (1) changes when what is there does.

Top level: `app`, `locale`, `generatedAt`, `conditions` (`name`, `values`, `source`), `tabs` (each `pages`, with `page`, `trigger` and `if`; `retap`, `first` or `stay`; `source`), `tags` (`name`, `url`), `variants` (`name`, `platform`, `preview`; one, unnamed, when the sheet names none), `release` (`version`, the app's pubspec's; `commit` and `branch`, where git knows them), `basis` (when there is one: `commit`, `found`, `changed`, `unmapped`: what changed in `lib/` that the sheet names for no page, nor as a preview), `canvas` (`width`, `height`, `labelHeight`), `sections` (`name` and its island's box), `pages`, `edges`, `entries`, `bundles`, `tree`.

- A page: the sheet's fields (`tab` a list, empty for none; `parent` or null; `params`, `{}` for none; `tags` a list in the tags' order, each `tag`, `label` and `url`: the value in its tag's `url`, its own, or null), its `dependencies` in full, `sheetChanged` (its files changed since the basis), and its box as the first variant lays the map out (`x`, `y`, `width`, `height`; its label is the bottom `labelHeight` of it).
- A page's `states`: `name`, `preview` (null while not written), `project` (`app` or `sheet`, the sheet package; null without a preview), `uses`, `data`, `if` (`{}` for none), `params` (its own, `{}` for none), `tags` (all of them in it: its own, else its page's, as a page's are); and as the first variant draws it, `shot` (shutter's id), `width`, `height`, `image` (relative to `sheet.json`, or null) and `error` (or null); `variants`: those five in each variant, in order.
- An edge:
  - `key`: which transition it is, the same from one export to the next while its pages, trigger, `when`, `if` and kind stay (`home>cart label:Cart push`, `cart>checkout text:Buy [Full] {Login=Member} push`; ` #2` after one written twice);
  - the sheet's fields: one edge for each page a list of `from`s names (every page for `'*'`, `anywhere` true then) and, for a pop without `to`, for each page it can be over (`under` true); `item`, its place in the sheet's `edges`; `when` a list, empty for any state; `if` a list of values by condition, `{}` for none; `set`, `{}` for none; `tab` or null; `then` as written: a state, a map by the state it leaves, or null;
  - `arrive`: the states of `to` it can arrive in, from each state of `from` its `when` names (all, without one), under any values of the conditions it can happen while. One where said or kept by its name; else `to`'s first, its `data` states and its states of the conditions, those the values allow; a pop back to the page under it, in the state that page can be in there; empty for a state no values let it happen in;
  - `label` (as a developer reads it), its three parts in order (`labelCode`: what only the code names; `labelPlain`: what anyone reads; `labelKind`: `go` or `replace`), and `labelParts` (what anyone reads, part by part: `text`, and `part`, `does`, `when` or `kind`);
  - where it is drawn: `curve` (a cubic Bézier's 4 points, flattened) and `labelAt`; or `bundle`, the bundle it is drawn in; or, for a jump (`jump` true), both: its short arrow out and the bundle it comes in by. Neither for an edge from a page to itself, which is not drawn.
- An entry: `key` (`product_detail</products/:id`, then its `if` as an edge's), the sheet's fields (`then` or null; `if`, `{}` for none; `tab` or null), `line` (2 points, flattened) and `labelAt`.
- A bundle: `to`, `edges` (their places in `edges`), `label`, `line` and `labelAt`.
- The tree: `width`, `height`, `outside` (the roots of the trees nothing from the app's start reaches) and `pages`, in the sheet's order: `page`, its box, `parent` (null for a root), `depth`, what reaches it (`edge`, its place in `edges`, or `tab`, the tab's first page; both null for a root), and for one with a parent `line` (its branch's points, flattened) and, where it has words, `label` and `labelAt`.

## Basis and changes

`sheet basis` records the app as it is now as what the sheet was written against, in `contact_sheet/basis.json`: the commit, and the files that differed from it then (changed, or not in git yet) with their content's hash. Do not edit it.

`sheet changed` lists the app's files changed since then; the sheet package's own files are not the app's changes.

The map marks a page, for developers, when one of its files changed: its `source`, its dependencies' sources, the sources of its edges out and of the deep links into it. A mark is a hint: a change does not make the sheet wrong.

## Runs

shutter writes each shot into a run, in `.dart_tool/shutter/runs/` of the project it shoots in. Once the images are in the map, the export deletes the runs it made, so the team's own runs in the app stay as they were.

The WebP made of each shot is kept in `contact_sheet/.dart_tool/contact_sheet/webp/`, named by its PNG's hash: an export encodes only the shots that changed, and an export of every page (without `--only`) deletes the rest.

`sheet prune` deletes what an interrupted export left: every run in the sheet package, and in the app only the runs an export listed (`contact_sheet/.dart_tool/contact_sheet/runs`) or left half made (a run with no manifest that was not there before the export shot).

## What goes into the app's git

| Path | In git |
| --- | --- |
| `contact_sheet/sheet.yaml`, `contact_sheet/basis.json` | yes |
| The sheet package (`contact_sheet/pubspec.yaml`, `analysis_options.yaml`, `lib/`) | yes |
| `contact_sheet/map/` | as the team chooses |
| `contact_sheet/.dart_tool/` | no (`init --package` adds it to the app's `.gitignore` unless `.dart_tool/` is ignored already) |

## Commands

| Command | What |
| --- | --- |
| `agent` | Print the playbook for AI agents |
| `manual` | Print this reference |
| `init [--package]` | Write an empty sheet; with `--package`, the sheet package's skeleton too |
| `export [--out <folder>] [--only <page id>]... [--locale <en\|ja>] [--strict] [--svg] [--pixel-ratio <ratio>]` | Shoot the previews the sheet names and write the map. `--only`: those pages' previews alone, the others keeping their images. `--locale`: the map in that language (else the sheet's `locale`, else English). `--strict`: fail while a state has no image. `--svg`: write `map.svg` and `map-dev.svg` too. `--pixel-ratio`: the images drawn at it (1.5 by default) |
| `lint` | Tell what the sheet itself shows may be missing or written twice |
| `basis` | Record the app as the sheet was written against |
| `changed [--by-page]` | List the app's files changed since the basis; with `--by-page`, by the pages the sheet names them for |
| `prune` | Delete the runs of shutter's that Contact Sheet left |

Each command but `agent` and `manual` runs on the app directory given last, the current one by default. `sheet help <command>` tells a command's options; `--version`, the version.

## Exit codes

| Code | When |
| --- | --- |
| 0 | Done |
| 64 | A wrong use: the message and the usage on stderr. `export --only`: the sheet has no such page |
| 65 | `sheet.yaml` cannot be read (said with where). `changed`: the basis's commit is not in the repository. `export --strict`: a state has no image |
| 66 | No `pubspec.yaml` in the directory; no `sheet.yaml`. `changed`: no basis yet |
| 69 | `export`: no `flutter` to run (`FLUTTER_ROOT`, else the PATH), `flutter pub get` failed, or shutter cannot run |
| 70 | An unexpected error (`--verbose` tells where it came from) |
| 78 | `basis`: not a git repository. `export`: the app or the sheet package is not set up for shutter (no `flutter_test` in `dev_dependencies`) |

## What `lint` tells

Hints, not errors: each says what to look at. `export` tells them too.

Under each hint is its key. Once a hint is looked at and the sheet is right as it is, add the key to `checked`: lint and the export stop telling it. A key in `checked` that is no hint any more is told, to be taken out.

- Pages: one no arrow leads to from the first page, and no deep link opens; the first page with no state of the conditions' first values.
- States: one none of the page's arrows leaves from; one nothing arrives in (not `data`); two of the same values of the conditions; a page with no state of some values.
- Edges: one written twice; one written again for other states (write one edge, `when` both's, `then` by the state it leaves); a `when` state of other values than the `if`; an `if` no way through the app meets there.
- Conditions: a value nothing names; a value nothing gives, not the first.
- Deep links: one written twice.
- Tags: one no page has; one that three quarters of the pages or more have, and some do not; a page's path whose parameters have no value in `params`, where a tag's url is made with `{path}`.
- Tabs: a bar of one tab; an edge between two tabs of a bar (the bar switches them); a page opened from a tab it is not shown in, or from over the bar; a go or a deep link to a page in several tabs that names none.
- Checked: a key `checked` names that is no hint now.
