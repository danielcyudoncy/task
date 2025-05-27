// service/supabase_storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      final response = await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      return response;
    } catch (e) {
      print('Supabase upload error: $e');
      return null;
    }
  }

  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
