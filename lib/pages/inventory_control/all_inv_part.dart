import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_inv_part.dart';
import 'inv_part_detail.dart';
import 'barcode_scan_screen.dart';

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
  String selectedSupplier = 'All';
  String selectedStockStatus = 'All';
  List<String> suppliers = [];

  @override
  void initState() {
    super.initState();
    _fetchPartsFromFirestore();
    _fetchSuppliers();
  }

  // Fetch parts from Firestore
  Future<void> _fetchPartsFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('inventory_parts')
          .orderBy('createdAt', descending: true)
          .get();

      List<Part> fetchedParts = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Part(
          id: data['partId'] ?? doc.id,
          name: data['partName'] ?? 'Unknown Part',
          quantity: data['quantity'] ?? 0,
          isLowStock: data['isLowStock'] ?? false,
          category: data['category'] ?? 'Unknown',
          supplier: data['supplier'] ?? 'Unknown',
          description: data['description'] ?? '',
          documentId: doc.id,
          barcode: data['barcode'] ?? '',
        );
      }).toList();

      setState(() {
        parts = fetchedParts;
        _isLoading = false;
      });

      print('✅ Fetched ${parts.length} parts from Firestore');
    } catch (e) {
      print('❌ Error fetching parts: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error loading parts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchSuppliers() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('inventory_parts')
        .get();
    final uniqueSuppliers = querySnapshot.docs
        .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['supplier'] ?? '';
        })
        .toSet()
        .toList();
    setState(() {
      suppliers = List<String>.from(uniqueSuppliers.where((s) => s.isNotEmpty));
    });
  }

  Future<void> _resetFilters() async {
    setState(() {
      selectedCategory = 'All';
      selectedSupplier = 'All';
      selectedStockStatus = 'All';
      _searchQuery = '';
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
      final matchesSupplier =
          selectedSupplier == 'All' || part.supplier == selectedSupplier;
      final matchesStock =
          selectedStockStatus == 'All' ||
          (selectedStockStatus == 'Low Stock' && part.isLowStock) ||
          (selectedStockStatus == 'In Stock' && !part.isLowStock);
      return matchesSearch &&
          matchesCategory &&
          matchesSupplier &&
          matchesStock;
    }).toList();
  }

  Future<void> _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanScreen(
          onScanned: (barcode) {
            final found = parts.firstWhere(
              (p) => p.barcode == barcode,
              orElse: () => Part(
                id: '',
                name: '',
                quantity: 0,
                isLowStock: false,
                documentId: '',
                barcode: '',
              ),
            );
            if (found.id.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartDetailsScreen(part: found),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Part not found for barcode $barcode'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'All inventory parts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: _fetchPartsFromFirestore,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.refresh, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Header inside white container
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'All Inventory Parts',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${parts.length} parts',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Search Bar + Filters
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // First row: Search + Scan
                                Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Search parts...',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 16,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.qr_code_scanner,
                                        color: Colors.blue,
                                      ),
                                      onPressed: _scanBarcode,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // Second row: Filters + Reset
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    DropdownButton<String>(
                                      value: selectedCategory,
                                      items:
                                          [
                                                'All',
                                                'Engine',
                                                'Brakes',
                                                'Tires',
                                                'Suspension',
                                                'Electrical',
                                              ]
                                              .map(
                                                (cat) => DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(cat),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) =>
                                          setState(() => selectedCategory = v!),
                                    ),
                                    DropdownButton<String>(
                                      value: selectedSupplier,
                                      items: ['All', ...suppliers]
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => selectedSupplier = v!),
                                    ),
                                    DropdownButton<String>(
                                      value: selectedStockStatus,
                                      items: ['All', 'Low Stock', 'In Stock']
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(
                                        () => selectedStockStatus = v!,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _resetFilters,
                                      child: Text('Reset Filters'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[300],
                                        foregroundColor: Colors.black,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading parts from Firestore...',
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
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No parts found.\nAdd some parts to get started!'
                                        : 'No parts match your search.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchPartsFromFirestore,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                itemCount: filteredParts.length,
                                itemBuilder: (context, index) {
                                  return _buildPartItem(filteredParts[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartItem(Part part) {
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
              color: Colors.black.withValues(alpha: 0.05),
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
                    part.name,
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
                        ).withValues(alpha: 0.1),
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
                  _fetchPartsFromFirestore();
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
              _fetchPartsFromFirestore();
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

class Part {
  final String id;
  final String name;
  final int quantity;
  final bool isLowStock;
  final String category;
  final String supplier;
  final String description;
  final String documentId;
  final String barcode;

  Part({
    required this.id,
    required this.name,
    required this.quantity,
    required this.isLowStock,
    this.category = '',
    this.supplier = '',
    this.description = '',
    this.documentId = '',
    this.barcode = '',
  });
}
