import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';

/// The Account tab's first page: signing in or creating an account for a
/// guest; the profile, the cards and the saved stays for the signed in,
/// who sign out here. Settings, help and about for anyone.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: ListView(
          children: [
            if (auth.isSignedIn) ...[
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(auth.userName ?? ''),
                subtitle: const Text('Edit profile'),
                onTap: () => context.go('/account/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Payment methods'),
                onTap: () => context.go('/account/payment-methods'),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Saved stays'),
                onTap: () => context.go('/account/wishlist'),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Sign in to book, and to keep your trips.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/sign-in'),
                      child: const Text('Sign in'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/sign-up'),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => context.go('/account/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
              onTap: () => context.go('/account/help'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () => context.go('/account/about'),
            ),
            if (auth.isSignedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: auth.signOut,
              ),
          ],
        ),
      ),
    );
  }
}
