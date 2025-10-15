// views/wallpaper_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wallpaper_controller.dart';

class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  final List<String> _defaultWallpapers = [
    'assets/images/wallpapers/wallpaper_1.jpg',
    'assets/images/wallpapers/wallpaper_2.jpg',
    'assets/images/wallpapers/wallpaper_3.jpg',
    'assets/images/wallpapers/wallpaper_4.jpg',
    'assets/images/wallpapers/wallpaper_5.jpg',
    'assets/images/wallpapers/wallpaper_6.jpg',
    'assets/images/wallpapers/wallpaper_7.jpg',
    'assets/images/wallpapers/wallpaper_8.jpg',
    'assets/images/wallpapers/wallpaper_9.jpg',
    'assets/images/wallpapers/wallpaper_10.jpg',
  ];

  final List<Color> _solidColors = [
    const Color(0xFFE5DDD5), // Default WhatsApp-like color
    Colors.black,
    const Color(0xFF075E54), // Dark Teal
    const Color(0xFF128C7E), // Teal Green
    Colors.deepPurple,
    Colors.red.shade900,
  ];

  late final WallpaperController _wallpaperController;

  @override
  void initState() {
    super.initState();
    _wallpaperController = Get.put(WallpaperController());
  }

  Future<void> _updateWallpaper(String backgroundValue) async {
    await _wallpaperController.setWallpaper(backgroundValue);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallpaper updated!')),
    );
    Navigator.of(context).pop();
  }

  // NOTE: Picking from gallery and uploading is a more advanced feature
  // involving Firebase Storage. For now, we'll keep it simple.
  // We can add the upload logic in a future step if you wish.
  Future<void> _pickFromGallery() async {
    // This is a placeholder for a more complex flow.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery feature coming soon!')),
    );
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   // 1. Upload image to Firebase Storage
    //   // 2. Get the download URL
    //   // 3. Call _updateWallpaper(downloadUrl)
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Wallpaper')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Move action buttons to the top ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Photos', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _pickFromGallery,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    await _wallpaperController.setWallpaper('');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wallpaper removed!')),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Solid Colors', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2 / 3,
              ),
              itemCount: _solidColors.length,
              itemBuilder: (context, index) {
                final color = _solidColors[index];
                // Convert color to a hex string for storage
                final argb = color.toARGB32();
                final rgb = (argb & 0x00FFFFFF);
                final hexString =
                    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
                return GestureDetector(
                  onTap: () => _updateWallpaper(hexString),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Default Wallpapers',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2 / 3,
              ),
              itemCount: _defaultWallpapers.length,
              itemBuilder: (context, index) {
                final assetPath = _defaultWallpapers[index];
                return GestureDetector(
                  onTap: () => _updateWallpaper('asset:$assetPath'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(assetPath, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
