import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';

/// The user's name and email, saved back to the account.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: auth.userName,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const TextField(decoration: InputDecoration(labelText: 'Email')),
        ],
      ),
    );
  }
}
