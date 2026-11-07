import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The code to show at the front desk, over the whole screen.
class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Close',
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      title: const Text('Voucher'),
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2, size: 220),
          Text('Booking $tripId'.toUpperCase()),
        ],
      ),
    ),
  );
}
