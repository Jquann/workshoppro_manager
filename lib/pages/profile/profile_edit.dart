import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../utils/image_picker_utils.dart';

class MalaysianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    
    // Remove all non-digit characters
    String digits = newText.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add leading zero if not present and has digits
    if (digits.isNotEmpty && !digits.startsWith('0')) {
      digits = '0$digits';
    }
    
    // Limit to 11 digits maximum
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }
    
    String formatted = '';
    
    // Format based on length
    if (digits.length >= 3) {
      formatted = digits.substring(0, 3);
      
      if (digits.length > 3) {
        if (digits.length <= 6) {
          formatted += '-${digits.substring(3)}';
        } else if (digits.length <= 10) {
          formatted += '-${digits.substring(3, 6)} ${digits.substring(6)}';
        } else {
          // 11 digits: 012-3456 7890
          formatted += '-${digits.substring(3, 7)} ${digits.substring(7)}';
        }
      }
    } else {
      formatted = digits;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ProfileEdit extends StatefulWidget {
  final Map<String, dynamic>? currentUserData;

  const ProfileEdit({Key? key, this.currentUserData}) : super(key: key);

  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isUploadingImage = false;
  String _selectedGender = 'Male'; // Default gender
  File? _selectedImageFile;
  String? _currentProfileImageUrl;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.currentUserData != null) {
      _nameController.text = widget.currentUserData!['name'] ?? '';
      // Format phone number when loading
      String phoneNumber = widget.currentUserData!['phone'] ?? '';
      _phoneController.text = _formatPhoneNumber(phoneNumber);
      // Load gender
      _selectedGender = widget.currentUserData!['gender'] ?? 'Male';
      // Load current profile image path (changed from URL to path)
      _currentProfileImageUrl = widget.currentUserData!['profileImagePath'];
    }
    
    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  // Format phone number for display
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digits = phoneNumber.trim().replaceAll(RegExp(r'[^\d]'), '');
    
    // Add leading zero if not present
    if (digits.isNotEmpty && !digits.startsWith('0')) {
      digits = '0$digits';
    }
    
    // Format based on length
    if (digits.length == 10) {
      // Format: 012-345 6789
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 11) {
      // Format: 012-3456 7890
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    
    return digits; // Return digits if format doesn't match
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => _onBackPressed(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    
                    const SizedBox(height: 32),
                    
                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [MalaysianPhoneFormatter()],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          String phoneNumber = value.trim().replaceAll(RegExp(r'[^\d]'), '');
                          
                          // Add leading zero if not present for validation
                          if (!phoneNumber.startsWith('0')) {
                            phoneNumber = '0$phoneNumber';
                          }
                          
                          // Check if it's a valid Malaysian phone number (10-11 digits with leading 0)
                          if (phoneNumber.length < 10 || phoneNumber.length > 11) {
                            return 'Please enter a valid Malaysian phone number';
                          }
                          
                          // Check if it starts with valid Malaysian mobile prefixes (01x)
                          if (!phoneNumber.startsWith('01')) {
                            return 'Please enter a valid Malaysian mobile number starting with 01';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildGenderDropdown(),
                    
                    const SizedBox(height: 32),
                    
                    // Work Information Section
                    _buildSectionHeader('Work Information'),
                    const SizedBox(height: 16),
                    
                    _buildReadOnlyField(
                      label: 'Role',
                      value: widget.currentUserData?['role'] ?? 'admin',
                      icon: Icons.work_outline,
                    ),
                    
                    const SizedBox(height: 32),

                    
                    // Save Button
                    _buildSaveButton(),
                    
                    const SizedBox(height: 16),
                    
                    // Reset Button
                    _buildResetButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE5E5EA),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _selectedImageFile != null
                    ? Image.file(
                        _selectedImageFile!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty)
                        ? Image.file(
                            File(_currentProfileImageUrl!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF007AFF),
                                      Color(0xFF5856D6),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF007AFF),
                                  Color(0xFF5856D6),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingImage ? null : () => _showImageSourceDialog(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: _isUploadingImage
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.currentUserData?['email'] ?? _authService.currentUser?.email ?? 'User',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_selectedImageFile != null || (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _isUploadingImage ? null : _editCurrentImage,
                  icon: const Icon(
                    Icons.crop_outlined,
                    size: 16,
                    color: Color(0xFF007AFF),
                  ),
                  label: const Text(
                    'Crop Photo',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: _isUploadingImage ? null : _removeProfileImage,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFFF3B30),
                  ),
                  label: const Text(
                    'Remove Photo',
                    style: TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            hintStyle: const TextStyle(
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF8E8E93),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3B30)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.person_outline,
                color: const Color(0xFF8E8E93),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: ['Male', 'Female', 'Other'].map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGender = newValue;
                  _hasChanges = true;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF8E8E93),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outlined,
                color: Color(0xFF8E8E93),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: (_isLoading || !_hasChanges) ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _resetFields,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF007AFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Reset Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? profileImagePath = _currentProfileImageUrl;

      // Save new image locally if selected
      if (_selectedImageFile != null) {
        setState(() {
          _isUploadingImage = true;
        });
        
        // Delete old image if exists
        if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
          await ImageService.deleteLocalProfileImage(_currentProfileImageUrl!);
        }
        
        // Save new image locally
        profileImagePath = await ImageService.saveProfileImageLocally(_selectedImageFile!);
        
        setState(() {
          _isUploadingImage = false;
        });
      }

      // Create updated user data
      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'role': widget.currentUserData?['role'] ?? 'admin', // Keep existing role
        'phone': _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), ''), // Store only digits
        'gender': _selectedGender, // Add gender
        'email': widget.currentUserData?['email'] ?? _authService.currentUser?.email,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add profile image path if exists
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        updatedData['profileImagePath'] = profileImagePath;
      } else {
        // If image was removed, remove the field from Firestore
        if (_currentProfileImageUrl != null && _selectedImageFile == null) {
          updatedData['profileImagePath'] = null;
        }
      }

      // Save to Firestore
      await _authService.updateUserData(updatedData);

      if (mounted) {
        _showSnackBar('Profile updated successfully!', isError: false);
        setState(() {
          _hasChanges = false;
          _selectedImageFile = null;
          _currentProfileImageUrl = profileImagePath;
        });
        
        // Return success indicator to previous screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Profile Picture',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'How would you like to add your profile picture?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectProfileImageWithoutCrop();
              },
              child: const Text(
                'No Crop',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectProfileImage();
              },
              child: const Text(
                'Crop to Square',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectProfileImageWithoutCrop() async {
    try {
      print('Opening image picker dialog (no crop)...');
      
      final File? imageFile = await ImagePickerUtils.pickImage(context);
      
      print('Image file result: $imageFile');
      
      if (imageFile != null) {
        print('Image file path: ${imageFile.path}');
        
        // Validate the selected image
        if (!ImagePickerUtils.isValidImage(imageFile)) {
          _showSnackBar('Please select a valid image file (JPG, PNG) under 10MB', isError: true);
          return;
        }

        print('Setting selected image file in state (no crop)...');
        setState(() {
          _selectedImageFile = imageFile;
          _hasChanges = true;
        });
        print('State updated successfully');
        _showSnackBar('Image selected successfully!');
      } else {
        print('No image file selected');
      }
    } catch (e) {
      print('Error in _selectProfileImageWithoutCrop: $e');
      _showSnackBar('Error selecting image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _selectProfileImage() async {
    try {
      print('Opening image picker dialog...');
      
      // Use the simpler utility for testing
      final File? imageFile = await ImagePickerUtils.pickImage(context);
      
      print('Image file result: $imageFile');
      
      if (imageFile != null) {
        print('Image file path: ${imageFile.path}');
        
        // Validate the selected image
        if (!ImagePickerUtils.isValidImage(imageFile)) {
          _showSnackBar('Please select a valid image file (JPG, PNG) under 10MB', isError: true);
          return;
        }

        // Crop the image to 1:1 aspect ratio
        print('Opening image cropper...');
        
        try {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: imageFile.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            maxWidth: 512,
            maxHeight: 512,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 90,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Profile Picture',
                toolbarColor: const Color(0xFF007AFF),
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
                hideBottomControls: false,
                showCropGrid: true,
              ),
              IOSUiSettings(
                title: 'Crop Profile Picture',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
              ),
            ],
          );

          if (croppedFile != null) {
            print('Setting cropped image file in state...');
            setState(() {
              _selectedImageFile = File(croppedFile.path);
              _hasChanges = true;
            });
            print('State updated successfully');
            _showSnackBar('Image cropped and selected successfully!');
          } else {
            print('Image cropping was cancelled');
            _showSnackBar('Image cropping cancelled');
          }
        } catch (cropError) {
          print('Error during cropping: $cropError');
          _showSnackBar('Error cropping image. Using original image.', isError: true);
          
          // Fallback: use original image if cropping fails
          setState(() {
            _selectedImageFile = imageFile;
            _hasChanges = true;
          });
          _showSnackBar('Image selected successfully (cropping skipped)');
        }
      } else {
        print('No image file selected');
      }
    } catch (e) {
      print('Error in _selectProfileImage: $e');
      _showSnackBar('Error selecting or cropping image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _editCurrentImage() async {
    try {
      File? imageToEdit;
      
      // Determine which image to edit
      if (_selectedImageFile != null) {
        imageToEdit = _selectedImageFile!;
      } else if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
        imageToEdit = File(_currentProfileImageUrl!);
      }
      
      if (imageToEdit == null || !await imageToEdit.exists()) {
        _showSnackBar('No image found to edit', isError: true);
        return;
      }

      print('Opening image cropper for existing image...');
      
      // Crop the existing image to 1:1 aspect ratio
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: imageToEdit.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          maxWidth: 512,
          maxHeight: 512,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Picture',
              toolbarColor: const Color(0xFF007AFF),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
              showCropGrid: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Picture',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          print('Setting cropped image file in state...');
          setState(() {
            _selectedImageFile = File(croppedFile.path);
            _hasChanges = true;
          });
          print('State updated successfully');
          _showSnackBar('Image cropped successfully!');
        } else {
          print('Image cropping was cancelled');
          _showSnackBar('Image cropping cancelled');
        }
      } catch (cropError) {
        print('Error during cropping: $cropError');
        _showSnackBar('Error cropping image: ${cropError.toString()}', isError: true);
      }
    } catch (e) {
      print('Error in _editCurrentImage: $e');
      _showSnackBar('Error cropping image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() {
      _selectedImageFile = null;
      _hasChanges = true;
    });

    // If there's a current profile image URL, mark it for deletion when saving
    if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
      _currentProfileImageUrl = null;
    }
  }

  void _resetFields() {
    _nameController.text = widget.currentUserData?['name'] ?? '';
    // Format phone number when resetting
    String phoneNumber = widget.currentUserData?['phone'] ?? '';
    _phoneController.text = _formatPhoneNumber(phoneNumber);
    // Reset gender
    _selectedGender = widget.currentUserData?['gender'] ?? 'Male';
    
    setState(() {
      _hasChanges = false;
    });
    
    _showSnackBar('Changes reset to original values');
  }

  void _onBackPressed() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Unsaved Changes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            content: const Text(
              'You have unsaved changes. Do you want to discard them?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Discard',
                  style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}