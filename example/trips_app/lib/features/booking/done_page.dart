import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Booked: to the trip, or back to exploring.
class DonePage extends StatelessWidget {
  const DonePage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Icon(Icons.check_circle_outline, size: 96),
            const SizedBox(height: 16),
            Text(
              'You are booked',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go('/trips/$tripId'),
              child: const Text('View trip'),
            ),
            TextButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Keep exploring'),
            ),
          ],
        ),
      ),
    ),
  );
}
