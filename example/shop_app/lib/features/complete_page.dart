import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class CompletePage extends StatelessWidget {
  const CompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('購入完了')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 72),
            const SizedBox(height: 16),
            const Text('ご購入ありがとうございました'),
            const SizedBox(height: 24),
            OutlinedButton(
              key: const ValueKey('home'),
              onPressed: () => context.go('/'),
              child: const Text('ホームへ'),
            ),
            const SizedBox(height: 8),
            // This page is not kept under the history: back from there
            // does not come here again.
            TextButton(
              onPressed: () => context.pushReplacement('/orders'),
              child: const Text('注文履歴'),
            ),
          ],
        ),
      ),
    );
  }
}
