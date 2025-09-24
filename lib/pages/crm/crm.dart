import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_customer.dart';
import 'customer_profile.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'crm_dashboard_widget.dart';


class CRMPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CRMPage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _CRMPageState createState() => _CRMPageState();
}

class _CRMPageState extends State<CRMPage> {
  static const _kGrey = Color(0xFF8E8E93);
  static const _kSurface = Color(0xFFF2F2F7);
  final TextEditingController _searchCtrl = TextEditingController();
  bool _listening = false;
  late final SpeechToText _stt;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String q = '';
  bool isAscending = true; // Default to ascending

  @override
  void initState() {
    super.initState();
    _stt = SpeechToText();
  }

  @override
  void dispose() {
    _stt.stop();
    _searchCtrl.dispose();
    super.dispose();
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
    
    return digits.isNotEmpty ? digits : 'Not provided'; // Return digits if format doesn't match
  }

  InputDecoration _searchInput(double s) => InputDecoration(
    hintText: 'Search',
    hintStyle: TextStyle(color: _kGrey, fontSize: (14 * s).clamp(13, 16)),
    prefixIcon: const Icon(Icons.search, color: _kGrey),
    suffixIcon: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (q.trim().isNotEmpty)
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.clear, color: _kGrey, size: 20),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => q = '');
              FocusScope.of(context).unfocus();
            },
          ),
        IconButton(
          tooltip: _listening ? 'Stop' : 'Voice Search',
          icon: Icon(
            _listening ? Icons.mic : Icons.mic_none,
            color: _listening ? Colors.red : _kGrey,
            size: 20,
          ),
          onPressed: _toggleVoice,
        ),
      ],
    ),
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    filled: true,
    fillColor: _kSurface,
    contentPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: const Text(
          'CRM',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                isAscending = !isAscending;
              });
            },
            tooltip: isAscending ? 'Sort Descending (Z-A)' : 'Sort Ascending (A-Z)',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.person_add, color: Colors.black),
              onPressed: () => _navigateToAddCustomer(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LayoutBuilder(
              builder: (context, c) {
                const base = 375.0;
                final s = (c.maxWidth / base).clamp(0.95, 1.15);
                return Column(
                  children: [
                    // CRM Dashboard Widget
                    if (q.isEmpty) // Only show dashboard when not searching
                      Container(
                        padding: EdgeInsets.all(16 * s),
                        child: CRMDashboardWidget(),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 10 * s),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: _searchInput(s),
                        onChanged: (v) => setState(() => q = v),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('customers')
                            .where('isDeleted', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Error loading customers',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      'Please check your internet connection and Firebase permissions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kGrey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading customers...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    color: Colors.grey[400],
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No customers found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add your first customer to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _navigateToAddCustomer,
                                    icon: Icon(Icons.add),
                                    label: Text('Add Customer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kGrey,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Filter customers based on search query and exclude deleted customers
                          List<DocumentSnapshot> filteredCustomers = snapshot.data!.docs.where((doc) {
                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                            
                            // Exclude deleted customers
                            if (data['isDeleted'] == true) return false;
                            
                            if (q.isEmpty) return true;

                            String searchText = [
                              data['customerName'],
                              data['phoneNumber'],
                              data['emailAddress']
                            ].where((text) => text != null)
                                .map((text) => text.toString().toLowerCase())
                                .join(' ');

                            return searchText.contains(q.toLowerCase());
                          }).toList();

                          // Sort customers by name
                          filteredCustomers.sort((a, b) {
                            Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
                            Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
                            
                            String nameA = (dataA['customerName'] ?? '').toString().toLowerCase();
                            String nameB = (dataB['customerName'] ?? '').toString().toLowerCase();
                            
                            return isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
                          });

                          if (filteredCustomers.isEmpty && q.isNotEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    color: Colors.grey[400],
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No customers found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredCustomers.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: Colors.transparent),
                            itemBuilder: (context, index) {
                              DocumentSnapshot doc = filteredCustomers[index];
                              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                              return _buildCustomerItem(
                                doc.id,
                                data,
                                isFirst: index == 0,
                                isLast: index == filteredCustomers.length - 1,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerItem(String docId, Map<String, dynamic> customerData, {bool isFirst = false, bool isLast = false}) {
    String customerName = customerData['customerName'] ?? 'Unknown Customer';
    String phoneNumber = customerData['phoneNumber'] ?? '';
    String email = customerData['emailAddress'] ?? '';
    List<String> vehicleIds = List<String>.from(customerData['vehicleIds'] ?? []);

    // Create display info from contact details with formatted phone number
    String displayInfo = '';
    if (phoneNumber.isNotEmpty) {
      displayInfo = _formatPhoneNumber(phoneNumber);
    } else if (email.isNotEmpty) {
      displayInfo = email;
    }
    if (vehicleIds.isNotEmpty) {
      displayInfo += vehicleIds.length == 1
          ? ' · 1 Vehicle'
          : ' · ${vehicleIds.length} Vehicles';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _navigateToCustomerProfile(docId, customerData),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Avatar with Vehicle icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getAvatarBgColor(customerName),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_outline,
                    color: _getAvatarIconColor(customerName), size: 26),
              ),
              const SizedBox(width: 12),
              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayInfo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kGrey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarBgColor(String name) {
    const swatches = [
      Color(0xFFE3F2FD), // Light Blue
      Color(0xFFE8F5E9), // Light Green
      Color(0xFFFFF3E0), // Light Orange
      Color(0xFFEDE7F6), // Light Purple
      Color(0xFFFFEBEE), // Light Pink
      Color(0xFFE0F7FA), // Light Cyan
      Color(0xFFFFF8E1), // Light Yellow
      Color(0xFFEFEBE9), // Light Brown
    ];
    return swatches[name.hashCode % swatches.length];
  }

  Color _getAvatarIconColor(String name) {
    const iconColors = [
      Color(0xFF1976D2), // Blue
      Color(0xFF388E3C), // Green
      Color(0xFFEF6C00), // Orange
      Color(0xFF7B1FA2), // Purple
      Color(0xFFE91E63), // Pink
      Color(0xFF00ACC1), // Cyan
      Color(0xFFFFB300), // Yellow
      Color(0xFF5D4037), // Brown
    ];
    return iconColors[name.hashCode % iconColors.length];
  }

  void _navigateToCustomerProfile(String docId, Map<String, dynamic> customerData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerProfilePage(
          customerId: docId,
        ),
      ),
    );
  }

  void _navigateToAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerPage(),
      ),
    );

    // The StreamBuilder will automatically update the list when new data is added to Firestore
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer added successfully!'),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final req = await Permission.microphone.request();
    if (req.isGranted) return true;

    if (req.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Microphone in App Settings')),
      );
      await openAppSettings();
    }
    return false;
  }

  Future<String?> _pickLocaleId() async {
    try {
      final sys = await _stt.systemLocale();
      final id = sys?.localeId;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return 'ms_MY';
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _stt.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!await _ensureMicPermission()) return;

    final available = await _stt.initialize(
      onError: (e) {
        debugPrint('STT error: $e');
        if (mounted) {
          setState(() => _listening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${e.errorMsg}')),
          );
        }
      },
      onStatus: (status) {
        final s = status.toLowerCase();
        if (s.contains('notlistening') || s.contains('done')) {
          if (mounted) setState(() => _listening = false);
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech service unavailable. Install/enable Google app & Speech Services.'),
          ),
        );
      }
      return;
    }

    final locale = await _pickLocaleId();
    if (mounted) setState(() => _listening = true);

    await _stt.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        _searchCtrl.text = text;
        _searchCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchCtrl.text.length),
        );
        if (mounted) setState(() => q = text);
      },
      localeId: locale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }
}