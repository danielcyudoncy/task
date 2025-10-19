// service/task_attachment_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/app_lock_controller.dart';
import 'package:task/models/task.dart';
import 'package:task/service/firebase_storage_service.dart';
import 'package:path/path.dart' as path;

class TaskAttachmentService extends GetxService {
  static TaskAttachmentService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorageService _storageService =
      Get.find<FirebaseStorageService>();
  final ImagePicker _imagePicker = ImagePicker();

  /// Initialize the service
  Future<void> initialize() async {
    debugPrint('TaskAttachmentService initialized');
  }

  // Supported file types
  static const List<String> supportedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> supportedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'rtf'
  ];
  static const List<String> supportedVideoTypes = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> supportedAudioTypes = ['mp3', 'wav', 'aac', 'm4a'];

  // Maximum file size (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Pick and upload image from camera or gallery
  Future<Map<String, dynamic>?> pickAndUploadImage({
    required String taskId,
    required ImageSource source,
  }) async {
    try {
      // Suspend app lock while the native picker is active (may background the app)
      XFile? pickedFile;
      try {
        final appLock = Get.find<AppLockController>();
        pickedFile = await appLock.suspendLockWhile(
          _imagePicker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          ),
        );
      } catch (_) {
        // If AppLockController is not available or suspend fails, fallback to direct pick
        pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (pickedFile == null) return null;

      // Check file size
      final fileSize = await pickedFile.length();
      if (fileSize > maxFileSize) {
        throw Exception('File size exceeds 10MB limit');
      }

      // Extend suspension for upload operation as well
      final appLock = Get.find<AppLockController>();
      appLock.suspendLockFor(const Duration(seconds: 30));

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        return await _uploadFileFromBytes(
          taskId: taskId,
          fileName: pickedFile.name,
          bytes: bytes,
          fileType: 'image',
        );
      } else {
        final file = File(pickedFile.path);
        return await _uploadFile(
          taskId: taskId,
          file: file,
          fileName: pickedFile.name,
          fileType: 'image',
        );
      }
    } catch (e) {
      debugPrint('Error picking/uploading image: $e');
      rethrow;
    }
  }

  /// Pick and upload document files
  Future<Map<String, dynamic>?> pickAndUploadDocument({
    required String taskId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...supportedDocumentTypes,
          ...supportedVideoTypes,
          ...supportedAudioTypes
        ],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final platformFile = result.files.first;

      // Check file size
      if (platformFile.size > maxFileSize) {
        throw Exception('File size exceeds 10MB limit');
      }

      final fileExtension =
          path.extension(platformFile.name).toLowerCase().replaceAll('.', '');
      String fileType = 'document';

      if (supportedVideoTypes.contains(fileExtension)) {
        fileType = 'video';
      } else if (supportedAudioTypes.contains(fileExtension)) {
        fileType = 'audio';
      }

      // Extend suspension for upload operation as well
      final appLock = Get.find<AppLockController>();
      appLock.suspendLockFor(const Duration(seconds: 30));

      if (kIsWeb) {
        if (platformFile.bytes == null) {
          throw Exception('File bytes not available');
        }
        return await _uploadFileFromBytes(
          taskId: taskId,
          fileName: platformFile.name,
          bytes: platformFile.bytes!,
          fileType: fileType,
        );
      } else {
        if (platformFile.path == null) {
          throw Exception('File path not available');
        }
        final file = File(platformFile.path!);
        return await _uploadFile(
          taskId: taskId,
          file: file,
          fileName: platformFile.name,
          fileType: fileType,
        );
      }
    } catch (e) {
      debugPrint('Error picking/uploading document: $e');
      rethrow;
    }
  }

  /// Upload file from File object
  Future<Map<String, dynamic>> _uploadFile({
    required String taskId,
    required File file,
    required String fileName,
    required String fileType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create unique file path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = path.extension(fileName);
    final uniqueFileName =
        '${path.basenameWithoutExtension(fileName)}_$timestamp$fileExtension';
    final filePath = 'task_attachments/$taskId/$uniqueFileName';

    // Upload to Firebase Storage
    final downloadUrl = await _storageService.uploadFile(
      bucket: 'task-attachments',
      path: filePath,
      file: file,
    );

    if (downloadUrl == null) {
      throw Exception('Failed to upload file');
    }

    return {
      'url': downloadUrl,
      'name': fileName,
      'type': fileType,
      'size': await file.length(),
      'uploadedAt': DateTime.now(),
    };
  }

  /// Upload file from bytes (for web)
  Future<Map<String, dynamic>> _uploadFileFromBytes({
    required String taskId,
    required String fileName,
    required Uint8List bytes,
    required String fileType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create unique file path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = path.extension(fileName);
    final uniqueFileName =
        '${path.basenameWithoutExtension(fileName)}_$timestamp$fileExtension';
    final filePath = 'task_attachments/$taskId/$uniqueFileName';

    try {
      // Upload to Firebase Storage
      final storageRef = storage.FirebaseStorage.instance
          .ref()
          .child('task-attachments/$filePath');

      final uploadTask = storageRef.putData(
        bytes,
        storage.SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: {
            'uploaded_at': DateTime.now().toIso8601String(),
            'uploaded_by': user.uid,
            'task_id': taskId,
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'url': downloadUrl,
        'name': fileName,
        'type': fileType,
        'size': bytes.length,
        'uploadedAt': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error uploading file from bytes: $e');
      rethrow;
    }
  }

  /// Add attachment to task
  Future<void> addAttachmentToTask({
    required String taskId,
    required String url,
    required String name,
    required String type,
    required int size,
  }) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);

      await taskRef.update({
        'attachmentUrls': FieldValue.arrayUnion([url]),
        'attachmentNames': FieldValue.arrayUnion([name]),
        'attachmentTypes': FieldValue.arrayUnion([type]),
        'attachmentSizes': FieldValue.arrayUnion([size]),
        'lastAttachmentAdded': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding attachment to task: $e');
      rethrow;
    }
  }

  /// Remove attachment from task
  Future<void> removeAttachmentFromTask({
    required String taskId,
    required int attachmentIndex,
    required Task task,
  }) async {
    try {
      if (attachmentIndex < 0 ||
          attachmentIndex >= task.attachmentUrls.length) {
        throw Exception('Invalid attachment index');
      }

      // Get attachment details
      final url = task.attachmentUrls[attachmentIndex];
      final name = task.attachmentNames[attachmentIndex];
      final type = task.attachmentTypes[attachmentIndex];
      final size = task.attachmentSizes[attachmentIndex];

      // Remove from Firebase Storage
      try {
        final ref = storage.FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (e) {
        debugPrint('Warning: Could not delete file from storage: $e');
      }

      // Update task in Firestore
      final taskRef = _firestore.collection('tasks').doc(taskId);
      await taskRef.update({
        'attachmentUrls': FieldValue.arrayRemove([url]),
        'attachmentNames': FieldValue.arrayRemove([name]),
        'attachmentTypes': FieldValue.arrayRemove([type]),
        'attachmentSizes': FieldValue.arrayRemove([size]),
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error removing attachment from task: $e');
      rethrow;
    }
  }

  /// Get content type for file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file type category
  String getFileTypeCategory(String fileName) {
    final extension =
        path.extension(fileName).toLowerCase().replaceAll('.', '');

    if (supportedImageTypes.contains(extension)) {
      return 'image';
    } else if (supportedVideoTypes.contains(extension)) {
      return 'video';
    } else if (supportedAudioTypes.contains(extension)) {
      return 'audio';
    } else if (supportedDocumentTypes.contains(extension)) {
      return 'document';
    }

    return 'unknown';
  }

  /// Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get icon for file type
  IconData getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'document':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }
}
