import 'package:material_ui/material_ui.dart';

/// The app's version, and the licenses of what it is built with (Flutter's
/// own page).
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About')),
    body: ListView(
      children: [
        const ListTile(title: Text('Trips'), subtitle: Text('Version 2.4.0')),
        ListTile(
          title: const Text('Licenses'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Trips',
            applicationVersion: '2.4.0',
          ),
        ),
      ],
    ),
  );
}
