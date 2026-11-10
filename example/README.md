# Examples

Four Flutter apps, each with its sheet (`contact_sheet/sheet.yaml`) written as the playbook (`sheet agent`) says, one for each place the previews can come from.

| App | Navigation | State | Previews |
| --- | --- | --- | --- |
| [`shop_app`](shop_app) | go_router: a redirect for guests, a deep link, pages pushed over others | riverpod | none in the app: all in the sheet package (`shop_app/contact_sheet/`), started through the app's router |
| [`notes_app`](notes_app) | Navigator 1.0: named routes with arguments, a new note as a full-screen dialog | an `InheritedNotifier` | all the app's own, one file per page (`lib/pages/*_preview.dart`), each a `MultiPreview` of a phone and a tablet: no sheet package. Shot in three variants: iPhone, Android, tablet |
| [`tabs_app`](tabs_app) | Bottom tabs that switch in place, `Navigator.push` without route names | a global service locator | the app's for the tabs and the post; the sheet package's (`tabs_app/contact_sheet/`) for signing in, a full-screen dialog over the profile tab |
| [`trips_app`](trips_app) | go_router: tabs that keep their own histories (`StatefulShellRoute`), pages over the bar, redirects for the welcome and for guests; 37 pages | riverpod, shared_preferences, url_launcher | none in the app: all in the sheet package (`trips_app/contact_sheet/`), started through the app's router |

What each sheet shows:

- `shop_app`: conditions the app keeps across its pages (`Login`, `Cart`): the home page's states are of the login, the cart's and checkout's of the cart, and the router's redirect for a guest is an edge of its own (`if: {Login: Guest}`). A route from home to checkout as a guest goes through logging in. Under the map, `Login` chosen `Guest` leaves only what a guest sees.
- `notes_app`: `data` states (an empty list, loading), a page opened in the state its argument decides (`then: New`, `then: Existing`), saving that goes back to where the editor was opened from (a `pop` for each state), and `variants`.
- `trips_app`: a sheet written by an AI agent given only `sheet agent` and `sheet manual`. Tabs that keep their own histories (`tabs`, `retap: first`, pages with `tab:`, pages over the bar without), nested routes gone to by `go` whose back goes to their `parent`, the router's redirects for the welcome and for guests, a sign-in with a state for each place it is sent from, conditions for the welcome, signing in, the trips, the cards, the wishlist and the language, and url_launcher faked at its platform interface. With 37 pages, arrows between sections that would cross another section are jumps.
- `tabs_app`: tabs written as `replace` edges from a list of pages (`from: [search, profile]`), signing in that the profile keeps after the tabs change (`set: {Login: Signed in}`), and signing out in place (an edge from the page to itself).

To draw one, from the root of a clone of [the repository](https://github.com/koji-1009/contact_sheet):

```sh
git clone https://github.com/koji-1009/contact_sheet.git
cd contact_sheet
dart run contact_sheet export example/shop_app
```

The map is then in `example/shop_app/contact_sheet/map/`: open `index.html`.

To write the sheet of an app of your own, run `sheet agent` in its directory and follow it, or ask an AI agent to.
