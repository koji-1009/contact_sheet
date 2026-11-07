import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The link was sent: back to signing in.
class ResetSentPage extends StatelessWidget {
  const ResetSentPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Check your email')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 72),
          const SizedBox(height: 16),
          const Text(
            'We sent you a link. Open it to choose a new password.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    ),
  );
}
