import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/pages/post_page.dart';
import 'package:tabs_app/services.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.text.isEmpty
        ? const <Post>[]
        : Services.feed.search(_query.text);
    return Scaffold(
      appBar: AppBar(title: const Text('検索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '投稿を検索',
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final post in results)
                  ListTile(
                    title: Text(post.author),
                    subtitle: Text(post.text),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PostPage(post: post),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
