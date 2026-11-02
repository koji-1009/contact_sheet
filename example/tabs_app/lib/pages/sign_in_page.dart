import 'package:material_ui/material_ui.dart';

import 'package:tabs_app/services.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'ユーザー名')),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('submit'),
              onPressed: () {
                Services.session.signIn('koji');
                Navigator.pop(context);
              },
              child: const Text('ログインする'),
            ),
          ],
        ),
      ),
    );
  }
}
