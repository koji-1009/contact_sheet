import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/auth_repository.dart';

/// Signing in; then where the user was sent from ([from]), or Explore.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key, this.from});

  final String? from;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String get _back => widget.from ?? '/explore';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.from != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Sign in to go on.'),
            ),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text('Forgot password?'),
            ),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signIn(_email.text);
              if (context.mounted) context.go(_back);
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => context.push(
              widget.from == null
                  ? '/sign-up'
                  : Uri(
                      path: '/sign-up',
                      queryParameters: {'from': widget.from},
                    ).toString(),
            ),
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }
}
