// views/wallpaper_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


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

  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _updateWallpaper(String backgroundValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({'chatBackground': backgroundValue});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallpaper updated!')),
      );
      Navigator.of(context).pop(); // Go back to chat screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update wallpaper: $e')),
      );
    }
  }

  // NOTE: Picking from gallery and uploading is a more advanced feature
  // involving Firebase Storage. For now, we'll keep it simple.
  // We can add the upload logic in a future step if you wish.
  Future<void> _pickFromGallery() async {
    // This is a placeholder for a more complex flow.
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
                final hexString =
                    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
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
            const SizedBox(height: 32),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('From My Photos'),
                onPressed: _pickFromGallery,
              ),
            )
          ],
        ),
      ),
    );
  }
}
