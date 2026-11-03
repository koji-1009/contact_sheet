import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          const Expanded(
            child: Center(child: Text('Order received: preparing to ship')),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              key: const ValueKey('home'),
              onPressed: () => context.go('/'),
              child: const Text('Back to home'),
            ),
          ),
        ],
      ),
    );
  }
}
