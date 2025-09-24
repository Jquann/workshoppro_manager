import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();
  
  // Global notifier for profile image updates
  static final ValueNotifier<int> profileImageUpdateNotifier = ValueNotifier<int>(0);
  static final Map<String, Uint8List> _imageCache = {};
  
  /// Force refresh all profile images across the app
  static void forceProfileImageRefresh() {
    profileImageUpdateNotifier.value++;
    _imageCache.clear();
    print('Profile image refresh triggered: ${profileImageUpdateNotifier.value}');
  }
  
  /// Get image as Uint8List for immediate display
  static Future<Uint8List?> getImageBytes(String imagePath) async {
    try {
      if (_imageCache.containsKey(imagePath)) {
        return _imageCache[imagePath];
      }
      
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _imageCache[imagePath] = bytes;
        return bytes;
      }
      return null;
    } catch (e) {
      print('Error reading image bytes: $e');
      return null;
    }
  }
  
  /// Clear specific image from cache
  static void clearImageFromCache(String imagePath) {
    _imageCache.remove(imagePath);
    print('Cleared image from cache: $imagePath');
  }

  /// Save profile image to local storage
  /// Returns the local file path of the saved image
  static Future<String?> saveProfileImageLocally(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory profileImagesDir = Directory(path.join(appDocDir.path, 'profile_images'));
      
      // Create directory if it doesn't exist
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      // Create a unique filename for the profile image with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'profile_${user.uid}_$timestamp.jpg';
      final String localPath = path.join(profileImagesDir.path, fileName);
      
      // Delete old profile image if exists
      await _deleteOldProfileImages(user.uid, profileImagesDir);
      
      // Copy the selected image to the local directory
      final File localImageFile = await imageFile.copy(localPath);
      
      // Clear cache and trigger refresh
      clearImageFromCache(localPath);
      forceProfileImageRefresh();
      
      print('Image saved locally at: $localPath');
      return localImageFile.path;
    } catch (e) {
      print('Error saving profile image locally: $e');
      throw Exception('Failed to save image locally: ${e.toString()}');
    }
  }
  
  /// Delete old profile images for the user
  static Future<void> _deleteOldProfileImages(String userId, Directory profileImagesDir) async {
    try {
      final List<FileSystemEntity> files = await profileImagesDir.list().toList();
      for (final file in files) {
        if (file is File && file.path.contains('profile_$userId')) {
          await file.delete();
          print('Deleted old profile image: ${file.path}');
        }
      }
    } catch (e) {
      print('Error deleting old profile images: $e');
    }
  }

  /// Delete profile image from local storage
  static Future<void> deleteLocalProfileImage(String localPath) async {
    try {
      if (localPath.isEmpty) return;

      final File imageFile = File(localPath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        print('Local profile image deleted: $localPath');
      }
    } catch (e) {
      print('Error deleting local profile image: $e');
      // Don't throw here as deletion failure shouldn't block the app
    }
  }

  /// Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      print('Starting gallery image selection...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('Image selected from gallery: ${pickedFile.path}');
        final file = File(pickedFile.path);
        print('File exists: ${await file.exists()}');
        return file;
      } else {
        print('No image selected from gallery');
        return null;
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      print('Starting camera image capture...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('Image captured from camera: ${pickedFile.path}');
        final file = File(pickedFile.path);
        print('File exists: ${await file.exists()}');
        return file;
      } else {
        print('No image captured from camera');
        return null;
      }
    } catch (e) {
      print('Error picking image from camera: $e');
      throw Exception('Failed to take photo: ${e.toString()}');
    }
  }

  /// Show image source selection dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    File? selectedFile;
    
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Image Source',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose how you want to add your profile picture:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        selectedFile = await pickImageFromGallery();
                      } catch (e) {
                        print('Error picking from gallery: $e');
                      }
                    },
                  ),
                  _buildSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.of(context).pop();
                      try {
                        selectedFile = await pickImageFromCamera();
                      } catch (e) {
                        print('Error picking from camera: $e');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
    
    return selectedFile;
  }

  static Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5EA)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF007AFF),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Save profile image locally with optional progress callback
  static Future<String?> saveProfileImageLocallyWithProgress(
    File imageFile,
    Function(double progress)? onProgress,
  ) async {
    try {
      // For local storage, we don't need complex progress tracking
      // Just call the main save method
      if (onProgress != null) {
        onProgress(0.5); // Simulate progress
      }
      
      final String? localPath = await saveProfileImageLocally(imageFile);
      
      if (onProgress != null) {
        onProgress(1.0); // Complete
      }
      
      return localPath;
    } catch (e) {
      print('Error saving profile image locally: $e');
      throw Exception('Failed to save image locally: ${e.toString()}');
    }
  }

  /// Get the current user's profile image path from their user data
  static String? getCurrentUserProfileImagePath(Map<String, dynamic>? userData) {
    return userData?['profileImagePath'] as String?;
  }

  /// Check if a local profile image exists for the current user
  static Future<bool> hasLocalProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory profileImagesDir = Directory(path.join(appDocDir.path, 'profile_images'));
      
      if (!await profileImagesDir.exists()) {
        return false;
      }

      // Check if any profile image file exists for this user
      final List<FileSystemEntity> files = await profileImagesDir.list().toList();
      for (final entity in files) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.startsWith('profile_${user.uid}_')) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking local profile image: $e');
      return false;
    }
  }

  /// Get the local profile image path for the current user
  static Future<String?> getLocalProfileImagePath() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory profileImagesDir = Directory(path.join(appDocDir.path, 'profile_images'));
      
      if (!await profileImagesDir.exists()) {
        return null;
      }

      // Find the most recent profile image for this user
      final List<FileSystemEntity> files = await profileImagesDir.list().toList();
      String? latestImagePath;
      int latestTimestamp = 0;

      for (final entity in files) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.startsWith('profile_${user.uid}_')) {
            // Extract timestamp from filename
            final timestampStr = fileName.substring('profile_${user.uid}_'.length).replaceAll('.jpg', '');
            try {
              final timestamp = int.parse(timestampStr);
              if (timestamp > latestTimestamp) {
                latestTimestamp = timestamp;
                latestImagePath = entity.path;
              }
            } catch (e) {
              // Ignore files with invalid timestamp format
            }
          }
        }
      }

      return latestImagePath;
    } catch (e) {
      print('Error getting local profile image path: $e');
      return null;
    }
  }

  /// Validate image file size and format
  static bool isValidImageFile(File imageFile) {
    try {
      // Check file size (max 10MB)
      final int fileSizeInBytes = imageFile.lengthSync();
      const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB
      
      if (fileSizeInBytes > maxSizeInBytes) {
        return false;
      }

      // Check file extension
      final String extension = imageFile.path.toLowerCase();
      return extension.endsWith('.jpg') || 
             extension.endsWith('.jpeg') || 
             extension.endsWith('.png');
    } catch (e) {
      return false;
    }
  }
}
