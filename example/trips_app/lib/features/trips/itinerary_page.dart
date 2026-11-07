import 'package:material_ui/material_ui.dart';

/// A trip's days, one under the other.
class ItineraryPage extends StatelessWidget {
  const ItineraryPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Itinerary')),
    body: ListView(
      children: const [
        ListTile(title: Text('Dec 20'), subtitle: Text('Check in from 3 pm')),
        ListTile(title: Text('Dec 21'), subtitle: Text('Breakfast 7–10 am')),
        ListTile(title: Text('Dec 22'), subtitle: Text('Check out by 11 am')),
      ],
    ),
  );
}
