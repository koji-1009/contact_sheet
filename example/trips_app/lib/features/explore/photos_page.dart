import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// A hotel's photos, over the whole screen.
class PhotosPage extends StatelessWidget {
  const PhotosPage({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Close',
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      title: const Text('1 / 12'),
    ),
    body: PageView(
      children: [
        for (var i = 0; i < 12; i++)
          const Center(
            child: Icon(Icons.image, size: 160, color: Colors.white54),
          ),
      ],
    ),
  );
}
