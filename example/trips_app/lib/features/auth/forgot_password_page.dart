import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Asking for a link to reset the password: the page that says it was sent
/// takes this one's place.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset your password')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('We will send a link to your email.'),
        const TextField(decoration: InputDecoration(labelText: 'Email')),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.pushReplacement('/reset-sent'),
          child: const Text('Send link'),
        ),
      ],
    ),
  );
}
