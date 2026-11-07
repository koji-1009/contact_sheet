import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Booking, first: who is staying.
class GuestsPage extends StatelessWidget {
  const GuestsPage({super.key, required this.hotelId, required this.roomId});

  final String hotelId;
  final String roomId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Who is staying?')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        TextField(decoration: InputDecoration(labelText: 'Full name')),
        TextField(decoration: InputDecoration(labelText: 'Phone')),
        ListTile(title: Text('Guests'), trailing: Text('2 adults')),
      ],
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: () => context.push(
          Uri(
            path: '/book/payment',
            queryParameters: {'hotel': hotelId, 'room': roomId},
          ).toString(),
        ),
        child: const Text('Continue'),
      ),
    ),
  );
}
