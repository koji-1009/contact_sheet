import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help: the help center in the browser, and an email to support when the
/// device can send one.
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static final _support = Uri.parse('mailto:support@trips.example.com');
  static final _center = Uri.parse('https://trips.example.com/help');

  bool _canEmail = false;

  @override
  void initState() {
    super.initState();
    _checkEmail();
  }

  Future<void> _checkEmail() async {
    final can = await canLaunchUrl(_support);
    if (mounted) setState(() => _canEmail = can);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help')),
    body: ListView(
      children: [
        const ListTile(
          title: Text('Changing a booking'),
          subtitle: Text('Open the trip, then Cancel booking, and book again.'),
        ),
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: const Text('Open the help center'),
          onTap: () => launchUrl(_center),
        ),
        if (_canEmail)
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email support'),
            onTap: () => launchUrl(_support),
          ),
      ],
    ),
  );
}
