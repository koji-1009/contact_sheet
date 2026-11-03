import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/main.dart';
import 'package:tabs_app/pages/home_shell.dart';
import 'package:tabs_app/services.dart';

// The team's preview wrappers: fakes in the service locator, as main.dart
// puts the real services, and the page in the app's theme.

const previewPosts = [
  Post(id: 'p1', author: 'Aoi', text: '新しいカフェに行ってきた'),
  Post(id: 'p2', author: 'Ren', text: 'Flutter のプレビューで画面を一覧にした'),
  Post(id: 'p3', author: 'Mio', text: '週末は山へ'),
];

class _FakeFeed implements FeedApi {
  @override
  List<Post> latest() => previewPosts;

  @override
  List<Post> search(String query) =>
      previewPosts.where((p) => p.text.contains(query)).toList();
}

class _FakeSession implements Session {
  _FakeSession(this.user);

  @override
  String? user;

  @override
  void signIn(String user) => this.user = user;

  @override
  void signOut() => user = null;
}

/// Fakes in the locator for a guest, or for [user] signed in.
void fakeServices({String? user}) {
  Services.feed = _FakeFeed();
  Services.session = _FakeSession(user);
}

/// [page] in the app: alone, or, [over] the tabs, as the app pushes it (its
/// back button shown).
Widget _inApp(Widget page, {bool over = false}) => MaterialApp(
  theme: tabsTheme,
  debugShowCheckedModeBanner: false,
  onGenerateInitialRoutes: (_) => [
    if (over) MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    MaterialPageRoute<void>(builder: (_) => page),
  ],
  // The app names no routes: without one, there is no navigator.
  onGenerateRoute: (_) => null,
);

Widget guest(Widget page) {
  fakeServices();
  return _inApp(page);
}

Widget signedIn(Widget page) {
  fakeServices(user: 'koji');
  return _inApp(page);
}

/// A page the tabs open, over them, for a guest.
Widget guestOverTabs(Widget page) {
  fakeServices();
  return _inApp(page, over: true);
}
