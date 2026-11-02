import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/main.dart';
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

Widget _inApp(Widget page) => MaterialApp(
  theme: tabsTheme,
  debugShowCheckedModeBanner: false,
  home: page,
);

Widget guest(Widget page) {
  fakeServices();
  return _inApp(page);
}

Widget signedIn(Widget page) {
  fakeServices(user: 'koji');
  return _inApp(page);
}
