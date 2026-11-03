import 'package:material_ui/material_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          SwitchListTile(value: true, onChanged: null, title: Text('Sync')),
          ListTile(title: Text('Version'), trailing: Text('1.0.0')),
        ],
      ),
    );
  }
}
