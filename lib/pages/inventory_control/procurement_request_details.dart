import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProcurementRequestDetailsPage extends StatefulWidget {
  final String requestId;
  const ProcurementRequestDetailsPage({Key? key, required this.requestId}) : super(key: key);

  @override
  State<ProcurementRequestDetailsPage> createState() => _ProcurementRequestDetailsPageState();
}

class _ProcurementRequestDetailsPageState extends State<ProcurementRequestDetailsPage> {
  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  String? _selectedStatus;
  final List<Map<String, dynamic>> _steps = [
    {'label': 'Requested', 'icon': Icons.assignment},
    {'label': 'Confirmed', 'icon': Icons.verified},
    {'label': 'Ordered', 'icon': Icons.shopping_cart},
    {'label': 'Paid', 'icon': Icons.credit_card},
    {'label': 'Shipped', 'icon': Icons.local_shipping},
    {'label': 'Delivered', 'icon': Icons.location_on},
    {'label': 'Rejected', 'icon': Icons.cancel}, // Added Rejected status
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    setState(() { _isLoading = true; });
    final doc = await FirebaseFirestore.instance.collection('procurement_requests').doc(widget.requestId).get();
    if (doc.exists) {
      setState(() {
        _requestData = doc.data();
        _selectedStatus = _requestData?['status'] ?? 'Requested';
        _isLoading = false;
      });
    } else {
      setState(() {
        _requestData = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_requestData == null) return;
    setState(() { _isLoading = true; });
    await FirebaseFirestore.instance.collection('procurement_requests').doc(widget.requestId).update({
      'status': newStatus,
      'lastUpdated': Timestamp.now(),
    });
    // If delivered, update inventory
    if (newStatus == 'Delivered') {
      await _restockPart();
    }
    await _fetchRequestDetails();
  }

  Future<void> _restockPart() async {
    final partId = _requestData?['partId'] ?? _requestData?['part_id'];
    final category = _requestData?['partCategory'] ?? _requestData?['category'];
    final qty = (_requestData?['quantity'] ?? _requestData?['requestedQty']) ?? 0;
    if (partId == null || category == null || qty == 0) return;
    final partDoc = FirebaseFirestore.instance.collection('inventory_parts').doc(category);
    final partSnap = await partDoc.get();
    if (partSnap.exists) {
      final partData = partSnap.data();
      if (partData != null && partData[partId] != null) {
        final currentQty = (partData[partId]['quantity'] ?? 0) as int;
        await partDoc.update({
          '$partId.quantity': currentQty + (qty is int ? qty : int.tryParse(qty.toString()) ?? 0),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If status is not in steps, fallback to first step
    final validLabels = _steps.map((s) => s['label'] as String).toList();
    final dropdownValue = validLabels.contains(_selectedStatus) ? _selectedStatus : validLabels.first;
    return Scaffold(
      appBar: AppBar(
        title: Text('Procurement Request Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRequestDetails,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _requestData == null
              ? Center(child: Text('Request not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _requestData?['partName'] ?? 'Part',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('ID: ${_requestData?['requestId'] ?? widget.requestId}', style: TextStyle(color: Colors.grey[700])),
                          SizedBox(width: 16),
                          Chip(
                            label: Text((_selectedStatus ?? '').toUpperCase()),
                            backgroundColor: Colors.blue[100],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.inventory, color: Colors.blue, size: 20),
                          SizedBox(width: 4),
                          Text('Qty: ${_requestData?['quantity'] ?? _requestData?['requestedQty'] ?? '-'}'),
                          SizedBox(width: 16),
                          Icon(Icons.business, color: Colors.orange, size: 20),
                          SizedBox(width: 4),
                          Text(_requestData?['supplier'] ?? '-'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.green, size: 20),
                          SizedBox(width: 4),
                          Text(_requestData?['supplierEmail'] ?? '-'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.purple, size: 20),
                          SizedBox(width: 4),
                          Text('ETA: ${_requestData?['eta'] != null ? _formatDateTime(_requestData?['eta']) : '-'}'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Requested: ${_requestData?['requestedDate'] ?? '-'}', style: TextStyle(color: Colors.grey[600])),
                      SizedBox(height: 24),
                      Center(child: Text('Delivery Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_steps.length, (i) {
                          final isActive = i <= (_steps.indexWhere((s) => s['label'] == _selectedStatus));
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: isActive ? Colors.green : Colors.grey[300],
                                child: Icon(_steps[i]['icon'] as IconData, color: isActive ? Colors.white : Colors.grey[600], size: 28),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _steps[i]['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive ? Colors.green : Colors.grey[600],
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: List.generate(_steps.length, (i) {
                          return Expanded(
                            child: Container(
                              height: 4,
                              color: i < (_steps.indexWhere((s) => s['label'] == _selectedStatus)) ? Colors.green : Colors.grey[300],
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 24),
                      Text('Last updated: ${_requestData?['lastUpdated']?.toString() ?? '-'}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      SizedBox(height: 24),
                      // Status update dropdown
                      Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      DropdownButton<String>(
                        value: dropdownValue,
                        items: validLabels.map((label) {
                          return DropdownMenuItem<String>(
                            value: label,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null && val != _selectedStatus) {
                            await _updateStatus(val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatDateTime(dynamic eta) {
    if (eta is Timestamp) {
      final date = eta.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (eta is DateTime) {
      return '${eta.day}/${eta.month}/${eta.year} ${eta.hour}:${eta.minute.toString().padLeft(2, '0')}';
    } else if (eta is String) {
      return eta;
    }
    return '-';
  }
}
