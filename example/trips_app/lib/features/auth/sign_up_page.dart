import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';

/// Creating an account; then where the user was sent from, or Explore.
class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const TextField(decoration: InputDecoration(labelText: 'Name')),
          const TextField(decoration: InputDecoration(labelText: 'Email')),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(authRepositoryProvider)
                  .signUp('new@example.com', 'New traveler');
              if (context.mounted) context.go(from ?? '/explore');
            },
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}
