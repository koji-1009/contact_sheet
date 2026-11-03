import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/pages/sign_in_page.dart';
import 'package:tabs_app/services.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final user = Services.session.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: user == null
            ? FilledButton(
                key: const ValueKey('sign-in'),
                onPressed: () async {
                  // Signing in opens as a dialog over the tabs.
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => const SignInPage(),
                    ),
                  );
                  setState(() {});
                },
                child: const Text('Sign in'),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 32, child: Text(user[0])),
                  const SizedBox(height: 12),
                  Text(user),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => setState(() => Services.session.signOut()),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
      ),
    );
  }
}
