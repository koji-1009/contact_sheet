import 'package:material_ui/material_ui.dart';

import 'package:notes_app/data/notes.dart';

/// Edits the note [id], or writes a new one when it is null.
class EditPage extends StatefulWidget {
  const EditPage({super.key, this.id});

  final String? id;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.id;
    final note = id == null ? null : NotesScope.of(context).byId(id);
    _title = TextEditingController(text: note?.title);
    _body = TextEditingController(text: note?.body);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await NotesScope.of(context).save(
      Note(
        id: widget.id ?? '${DateTime.now().millisecondsSinceEpoch}',
        title: _title.text,
        body: _body.text,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? '新しいメモ' : 'メモを編集'),
        actions: [
          TextButton(
            key: const ValueKey('save'),
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              maxLines: 8,
              decoration: const InputDecoration(labelText: '本文'),
            ),
          ],
        ),
      ),
    );
  }
}
