import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inv_part_detail.dart' show PartDetailsScreen;
import 'add_inv_part.dart';
import '../../models/part.dart';

class AllInventoryPartsScreen extends StatefulWidget {
  @override
  _AllInventoryPartsScreenState createState() =>
      _AllInventoryPartsScreenState();
}

class _AllInventoryPartsScreenState extends State<AllInventoryPartsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Part> parts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String selectedCategory = 'All';
  String selectedStockStatus = 'All';
  List<String> categories = [];
  bool showLowStockOnly = false; // Add low stock filter toggle

  @override
  void initState() {
    super.initState();
    _fetchPartsAndFiltersFromFirestore();
    _checkAndUpdateAllLowStock(); // Automatically check low stock on app load
  }

  // Fetch all parts and build filters from Firestore
  Future<void> _fetchPartsAndFiltersFromFirestore() async {
    setState(() { _isLoading = true; });
    try {
      QuerySnapshot categorySnapshot = await _firestore.collection('inventory_parts').get();
      List<Part> fetchedParts = [];
      List<String> categoryList = [];

      for (var categoryDoc in categorySnapshot.docs) {
        categoryList.add(categoryDoc.id);
        Map<String, dynamic> data = categoryDoc.data() as Map<String, dynamic>;

        // Process each part in the category
        for (String partName in data.keys) {
          var partData = data[partName];
          if (partData is Map<String, dynamic>) {
            // Get threshold and quantity
            int quantity = partData['quantity'] ?? 0;
            int lowStockThreshold = partData['lowStockThreshold'] ?? 15;

            // Automatically determine low stock status
            bool isLowStock = quantity <= lowStockThreshold;

            // Update Firestore if the low stock status has changed
            if ((partData['isLowStock'] ?? false) != isLowStock) {
              await _firestore.collection('inventory_parts').doc(categoryDoc.id).update({
                '$partName.isLowStock': isLowStock,
              });
            }

            // Use factory constructor to load suppliers and all fields
            fetchedParts.add(Part.fromFirestore(partData, categoryDoc.id));
          }
        }
      }

      setState(() {
        parts = fetchedParts;
        categories = categoryList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error loading parts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to check and update low stock status for all parts
  Future<void> _checkAndUpdateAllLowStock() async {
    try {
      QuerySnapshot categorySnapshot = await _firestore.collection('inventory_parts').get();

      for (var categoryDoc in categorySnapshot.docs) {
        Map<String, dynamic> data = categoryDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> updates = {};

        for (String partName in data.keys) {
          var partData = data[partName];
          if (partData is Map<String, dynamic>) {
            int quantity = partData['quantity'] ?? 0;
            int lowStockThreshold = partData['lowStockThreshold'] ?? 15;
            bool currentLowStockStatus = partData['isLowStock'] ?? false;
            bool newLowStockStatus = quantity <= lowStockThreshold;

            // Update if status has changed
            if (currentLowStockStatus != newLowStockStatus) {
              updates['$partName.isLowStock'] = newLowStockStatus;
            }
          }
        }

        // Batch update for this category if there are changes
        if (updates.isNotEmpty) {
          await _firestore.collection('inventory_parts').doc(categoryDoc.id).update(updates);
        }
      }
    } catch (e) {
      print('Error checking low stock status: $e');
    }
  }

  Future<void> _resetFilters() async {
    setState(() {
      selectedCategory = 'All';
      selectedStockStatus = 'All';
      _searchQuery = '';
      showLowStockOnly = false;
    });
  }

  // Filter parts based on search query and filters
  List<Part> get filteredParts {
    return parts.where((part) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          part.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          part.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          part.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'All' || part.category == selectedCategory;
      final matchesStock =
          selectedStockStatus == 'All' ||
          (selectedStockStatus == 'Low Stock' && part.isLowStock) ||
          (selectedStockStatus == 'In Stock' && !part.isLowStock);
      final matchesLowStockToggle = !showLowStockOnly || part.isLowStock;
      return matchesSearch && matchesCategory && matchesStock && matchesLowStockToggle;
    }).toList();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 18),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Inventory Parts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${filteredParts.length} of ${parts.length} parts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Search and Filters Section
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by part name, ID, or category...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCategory,
                                  hint: Text('All categories'),
                                  isExpanded: true,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  items: ['All', ...categories].map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => selectedCategory = v!),
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedStockStatus,
                                  hint: Text('All status'),
                                  isExpanded: true,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  items: ['All', 'Low Stock', 'In Stock'].map((status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                        status,
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() => selectedStockStatus = v!),
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Quick Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetFilters,
                          icon: Icon(Icons.clear_all, size: 18),
                          label: Text('Reset Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: showLowStockOnly ? Colors.red[50] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: showLowStockOnly ? Colors.red[200]! : Colors.grey[300]!,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              showLowStockOnly = !showLowStockOnly;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  showLowStockOnly ? Icons.warning : Icons.warning_outlined,
                                  color: showLowStockOnly ? Colors.red[600] : Colors.grey[600],
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Low Stock Only',
                                  style: TextStyle(
                                    color: showLowStockOnly ? Colors.red[700] : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Parts List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue[600]),
                          SizedBox(height: 16),
                          Text(
                            'Loading inventory parts...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredParts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No parts found'
                                    : 'No parts match your search',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Add some parts to get started!'
                                    : 'Try adjusting your filters or search terms',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchPartsAndFiltersFromFirestore,
                          color: Colors.blue[600],
                          child: ListView.builder(
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredParts.length,
                            itemBuilder: (context, index) {
                              return _buildEnhancedPartItem(filteredParts[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPartItem(Part part) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartDetailsScreen(part: part),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(part.category),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(part.category),
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 16),

            // Part Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.name, // <-- Show part name as the main title
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ID: ${part.id} | Qty: ${part.quantity}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (part.category.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          part.category,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        part.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(part.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Low Stock Badge
            if (part.isLowStock)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Low Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Popup menu for Edit/Delete
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNewPartScreen(
                        part: part,
                        documentId: part.documentId,
                      ),
                    ),
                  );
                  _fetchPartsAndFiltersFromFirestore();
                } else if (value == 'delete') {
                  _showDeleteDialog(part.documentId);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String documentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Part'),
        content: Text('Are you sure you want to delete this part?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore
                  .collection('inventory_parts')
                  .doc(documentId)
                  .delete();
              _fetchPartsAndFiltersFromFirestore();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Part deleted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'engine':
        return Colors.blue;
      case 'brakes':
        return Colors.red;
      case 'tires':
        return Colors.orange;
      case 'suspension':
        return Colors.green;
      case 'electrical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'engine':
        return Icons.settings;
      case 'brakes':
        return Icons.stop_circle;
      case 'tires':
        return Icons.circle;
      case 'suspension':
        return Icons.height;
      case 'electrical':
        return Icons.electrical_services;
      default:
        return Icons.build;
    }
  }
}
