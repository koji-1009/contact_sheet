import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The filters of a search, over the whole screen: applied or not, back to
/// the results.
class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  RangeValues _price = const RangeValues(5000, 40000);
  bool _breakfast = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Close',
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      title: const Text('Filters'),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _price = const RangeValues(5000, 40000);
            _breakfast = false;
          }),
          child: const Text('Reset'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Price a night'),
        RangeSlider(
          values: _price,
          min: 0,
          max: 50000,
          onChanged: (v) => setState(() => _price = v),
        ),
        SwitchListTile(
          title: const Text('Breakfast included'),
          value: _breakfast,
          onChanged: (v) => setState(() => _breakfast = v),
        ),
      ],
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: () => context.pop(),
        child: const Text('Show stays'),
      ),
    ),
  );
}
