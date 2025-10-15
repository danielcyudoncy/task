// controllers/wallpaper_controller.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperController extends GetxController {
  static const String _wallpaperKey = 'chat_wallpaper';
  final RxString wallpaper = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadWallpaper();
  }

  Future<void> loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    wallpaper.value = prefs.getString(_wallpaperKey) ?? '';
  }

  Future<void> setWallpaper(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperKey, value);
    wallpaper.value = value;
  }
}
