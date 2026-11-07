import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:trips_app/data/models.dart';

/// A hotel in a list: its name, city, price and rating.
class HotelTile extends StatelessWidget {
  const HotelTile({super.key, required this.hotel, required this.onTap});

  final Hotel hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const CircleAvatar(child: Icon(Icons.hotel)),
    title: Text(hotel.name),
    subtitle: Text('${hotel.city} · ★ ${hotel.rating}'),
    trailing: Text('¥${hotel.price}'),
    onTap: onTap,
  );
}

/// [value] drawn by [data] once loaded, a spinner while it loads, and what
/// went wrong when it fails.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T value) data;

  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    error: (e, _) => Center(child: Text('Could not load: $e')),
    loading: () => const Center(child: CircularProgressIndicator()),
  );
}

/// What a tab shows a guest: why to sign in, and the button.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({
    super.key,
    required this.icon,
    required this.text,
    required this.onSignIn,
  });

  final IconData icon;
  final String text;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onSignIn, child: const Text('Sign in')),
        ],
      ),
    ),
  );
}
