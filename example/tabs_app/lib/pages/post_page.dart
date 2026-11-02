import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/services.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post.author)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(post.text, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
