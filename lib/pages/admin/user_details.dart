import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final bool isCurrentUser;

  const UserDetailsPage({
    Key? key,
    required this.userId,
    required this.userData,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasChanges = false;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedRole = 'manager';
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    // Don't show "Not provided" when editing - show empty instead
    String phoneNumber = widget.userData['phone'] ?? '';
    _phoneController = TextEditingController(text: phoneNumber.isEmpty ? '' : _formatPhoneNumber(phoneNumber));
    _selectedRole = widget.userData['role'] ?? 'manager';
    _selectedGender = widget.userData['gender'] ?? 'Male';
    
    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  // Format phone number for display
  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return 'Not provided';
    
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
    
    return digits.isNotEmpty ? digits : 'Not provided';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), ''), // Store only digits
        'role': _selectedRole,
        'gender': _selectedGender,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(widget.userId).update(updatedData);

      // Update widget.userData with new values for immediate UI refresh
      setState(() {
        widget.userData['name'] = updatedData['name'];
        widget.userData['email'] = updatedData['email'];
        widget.userData['phone'] = updatedData['phone'];
        widget.userData['role'] = updatedData['role'];
        widget.userData['gender'] = updatedData['gender'];
        widget.userData['updatedAt'] = Timestamp.now(); // Approximate timestamp
        _isEditing = false;
        _hasChanges = false;
      });

      _showSnackBar('User updated successfully!');
    } catch (e) {
      _showSnackBar('Error updating user: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('users').doc(widget.userId).delete();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "${widget.userData['name']}" deleted successfully!'),
            backgroundColor: Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error deleting user: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Color(0xFFFF3B30) : Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    final TextEditingController confirmationController = TextEditingController();
    final String userName = widget.userData['name'] ?? 'Unknown';
    bool isNameMatched = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Color(0xFFFF3B30),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delete User',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to delete this user?',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF3B30).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Color(0xFFFF3B30),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Type "$userName" to confirm:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 6),
                    TextField(
                      controller: confirmationController,
                      decoration: InputDecoration(
                        hintText: 'Type user name here',
                        hintStyle: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Color(0xFFE5E5EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Color(0xFFE5E5EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Color(0xFF007AFF), width: 1),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF2F2F7),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          isNameMatched = value.trim() == userName;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isNameMatched ? () {
                    Navigator.of(context).pop();
                    _deleteUser();
                  } : null,
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: isNameMatched ? Color(0xFFFF3B30) : Color(0xFF8E8E93),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
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
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF8E8E93),
            ),
            suffixIcon: readOnly ? const Icon(
              Icons.lock_outlined,
              color: Color(0xFF8E8E93),
              size: 16,
            ) : null,
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
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
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
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
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role',
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
              value: _selectedRole,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.work_outline,
                  color: const Color(0xFF8E8E93),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: <String>['admin', 'manager', 'mechanic']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: value == 'admin' 
                          ? Color(0xFFFF3B30)
                          : value == 'mechanic'
                              ? Color(0xFF34C759)
                              : Color(0xFF007AFF),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String role) {
    return Center(
      child: Column(
        children: [
          Container(
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
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: role == 'admin' 
                  ? Color(0xFFFF3B30)
                  : role == 'mechanic'
                      ? Color(0xFF34C759)
                      : Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_isLoading || !_hasChanges) ? null : _updateUser,
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
      width: double.infinity,
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

  void _resetFields() {
    _nameController.text = widget.userData['name'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
    // Don't show "Not provided" when resetting - show empty instead
    String phoneNumber = widget.userData['phone'] ?? '';
    _phoneController.text = phoneNumber.isEmpty ? '' : _formatPhoneNumber(phoneNumber);
    // Reset role and gender
    _selectedRole = widget.userData['role'] ?? 'manager';
    _selectedGender = widget.userData['gender'] ?? 'Male';
    
    setState(() {
      _hasChanges = false;
    });
    
    _showSnackBar('Changes reset to original values');
  }

  void _showUnsavedChangesDialog() {
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
                setState(() {
                  _isEditing = false;
                  _hasChanges = false;
                  _initializeControllers(); // Reset controllers
                });
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
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData['name'] ?? 'Unknown';
    final email = widget.userData['email'] ?? 'No email';
    final phone = widget.userData['phone'] ?? '';
    final role = widget.userData['role'] ?? 'manager';
    final gender = widget.userData['gender'] ?? 'Not provided';
    final createdAt = widget.userData['createdAt'];
    final updatedAt = widget.userData['updatedAt'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: Text(
          _isEditing ? 'Edit User' : 'User Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_isEditing) {
              if (_hasChanges) {
                _showUnsavedChangesDialog();
              } else {
                setState(() {
                  _isEditing = false;
                  _initializeControllers(); // Reset controllers
                });
              }
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isEditing && !widget.isCurrentUser) ...[
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF007AFF)),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Color(0xFFFF3B30)),
              onPressed: _showDeleteConfirmationDialog,
            ),
            SizedBox(width: 8), // Add some padding from the right edge
          ],
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF007AFF),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header
                          _buildProfileHeader(name, role),
                          
                          const SizedBox(height: 32),
                          
                          if (_isEditing) ...[
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the full name';
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
                          ] else ...[
                            _buildReadOnlyField(
                              label: 'Full Name',
                              value: name,
                              icon: Icons.person_outline,
                            ),
                            
                            _buildReadOnlyField(
                              label: 'Phone Number',
                              value: _formatPhoneNumber(phone),
                              icon: Icons.phone_outlined,
                            ),
                            
                            _buildReadOnlyField(
                              label: 'Gender',
                              value: gender,
                              icon: Icons.person_outline,
                            ),
                          ],
                          
                          if (_isEditing) ...[
                            _buildRoleDropdown(),
                          ] else ...[
                            _buildReadOnlyField(
                              label: 'Role',
                              value: role.toUpperCase(),
                              icon: Icons.work_outline,
                            ),
                          ],
                          
                          if (_isEditing) ...[
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an email address';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            _buildReadOnlyField(
                              label: 'Email Address',
                              value: email,
                              icon: Icons.email_outlined,
                            ),
                          ],
                          
                          // Timestamps (view mode only)
                          if (!_isEditing) ...[
                            if (createdAt != null) ...[
                              _buildReadOnlyField(
                                label: 'Created',
                                value: createdAt is Timestamp 
                                    ? createdAt.toDate().toString().split('.')[0]
                                    : createdAt.toString(),
                                icon: Icons.calendar_today_outlined,
                              ),
                            ],
                            if (updatedAt != null) ...[
                              _buildReadOnlyField(
                                label: 'Last Updated',
                                value: updatedAt is Timestamp 
                                    ? updatedAt.toDate().toString().split('.')[0]
                                    : updatedAt.toString(),
                                icon: Icons.update_outlined,
                              ),
                            ],
                          ],
                          
                          const SizedBox(height: 40),
                          
                          // Action Buttons
                          if (_isEditing) ...[
                            // Save Button
                            _buildSaveButton(),
                            
                            const SizedBox(height: 16),
                            
                            // Reset Button
                            _buildResetButton(),
                          ],
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}