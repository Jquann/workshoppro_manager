import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/part.dart';

class WorkOrderCreateScreen extends StatefulWidget {
  @override
  _WorkOrderCreateScreenState createState() => _WorkOrderCreateScreenState();
}

class _WorkOrderCreateScreenState extends State<WorkOrderCreateScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Part> parts = [];
  Map<String, int> selectedParts = {};
  bool _isLoading = true;
  String workOrderName = '';

  @override
  void initState() {
    super.initState();
    _fetchParts();
  }

  Future<void> _fetchParts() async {
    QuerySnapshot querySnapshot = await _firestore.collection('inventory_parts').get();
    setState(() {
      parts = querySnapshot.docs.map((doc) {
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
        );
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _createWorkOrder() async {
    if (workOrderName.trim().isEmpty || selectedParts.isEmpty) return;
    // Validate stock
    for (var entry in selectedParts.entries) {
      final part = parts.firstWhere((p) => p.documentId == entry.key);
      if (entry.value > part.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for ${part.name}'), backgroundColor: Colors.red),
        );
        return;
      }
    }
    // Create work order
    await _firestore.collection('work_orders').add({
      'name': workOrderName,
      'allocatedParts': selectedParts.entries.map((e) => {
        'partId': e.key,
        'quantity': e.value,
      }).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Update part quantities
    for (var entry in selectedParts.entries) {
      final part = parts.firstWhere((p) => p.documentId == entry.key);
      await _firestore.collection('inventory_parts').doc(entry.key).update({
        'quantity': part.quantity - entry.value,
        'isLowStock': (part.quantity - entry.value) <= part.lowStockThreshold,
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Work order created!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Work Order')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                double horizontalPadding = constraints.maxWidth < 500 ? 12 : 32;
                double headerFontSize = constraints.maxWidth < 500 ? 20 : 24;
                double labelFontSize = constraints.maxWidth < 500 ? 14 : 16;
                return Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Work Order Name'),
                        onChanged: (v) => setState(() => workOrderName = v),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: parts.length,
                          itemBuilder: (ctx, i) {
                            final part = parts[i];
                            return ListTile(
                              title: Text(part.name, style: TextStyle(fontSize: labelFontSize)),
                              subtitle: Text('Qty: ${part.quantity}', style: TextStyle(fontSize: labelFontSize)),
                              trailing: SizedBox(
                                width: 100,
                                child: TextFormField(
                                  decoration: InputDecoration(hintText: 'Allocate'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    int qty = int.tryParse(v) ?? 0;
                                    setState(() {
                                      if (qty > 0) {
                                        selectedParts[part.documentId] = qty;
                                      } else {
                                        selectedParts.remove(part.documentId);
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _createWorkOrder,
                        child: Text('Create Work Order', style: TextStyle(fontSize: headerFontSize)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
