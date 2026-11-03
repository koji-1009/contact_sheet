import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/pages/post_page.dart';
import 'package:tabs_app/services.dart';

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = Services.feed.latest();
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: ListView(
        children: [
          for (final post in posts)
            ListTile(
              key: ValueKey('post-${post.id}'),
              leading: CircleAvatar(child: Text(post.author[0])),
              title: Text(post.author),
              subtitle: Text(post.text),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => PostPage(post: post)),
              ),
            ),
        ],
      ),
    );
  }
}
