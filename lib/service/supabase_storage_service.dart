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
      print('Uploading to bucket: $bucket, path: $path');
      final response = await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      print('Upload response: $response');
      return response;
    } catch (e, stack) {
      print('Supabase upload error: $e');
      print('Stacktrace: $stack');
      return null;
    }
  }

  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      print('Supabase delete error: $e');
    }
  }
}
