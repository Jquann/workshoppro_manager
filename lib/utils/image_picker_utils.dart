import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Simple image picker with error handling and debugging
  static Future<File?> pickImage(BuildContext context) async {
    try {
      // Show simple dialog for source selection
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (source == null) {
        print('No source selected');
        return null;
      }

      print('Selected source: $source');

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('No image picked');
        return null;
      }

      print('Image picked: ${pickedFile.path}');
      final file = File(pickedFile.path);
      
      final exists = await file.exists();
      print('File exists: $exists');
      
      if (exists) {
        final size = await file.length();
        print('File size: $size bytes');
        return file;
      } else {
        print('File does not exist at path');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error picking image: $e');
      print('Stack trace: $stackTrace');
      
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Validate image file
  static bool isValidImage(File file) {
    try {
      final path = file.path.toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png'];
      
      final hasValidExtension = validExtensions.any((ext) => path.endsWith(ext));
      if (!hasValidExtension) {
        print('Invalid file extension: $path');
        return false;
      }

      final sizeInBytes = file.lengthSync();
      const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
      
      if (sizeInBytes > maxSizeInBytes) {
        print('File too large: $sizeInBytes bytes');
        return false;
      }

      print('File validation passed: $path, size: $sizeInBytes bytes');
      return true;
    } catch (e) {
      print('Error validating file: $e');
      return false;
    }
  }
}