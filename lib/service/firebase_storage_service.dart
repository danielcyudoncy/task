// service/firebase_storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      debugPrint('Firebase Storage: Uploading to bucket: $bucket, path: $path');
      
      // Create a reference to the file location
      final storageRef = _storage.ref().child('$bucket/$path');
      
      // Upload the file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Firebase Storage: Upload successful, URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stack) {
      debugPrint('Firebase Storage upload error: $e');
      debugPrint('Stacktrace: $stack');
      return null;
    }
  }

  /// Get the public URL for a file (Firebase Storage URLs are public by default)
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _storage.ref().child('$bucket/$path').getDownloadURL().toString();
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      debugPrint('Firebase Storage: Deleting file from bucket: $bucket, path: $path');
      await _storage.ref().child('$bucket/$path').delete();
      debugPrint('Firebase Storage: File deleted successfully');
    } catch (e) {
      debugPrint('Firebase Storage delete error: $e');
    }
  }

  /// Upload profile picture with optimized settings
  Future<String?> uploadProfilePicture({
    required File imageFile,
    required String userId,
  }) async {
    try {
      debugPrint('Firebase Storage: Uploading profile picture for user: $userId');
      
      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_pictures/${userId}_$timestamp.jpg';
      
      // Upload to Firebase Storage
      final downloadUrl = await uploadFile(
        bucket: 'user-profiles',
        path: fileName,
        file: imageFile,
      );
      
      if (downloadUrl != null) {
        debugPrint('Firebase Storage: Profile picture uploaded successfully');
        return downloadUrl;
      } else {
        debugPrint('Firebase Storage: Profile picture upload failed');
        return null;
      }
    } catch (e) {
      debugPrint('Firebase Storage: Profile picture upload error: $e');
      return null;
    }
  }

  /// Upload profile picture from bytes (for web platform)
  Future<String?> uploadProfilePictureFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    try {
      debugPrint('Firebase Storage: Uploading profile picture from bytes for user: $userId');
      
      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = 'profile_pictures/${userId}_$timestamp.jpg';
      
      // Create a reference to the file location
      final storageRef = _storage.ref().child('user-profiles/$storageFileName');
      
      // Upload the bytes
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_at': DateTime.now().toIso8601String(),
            'original_filename': fileName,
          },
        ),
      );

      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Firebase Storage: Profile picture uploaded successfully from bytes');
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage: Profile picture upload from bytes error: $e');
      return null;
    }
  }

  /// Delete old profile picture
  Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('firebase')) {
        debugPrint('Firebase Storage: Skipping delete - not a Firebase URL');
        return;
      }

      // Extract the path from the Firebase Storage URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the storage path after the project ID
      final storageIndex = pathSegments.indexOf('o');
      if (storageIndex != -1 && storageIndex + 1 < pathSegments.length) {
        final filePath = pathSegments[storageIndex + 1];
        final decodedPath = Uri.decodeComponent(filePath);
        
        debugPrint('Firebase Storage: Deleting old profile picture: $decodedPath');
        await deleteFile(
          bucket: 'user-profiles',
          path: decodedPath,
        );
      }
    } catch (e) {
      debugPrint('Firebase Storage: Error deleting old profile picture: $e');
    }
  }
} 