import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Searching: a query, and the recent ones.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();

  static const _recent = ['Kyoto', 'Hot springs', 'Kobe'];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search(String query) => context.go(
    Uri(
      path: '/explore/search/results',
      queryParameters: {'q': query},
    ).toString(),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: TextField(
        controller: _query,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Where to?'),
        onSubmitted: _search,
      ),
      actions: [
        TextButton(
          onPressed: () => _search(_query.text),
          child: const Text('Search'),
        ),
      ],
    ),
    body: ListView(
      children: [
        const ListTile(title: Text('Recent searches')),
        for (final q in _recent)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(q),
            onTap: () => _search(q),
          ),
      ],
    ),
  );
}
