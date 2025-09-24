import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

/// A custom image widget that automatically refreshes when profile image is updated
class CachedProfileImage extends StatefulWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedProfileImage({
    Key? key,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<CachedProfileImage> createState() => _CachedProfileImageState();
}

class _CachedProfileImageState extends State<CachedProfileImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
    // Listen to global profile image updates
    ImageService.profileImageUpdateNotifier.addListener(_onImageUpdated);
  }

  @override
  void dispose() {
    ImageService.profileImageUpdateNotifier.removeListener(_onImageUpdated);
    super.dispose();
  }

  @override
  void didUpdateWidget(CachedProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
  }

  void _onImageUpdated() {
    if (mounted) {
      print('Profile image update detected, reloading...');
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imagePath == null || widget.imagePath!.isEmpty) {
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final bytes = await ImageService.getImageBytes(widget.imagePath!);
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = bytes == null;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = widget.placeholder ?? 
        const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
    } else if (_hasError || _imageBytes == null) {
      child = widget.errorWidget ??
        Container(
          color: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: (widget.width ?? 50) * 0.6,
            color: Colors.grey[600],
          ),
        );
    } else {
      child = Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true, // Smooth transitions
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }
}

/// Extension for common profile image configurations
class ProfileImageWidget extends StatelessWidget {
  final String? imagePath;
  final double size;

  const ProfileImageWidget({
    Key? key,
    this.imagePath,
    this.size = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedProfileImage(
      imagePath: imagePath,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.grey[600],
        ),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}