// service/version_control_service.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/service/firebase_storage_service.dart';
import 'dart:io';
import 'dart:typed_data';

class VersionControlService extends GetxService {
  static VersionControlService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService.to;
  bool _isInitialized = false;

  /// Initializes the version control service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Get.log('VersionControlService: Initializing...');
      _isInitialized = true;
      Get.log('VersionControlService: Initialized successfully');
    } catch (e) {
      Get.log('VersionControlService: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Creates a new version of a file
  Future<FileVersion> createVersion({
    required String taskId,
    required String fileName,
    required File file,
    required String userId,
    String? comment,
    String? previousVersionId,
  }) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      Get.log('Creating new version for file: $fileName in task: $taskId');

      // Generate version ID
      final versionId = _generateVersionId();
      final timestamp = DateTime.now();

      // Upload file to storage with version path
      final storagePath =
          'tasks/$taskId/attachments/versions/$versionId/$fileName';
      final downloadUrl = await _storageService.uploadFile(
        bucket: 'task-versions',
        path: storagePath,
        file: file,
      );

      // Get file metadata
      final fileStats = await file.stat();
      final fileSize = fileStats.size;

      // Determine version number
      int versionNumber = 1;
      if (previousVersionId != null) {
        final previousVersion = await getVersion(previousVersionId);
        if (previousVersion != null) {
          versionNumber = previousVersion.versionNumber + 1;
        }
      }

      // Create version document
      final version = FileVersion(
        versionId: versionId,
        taskId: taskId,
        fileName: fileName,
        downloadUrl: downloadUrl ?? '',
        storagePath: storagePath,
        versionNumber: versionNumber,
        fileSize: fileSize,
        mimeType: _getMimeType(fileName),
        createdBy: userId,
        createdAt: timestamp,
        comment: comment,
        previousVersionId: previousVersionId,
        isLatest: true,
      );

      // Save to Firestore
      await _firestore
          .collection('file_versions')
          .doc(versionId)
          .set(version.toMap());

      // Update previous version to not be latest
      if (previousVersionId != null) {
        await _firestore
            .collection('file_versions')
            .doc(previousVersionId)
            .update({'isLatest': false});
      }

      Get.log(
          'Successfully created version $versionNumber for file: $fileName');
      return version;
    } catch (e) {
      Get.log('Failed to create version for file $fileName: $e');
      rethrow;
    }
  }

  /// Creates a new version from bytes
  Future<FileVersion> createVersionFromBytes({
    required String taskId,
    required String fileName,
    required Uint8List bytes,
    required String userId,
    String? comment,
    String? previousVersionId,
  }) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      Get.log(
          'Creating new version from bytes for file: $fileName in task: $taskId');

      // Generate version ID
      final versionId = _generateVersionId();
      final timestamp = DateTime.now();

      // Upload bytes to storage with version path
      final storagePath =
          'tasks/$taskId/attachments/versions/$versionId/$fileName';

      // Create a temporary file for upload
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/temp_version_${DateTime.now().millisecondsSinceEpoch}');
      await tempFile.writeAsBytes(bytes);

      final downloadUrl = await _storageService.uploadFile(
        bucket: 'task-versions',
        path: storagePath,
        file: tempFile,
      );

      // Clean up temp file
      await tempFile.delete();

      // Determine version number
      int versionNumber = 1;
      if (previousVersionId != null) {
        final previousVersion = await getVersion(previousVersionId);
        if (previousVersion != null) {
          versionNumber = previousVersion.versionNumber + 1;
        }
      }

      // Create version document
      final version = FileVersion(
        versionId: versionId,
        taskId: taskId,
        fileName: fileName,
        downloadUrl: downloadUrl ?? '',
        storagePath: storagePath,
        versionNumber: versionNumber,
        fileSize: bytes.length,
        mimeType: _getMimeType(fileName),
        createdBy: userId,
        createdAt: timestamp,
        comment: comment,
        previousVersionId: previousVersionId,
        isLatest: true,
      );

      // Save to Firestore
      await _firestore
          .collection('file_versions')
          .doc(versionId)
          .set(version.toMap());

      // Update previous version to not be latest
      if (previousVersionId != null) {
        await _firestore
            .collection('file_versions')
            .doc(previousVersionId)
            .update({'isLatest': false});
      }

      Get.log(
          'Successfully created version $versionNumber for file: $fileName');
      return version;
    } catch (e) {
      Get.log('Failed to create version from bytes for file $fileName: $e');
      rethrow;
    }
  }

  /// Gets a specific version by ID
  Future<FileVersion?> getVersion(String versionId) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      final doc =
          await _firestore.collection('file_versions').doc(versionId).get();

      if (doc.exists && doc.data() != null) {
        return FileVersion.fromMap(doc.data()!);
      }

      return null;
    } catch (e) {
      Get.log('Failed to get version $versionId: $e');
      return null;
    }
  }

  /// Gets all versions for a specific file in a task
  Future<List<FileVersion>> getFileVersions({
    required String taskId,
    required String fileName,
  }) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      final querySnapshot = await _firestore
          .collection('file_versions')
          .where('taskId', isEqualTo: taskId)
          .where('fileName', isEqualTo: fileName)
          .orderBy('versionNumber', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FileVersion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Get.log('Failed to get file versions for $fileName in task $taskId: $e');
      return [];
    }
  }

  /// Gets the latest version of a file
  Future<FileVersion?> getLatestVersion({
    required String taskId,
    required String fileName,
  }) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      final querySnapshot = await _firestore
          .collection('file_versions')
          .where('taskId', isEqualTo: taskId)
          .where('fileName', isEqualTo: fileName)
          .where('isLatest', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return FileVersion.fromMap(querySnapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      Get.log('Failed to get latest version for $fileName in task $taskId: $e');
      return null;
    }
  }

  /// Gets all versions for a task
  Future<List<FileVersion>> getTaskVersions(String taskId) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      final querySnapshot = await _firestore
          .collection('file_versions')
          .where('taskId', isEqualTo: taskId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FileVersion.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Get.log('Failed to get task versions for task $taskId: $e');
      return [];
    }
  }

  /// Restores a specific version as the latest
  Future<FileVersion> restoreVersion({
    required String versionId,
    required String userId,
    String? comment,
  }) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      Get.log('Restoring version: $versionId');

      // Get the version to restore
      final versionToRestore = await getVersion(versionId);
      if (versionToRestore == null) {
        throw Exception('Version not found: $versionId');
      }

      // Get current latest version
      final currentLatest = await getLatestVersion(
        taskId: versionToRestore.taskId,
        fileName: versionToRestore.fileName,
      );

      // Create new version based on the restored version
      final newVersionId = _generateVersionId();
      final timestamp = DateTime.now();

      int newVersionNumber = 1;
      if (currentLatest != null) {
        newVersionNumber = currentLatest.versionNumber + 1;
      }

      final restoredVersion = FileVersion(
        versionId: newVersionId,
        taskId: versionToRestore.taskId,
        fileName: versionToRestore.fileName,
        downloadUrl: versionToRestore.downloadUrl,
        storagePath: versionToRestore.storagePath,
        versionNumber: newVersionNumber,
        fileSize: versionToRestore.fileSize,
        mimeType: versionToRestore.mimeType,
        createdBy: userId,
        createdAt: timestamp,
        comment: comment ??
            'Restored from version ${versionToRestore.versionNumber}',
        previousVersionId: currentLatest?.versionId,
        isLatest: true,
        restoredFromVersionId: versionId,
      );

      // Save new version
      await _firestore
          .collection('file_versions')
          .doc(newVersionId)
          .set(restoredVersion.toMap());

      // Update previous latest version
      if (currentLatest != null) {
        await _firestore
            .collection('file_versions')
            .doc(currentLatest.versionId)
            .update({'isLatest': false});
      }

      Get.log(
          'Successfully restored version $versionId as version $newVersionNumber');
      return restoredVersion;
    } catch (e) {
      Get.log('Failed to restore version $versionId: $e');
      rethrow;
    }
  }

  /// Deletes a specific version
  Future<void> deleteVersion(String versionId) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      Get.log('Deleting version: $versionId');

      // Get version info
      final version = await getVersion(versionId);
      if (version == null) {
        throw Exception('Version not found: $versionId');
      }

      // Don't allow deletion of latest version if it's the only version
      if (version.isLatest) {
        final allVersions = await getFileVersions(
          taskId: version.taskId,
          fileName: version.fileName,
        );

        if (allVersions.length == 1) {
          throw Exception('Cannot delete the only version of a file');
        }

        // If deleting latest version, promote previous version
        final previousVersions =
            allVersions.where((v) => v.versionId != versionId).toList();

        if (previousVersions.isNotEmpty) {
          final newLatest = previousVersions.first;
          await _firestore
              .collection('file_versions')
              .doc(newLatest.versionId)
              .update({'isLatest': true});
        }
      }

      // Delete from storage
      await _storageService.deleteFile(
        bucket: 'task-versions',
        path: version.storagePath,
      );

      // Delete from Firestore
      await _firestore.collection('file_versions').doc(versionId).delete();

      Get.log('Successfully deleted version: $versionId');
    } catch (e) {
      Get.log('Failed to delete version $versionId: $e');
      rethrow;
    }
  }

  /// Deletes all versions for a file
  Future<void> deleteAllFileVersions({
    required String taskId,
    required String fileName,
  }) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      Get.log('Deleting all versions for file: $fileName in task: $taskId');

      final versions = await getFileVersions(
        taskId: taskId,
        fileName: fileName,
      );

      for (final version in versions) {
        try {
          // Delete from storage
          await _storageService.deleteFile(
            bucket: 'task-versions',
            path: version.storagePath,
          );

          // Delete from Firestore
          await _firestore
              .collection('file_versions')
              .doc(version.versionId)
              .delete();
        } catch (e) {
          Get.log('Failed to delete version ${version.versionId}: $e');
        }
      }

      Get.log('Successfully deleted all versions for file: $fileName');
    } catch (e) {
      Get.log('Failed to delete all versions for file $fileName: $e');
      rethrow;
    }
  }

  /// Gets version history with differences
  Future<List<VersionHistoryEntry>> getVersionHistory({
    required String taskId,
    required String fileName,
  }) async {
    if (!_isInitialized) {
      throw Exception('VersionControlService not initialized');
    }

    try {
      final versions = await getFileVersions(
        taskId: taskId,
        fileName: fileName,
      );

      final history = <VersionHistoryEntry>[];

      for (int i = 0; i < versions.length; i++) {
        final version = versions[i];
        final previousVersion =
            i < versions.length - 1 ? versions[i + 1] : null;

        final entry = VersionHistoryEntry(
          version: version,
          previousVersion: previousVersion,
          sizeDifference: previousVersion != null
              ? version.fileSize - previousVersion.fileSize
              : 0,
          timeDifference: previousVersion != null
              ? version.createdAt.difference(previousVersion.createdAt)
              : Duration.zero,
        );

        history.add(entry);
      }

      return history;
    } catch (e) {
      Get.log('Failed to get version history for $fileName: $e');
      return [];
    }
  }

  /// Generates a unique version ID
  String _generateVersionId() {
    return 'ver_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().microsecond / 1000000))).round()}';
  }

  /// Gets MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Represents a file version
