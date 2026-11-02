class Post {
  const Post({required this.id, required this.author, required this.text});

  final String id;
  final String author;
  final String text;
}

/// The posts, from a server in the app.
abstract class FeedApi {
  List<Post> latest();
  List<Post> search(String query);
}

/// Who is signed in.
abstract class Session {
  String? get user;
  void signIn(String user);
  void signOut();
}

/// The app's services, set up in main.dart and read where they are needed:
/// a service locator, as GetIt is.
abstract final class Services {
  static late FeedApi feed;
  static late Session session;
}
