import 'package:material_ui/material_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: const [
          SwitchListTile(value: true, onChanged: null, title: Text('同期する')),
          ListTile(title: Text('バージョン'), trailing: Text('1.0.0')),
        ],
      ),
    );
  }
}