class FileVersion {
  final String versionId;
  final String taskId;
  final String fileName;
  final String downloadUrl;
  final String storagePath;
  final int versionNumber;
  final int fileSize;
  final String mimeType;
  final String createdBy;
  final DateTime createdAt;
  final String? comment;
  final String? previousVersionId;
  final bool isLatest;
  final String? restoredFromVersionId;

  FileVersion({
    required this.versionId,
    required this.taskId,
    required this.fileName,
    required this.downloadUrl,
    required this.storagePath,
    required this.versionNumber,
    required this.fileSize,
    required this.mimeType,
    required this.createdBy,
    required this.createdAt,
    this.comment,
    this.previousVersionId,
    required this.isLatest,
    this.restoredFromVersionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'versionId': versionId,
      'taskId': taskId,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'versionNumber': versionNumber,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'comment': comment,
      'previousVersionId': previousVersionId,
      'isLatest': isLatest,
      'restoredFromVersionId': restoredFromVersionId,
    };
  }

  factory FileVersion.fromMap(Map<String, dynamic> map) {
    return FileVersion(
      versionId: map['versionId'] ?? '',
      taskId: map['taskId'] ?? '',
      fileName: map['fileName'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      storagePath: map['storagePath'] ?? '',
      versionNumber: map['versionNumber'] ?? 1,
      fileSize: map['fileSize'] ?? 0,
      mimeType: map['mimeType'] ?? 'application/octet-stream',
      createdBy: map['createdBy'] ?? '',
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      comment: map['comment'],
      previousVersionId: map['previousVersionId'],
      isLatest: map['isLatest'] ?? false,
      restoredFromVersionId: map['restoredFromVersionId'],
    );
  }
}

/// Represents a version history entry with comparison data
class VersionHistoryEntry {
  final FileVersion version;
  final FileVersion? previousVersion;
  final int sizeDifference;
  final Duration timeDifference;

  VersionHistoryEntry({
    required this.version,
    this.previousVersion,
    required this.sizeDifference,
    required this.timeDifference,
  });

  bool get isFirstVersion => previousVersion == null;
  bool get isSizeIncrease => sizeDifference > 0;
  bool get isSizeDecrease => sizeDifference < 0;
  bool get isSameSize => sizeDifference == 0;
}
