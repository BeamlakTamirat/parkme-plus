import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../../config/appwrite_config.dart';

/// Storage service for handling file uploads to Appwrite
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  // Storage bucket IDs
  static const String parkingImagesBucketId = 'parking-images';
  static const String profileImagesBucketId = 'profile-images';

  /// Upload parking location image
  /// Returns the file ID if successful, null if failed
  Future<String?> uploadParkingImage({
    required String locationId,
    required dynamic file, // File (mobile) or Uint8List (web)
    required String fileName,
  }) async {
    try {
      final fileId = '${locationId}_${DateTime.now().millisecondsSinceEpoch}';

      if (kDebugMode) {
        print('📤 Uploading parking image...');
        print('   Location ID: $locationId');
        print('   File name: $fileName');
        print('   File ID: $fileId');
      }

      late InputFile inputFile;

      // Handle different file types for mobile vs web
      if (kIsWeb && file is Uint8List) {
        inputFile = InputFile.fromBytes(
          bytes: file,
          filename: fileName,
        );
      } else if (!kIsWeb && file is File) {
        inputFile = InputFile.fromPath(
          path: file.path,
          filename: fileName,
        );
      } else {
        throw Exception('Unsupported file type for platform');
      }

      final result = await AppwriteConfig.storage.createFile(
        bucketId: parkingImagesBucketId,
        fileId: fileId,
        file: inputFile,
      );

      if (kDebugMode) {
        print('✅ Image uploaded successfully');
        print('   File ID: ${result.$id}');
        print('   Size: ${result.sizeOriginal} bytes');
      }

      return result.$id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to upload parking image: $e');
      }
      return null;
    }
  }

  /// Get public URL for uploaded image
  String getImageUrl(String fileId, {String? bucketId}) {
    bucketId ??= parkingImagesBucketId;

    final url =
        '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/view?project=${AppwriteConfig.projectId}';

    if (kDebugMode) {
      print('🔗 Generated image URL: $url');
    }

    return url;
  }

  /// Get image download URL with optional transformations
  String getImageDownloadUrl(
    String fileId, {
    String? bucketId,
    int? width,
    int? height,
    String? quality,
  }) {
    bucketId ??= parkingImagesBucketId;

    String url =
        '${AppwriteConfig.endpoint}/storage/buckets/$bucketId/files/$fileId/download?project=${AppwriteConfig.projectId}';

    // Add transformations
    if (width != null) url += '&width=$width';
    if (height != null) url += '&height=$height';
    if (quality != null) url += '&quality=$quality';

    return url;
  }

  /// Delete image file
  Future<bool> deleteImage(String fileId, {String? bucketId}) async {
    try {
      bucketId ??= parkingImagesBucketId;

      if (kDebugMode) {
        print('🗑️ Deleting image: $fileId');
      }

      await AppwriteConfig.storage.deleteFile(
        bucketId: bucketId,
        fileId: fileId,
      );

      if (kDebugMode) {
        print('✅ Image deleted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete image: $e');
      }
      return false;
    }
  }

  /// Upload multiple parking images
  Future<List<String>> uploadMultipleParkingImages({
    required String locationId,
    required List<dynamic> files,
    required List<String> fileNames,
  }) async {
    final List<String> uploadedFileIds = [];

    for (int i = 0; i < files.length && i < fileNames.length; i++) {
      final fileId = await uploadParkingImage(
        locationId: locationId,
        file: files[i],
        fileName: fileNames[i],
      );

      if (fileId != null) {
        uploadedFileIds.add(fileId);
      }
    }

    if (kDebugMode) {
      print('📸 Uploaded ${uploadedFileIds.length}/${files.length} images');
    }

    return uploadedFileIds;
  }

  /// Get preview URL with smaller size for thumbnails
  String getPreviewUrl(String fileId, {String? bucketId}) {
    return getImageDownloadUrl(
      fileId,
      bucketId: bucketId,
      width: 400,
      height: 300,
      quality: '80',
    );
  }

  /// Get full-size image URL
  String getFullSizeUrl(String fileId, {String? bucketId}) {
    return getImageUrl(fileId, bucketId: bucketId);
  }

  /// Validate image file
  static bool isValidImageFile(String fileName) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return validExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  /// Get file size limit (5MB)
  static int get maxFileSizeBytes => 5 * 1024 * 1024; // 5MB
}
