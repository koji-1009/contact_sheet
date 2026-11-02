import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/pages/home_shell.dart';
import 'package:tabs_app/services.dart';

final tabsTheme = ThemeData(colorSchemeSeed: Colors.indigo);

void main() {
  Services.feed = _ServerFeed();
  Services.session = _Session();
  runApp(MaterialApp(theme: tabsTheme, home: const HomeShell()));
}

/// The real server, which this example does not have.
class _ServerFeed implements FeedApi {
  @override
  List<Post> latest() => const [];

  @override
  List<Post> search(String query) => const [];
}

class _Session implements Session {
  @override
  String? user;

  @override
  void signIn(String user) => this.user = user;

  @override
  void signOut() => user = null;
}
