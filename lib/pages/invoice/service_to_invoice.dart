import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firestore_service.dart';
import '../../models/service_model.dart';
import '../../models/vehicle_model.dart';

class ServiceToInvoiceMigration extends StatefulWidget {
  const ServiceToInvoiceMigration({super.key});

  @override
  State<ServiceToInvoiceMigration> createState() =>
      _ServiceToInvoiceMigrationState();
}

class _ServiceToInvoiceMigrationState extends State<ServiceToInvoiceMigration> {
  bool _isRunning = false;
  bool _isCompleted = false;
  int _totalVehicles = 0;
  int _processedVehicles = 0;
  int _totalServices = 0;
  int _processedServices = 0;
  int _createdInvoices = 0;
  int _failedInvoices = 0;
  List<String> _errorLogs = [];
  List<String> _successLogs = [];

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service to Invoice Migration'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Migration Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressRow(
                      'Vehicles',
                      _processedVehicles,
                      _totalVehicles,
                    ),
                    const SizedBox(height: 8),
                    _buildProgressRow(
                      'Services',
                      _processedServices,
                      _totalServices,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Created Invoices',
                      _createdInvoices,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow('Failed', _failedInvoices, Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isCompleted && !_isRunning)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startMigration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Start Migration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (_isRunning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Migration in progress...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Migration Completed!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            if (_successLogs.isNotEmpty || _errorLogs.isNotEmpty)
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Success Log'),
                          Tab(text: 'Error Log'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildLogView(_successLogs, Colors.green),
                            _buildLogView(_errorLogs, Colors.red),
                          ],
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

  Widget _buildProgressRow(String label, int current, int total) {
    final progress = total > 0 ? current / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$current / $total'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLogView(List<String> logs, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: logs.isEmpty
          ? Center(
              child: Text(
                'No ${color == Colors.green ? 'success' : 'error'} logs yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    logs[index],
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _startMigration() async {
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _totalVehicles = 0;
      _processedVehicles = 0;
      _totalServices = 0;
      _processedServices = 0;
      _createdInvoices = 0;
      _failedInvoices = 0;
      _errorLogs.clear();
      _successLogs.clear();
    });

    try {
      // Get all vehicles
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .get();

      setState(() {
        _totalVehicles = vehiclesSnapshot.docs.length;
      });

      _addSuccessLog('Found ${_totalVehicles} vehicles to process');

      // Process each vehicle
      for (final vehicleDoc in vehiclesSnapshot.docs) {
        try {
          final vehicleData = vehicleDoc.data();
          final vehicle = VehicleModel.fromMap(vehicleDoc.id, vehicleData);

          _addSuccessLog(
            'Processing vehicle: ${vehicle.carPlate} (${vehicle.customerName})',
          );

          // Get all service records for this vehicle
          final serviceRecordsSnapshot = await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleDoc.id)
              .collection('service_records')
              .get();

          final serviceCount = serviceRecordsSnapshot.docs.length;
          _addSuccessLog(
            'Found $serviceCount service records for vehicle ${vehicle.carPlate}',
          );

          setState(() {
            _totalServices += serviceCount;
          });

          // Process each service record
          for (final serviceDoc in serviceRecordsSnapshot.docs) {
            try {
              final serviceData = serviceDoc.data();

              // Handle the parsing issue for parts and labor that might be stored as Maps
              final processedServiceData = Map<String, dynamic>.from(
                serviceData,
              );

              // Convert parts from Map to List if needed with better error handling
              if (processedServiceData['parts'] != null) {
                final partsData = processedServiceData['parts'];
                if (partsData is Map) {
                  // Convert Map values to List, but check each value is also a Map
                  final partsList = <Map<String, dynamic>>[];
                  for (final entry in partsData.entries) {
                    if (entry.value is Map) {
                      partsList.add(
                        Map<String, dynamic>.from(entry.value as Map),
                      );
                    } else {
                      // Skip invalid part entries
                      _addErrorLog(
                        'Skipping invalid part entry in service ${serviceDoc.id}: ${entry.key} = ${entry.value}',
                      );
                    }
                  }
                  processedServiceData['parts'] = partsList;
                } else if (partsData is List) {
                  // Ensure all list items are Maps
                  final partsList = <Map<String, dynamic>>[];
                  for (final item in partsData) {
                    if (item is Map) {
                      partsList.add(Map<String, dynamic>.from(item as Map));
                    } else {
                      // Skip invalid part entries
                      _addErrorLog(
                        'Skipping invalid part item in service ${serviceDoc.id}: $item',
                      );
                    }
                  }
                  processedServiceData['parts'] = partsList;
                } else {
                  processedServiceData['parts'] = [];
                }
              }

              // Convert labor from Map to List if needed with better error handling
              if (processedServiceData['labor'] != null) {
                final laborData = processedServiceData['labor'];
                if (laborData is Map) {
                  // Check if this is a flat map with labor fields or a map of labor objects
                  if (laborData.containsKey('name') ||
                      laborData.containsKey('hours') ||
                      laborData.containsKey('rate')) {
                    // This is a single labor entry stored as flat fields
                    final laborMap = <String, dynamic>{
                      'name': laborData['name']?.toString() ?? 'Labor',
                      'hours': (laborData['hours'] is num)
                          ? (laborData['hours'] as num).toDouble()
                          : (laborData['hourse'] is num)
                          ? (laborData['hourse'] as num).toDouble()
                          : 0.0, // Handle typo 'hourse'
                      'rate': (laborData['rate'] is num)
                          ? (laborData['rate'] as num).toDouble()
                          : 0.0,
                    };
                    processedServiceData['labor'] = [laborMap];
                  } else {
                    // This is a map of labor objects
                    final laborList = <Map<String, dynamic>>[];
                    for (final entry in laborData.entries) {
                      if (entry.value is Map) {
                        final laborMap = Map<String, dynamic>.from(
                          entry.value as Map,
                        );
                        // Handle the 'hourse' typo if present
                        if (laborMap.containsKey('hourse') &&
                            !laborMap.containsKey('hours')) {
                          laborMap['hours'] = laborMap['hourse'];
                          laborMap.remove('hourse');
                        }
                        laborList.add(laborMap);
                      } else {
                        // Skip invalid labor entries
                        _addErrorLog(
                          'Skipping invalid labor entry in service ${serviceDoc.id}: ${entry.key} = ${entry.value}',
                        );
                      }
                    }
                    processedServiceData['labor'] = laborList;
                  }
                } else if (laborData is List) {
                  // Ensure all list items are Maps
                  final laborList = <Map<String, dynamic>>[];
                  for (final item in laborData) {
                    if (item is Map) {
                      final laborMap = Map<String, dynamic>.from(item as Map);
                      // Handle the 'hourse' typo if present
                      if (laborMap.containsKey('hourse') &&
                          !laborMap.containsKey('hours')) {
                        laborMap['hours'] = laborMap['hourse'];
                        laborMap.remove('hourse');
                      }
                      laborList.add(laborMap);
                    } else {
                      // Skip invalid labor entries
                      _addErrorLog(
                        'Skipping invalid labor item in service ${serviceDoc.id}: $item',
                      );
                    }
                  }
                  processedServiceData['labor'] = laborList;
                } else {
                  processedServiceData['labor'] = [];
                }
              }

              final serviceRecord = ServiceRecordModel.fromMap(
                serviceDoc.id,
                processedServiceData,
              );

              // Skip if no parts or labor (empty service)
              if (serviceRecord.parts.isEmpty && serviceRecord.labor.isEmpty) {
                _addSuccessLog(
                  'Skipping empty service record ${serviceRecord.id} for vehicle ${vehicle.carPlate}',
                );
                setState(() => _processedServices++);
                continue;
              }

              // Only process completed services
              if (serviceRecord.status != ServiceRecordModel.statusCompleted) {
                _addSuccessLog(
                  'Skipping non-completed service record ${serviceRecord.id} (status: ${serviceRecord.status}) for vehicle ${vehicle.carPlate}',
                );
                setState(() => _processedServices++);
                continue;
              }

              // Create invoice using the existing addInvoice function with migration defaults
              final invoiceId = await _firestoreService.addInvoice(
                vehicleDoc.id,
                serviceRecord,
                vehicle.customerName,
                vehicle.carPlate,
                serviceRecord.mechanic,
                'System Migration', // createdBy
                customStatus: 'Approved', // Default to Approved for migration
                customPaymentStatus: 'Paid', // Default to Paid for migration
                customCreatedAt:
                    serviceRecord.updatedAt ??
                    serviceRecord
                        .date, // Use updatedAt if available, fallback to service date
              );

              setState(() {
                _createdInvoices++;
                _processedServices++;
              });

              _addSuccessLog(
                'Created invoice $invoiceId for service ${serviceRecord.id} (${vehicle.carPlate})',
              );
            } catch (e) {
              setState(() {
                _failedInvoices++;
                _processedServices++;
              });
              _addErrorLog(
                'Failed to create invoice for service ${serviceDoc.id}: $e',
              );
            }
          }

          setState(() => _processedVehicles++);
        } catch (e) {
          setState(() => _processedVehicles++);
          _addErrorLog('Failed to process vehicle ${vehicleDoc.id}: $e');
        }
      }

      setState(() => _isCompleted = true);
      _addSuccessLog(
        'Migration completed! Created $_createdInvoices invoices, $_failedInvoices failed',
      );
    } catch (e) {
      _addErrorLog('Migration failed: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  void _addSuccessLog(String message) {
    setState(() {
      _successLogs.add(
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
    });
  }

  void _addErrorLog(String message) {
    setState(() {
      _errorLogs.add(
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
    });
  }
}

/// Standalone function to run migration programmatically
class InvoiceMigrationService {
  static final FirestoreService _firestoreService = FirestoreService();

  /// Run the migration and return results
  static Future<Map<String, dynamic>> runMigration() async {
    int totalVehicles = 0;
    int processedVehicles = 0;
    int totalServices = 0;
    int processedServices = 0;
    int createdInvoices = 0;
    int failedInvoices = 0;
    List<String> errorLogs = [];
    List<String> successLogs = [];

    try {
      // Get all vehicles
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .get();

      totalVehicles = vehiclesSnapshot.docs.length;
      print('Found $totalVehicles vehicles to process');

      // Process each vehicle
      for (final vehicleDoc in vehiclesSnapshot.docs) {
        try {
          final vehicleData = vehicleDoc.data();
          final vehicle = VehicleModel.fromMap(vehicleDoc.id, vehicleData);

          print(
            'Processing vehicle: ${vehicle.carPlate} (${vehicle.customerName})',
          );

          // Get all service records for this vehicle
          final serviceRecordsSnapshot = await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleDoc.id)
              .collection('service_records')
              .get();

          final serviceCount = serviceRecordsSnapshot.docs.length;
          print(
            'Found $serviceCount service records for vehicle ${vehicle.carPlate}',
          );

          totalServices += serviceCount;

          // Process each service record
          for (final serviceDoc in serviceRecordsSnapshot.docs) {
            try {
              final serviceData = serviceDoc.data();

              // Handle the parsing issue for parts and labor that might be stored as Maps
              final processedServiceData = Map<String, dynamic>.from(
                serviceData,
              );

              // Convert parts from Map to List if needed with better error handling
              if (processedServiceData['parts'] != null) {
                final partsData = processedServiceData['parts'];
                if (partsData is Map) {
                  // Convert Map values to List, but check each value is also a Map
                  final partsList = <Map<String, dynamic>>[];
                  for (final entry in partsData.entries) {
                    if (entry.value is Map) {
                      partsList.add(
                        Map<String, dynamic>.from(entry.value as Map),
                      );
                    } else {
                      // Skip invalid part entries
                      print(
                        'Skipping invalid part entry in service ${serviceDoc.id}: ${entry.key} = ${entry.value}',
                      );
                    }
                  }
                  processedServiceData['parts'] = partsList;
                } else if (partsData is List) {
                  // Ensure all list items are Maps
                  final partsList = <Map<String, dynamic>>[];
                  for (final item in partsData) {
                    if (item is Map) {
                      partsList.add(Map<String, dynamic>.from(item as Map));
                    } else {
                      // Skip invalid part entries
                      print(
                        'Skipping invalid part item in service ${serviceDoc.id}: $item',
                      );
                    }
                  }
                  processedServiceData['parts'] = partsList;
                } else {
                  processedServiceData['parts'] = [];
                }
              }

              // Convert labor from Map to List if needed with better error handling
              if (processedServiceData['labor'] != null) {
                final laborData = processedServiceData['labor'];
                if (laborData is Map) {
                  // Check if this is a flat map with labor fields or a map of labor objects
                  if (laborData.containsKey('name') ||
                      laborData.containsKey('hours') ||
                      laborData.containsKey('rate')) {
                    // This is a single labor entry stored as flat fields
                    final laborMap = <String, dynamic>{
                      'name': laborData['name']?.toString() ?? 'Labor',
                      'hours': (laborData['hours'] is num)
                          ? (laborData['hours'] as num).toDouble()
                          : (laborData['hourse'] is num)
                          ? (laborData['hourse'] as num).toDouble()
                          : 0.0, // Handle typo 'hourse'
                      'rate': (laborData['rate'] is num)
                          ? (laborData['rate'] as num).toDouble()
                          : 0.0,
                    };
                    processedServiceData['labor'] = [laborMap];
                  } else {
                    // This is a map of labor objects
                    final laborList = <Map<String, dynamic>>[];
                    for (final entry in laborData.entries) {
                      if (entry.value is Map) {
                        final laborMap = Map<String, dynamic>.from(
                          entry.value as Map,
                        );
                        // Handle the 'hourse' typo if present
                        if (laborMap.containsKey('hourse') &&
                            !laborMap.containsKey('hours')) {
                          laborMap['hours'] = laborMap['hourse'];
                          laborMap.remove('hourse');
                        }
                        laborList.add(laborMap);
                      } else {
                        // Skip invalid labor entries
                        print(
                          'Skipping invalid labor entry in service ${serviceDoc.id}: ${entry.key} = ${entry.value}',
                        );
                      }
                    }
                    processedServiceData['labor'] = laborList;
                  }
                } else if (laborData is List) {
                  // Ensure all list items are Maps
                  final laborList = <Map<String, dynamic>>[];
                  for (final item in laborData) {
                    if (item is Map) {
                      final laborMap = Map<String, dynamic>.from(item as Map);
                      // Handle the 'hourse' typo if present
                      if (laborMap.containsKey('hourse') &&
                          !laborMap.containsKey('hours')) {
                        laborMap['hours'] = laborMap['hourse'];
                        laborMap.remove('hourse');
                      }
                      laborList.add(laborMap);
                    } else {
                      // Skip invalid labor entries
                      print(
                        'Skipping invalid labor item in service ${serviceDoc.id}: $item',
                      );
                    }
                  }
                  processedServiceData['labor'] = laborList;
                } else {
                  processedServiceData['labor'] = [];
                }
              }

              final serviceRecord = ServiceRecordModel.fromMap(
                serviceDoc.id,
                processedServiceData,
              );

              // Skip if no parts or labor (empty service)
              if (serviceRecord.parts.isEmpty && serviceRecord.labor.isEmpty) {
                print(
                  'Skipping empty service record ${serviceRecord.id} for vehicle ${vehicle.carPlate}',
                );
                processedServices++;
                continue;
              }

              // Only process completed services
              if (serviceRecord.status != ServiceRecordModel.statusCompleted) {
                print(
                  'Skipping non-completed service record ${serviceRecord.id} (status: ${serviceRecord.status}) for vehicle ${vehicle.carPlate}',
                );
                processedServices++;
                continue;
              }

              // Create invoice using the existing addInvoice function with migration defaults
              final invoiceId = await _firestoreService.addInvoice(
                vehicleDoc.id,
                serviceRecord,
                vehicle.customerName,
                vehicle.carPlate,
                serviceRecord.mechanic,
                'System Migration', // createdBy
                customStatus: 'Approved', // Default to Approved for migration
                customPaymentStatus: 'Paid', // Default to Paid for migration
                customCreatedAt:
                    serviceRecord.updatedAt ??
                    serviceRecord
                        .date, // Use updatedAt if available, fallback to service date
              );

              createdInvoices++;
              processedServices++;
              successLogs.add(
                'Created invoice $invoiceId for service ${serviceRecord.id} (${vehicle.carPlate})',
              );
              print(
                'Created invoice $invoiceId for service ${serviceRecord.id} (${vehicle.carPlate})',
              );
            } catch (e) {
              failedInvoices++;
              processedServices++;
              errorLogs.add(
                'Failed to create invoice for service ${serviceDoc.id}: $e',
              );
              print(
                'Failed to create invoice for service ${serviceDoc.id}: $e',
              );
            }
          }

          processedVehicles++;
        } catch (e) {
          processedVehicles++;
          errorLogs.add('Failed to process vehicle ${vehicleDoc.id}: $e');
          print('Failed to process vehicle ${vehicleDoc.id}: $e');
        }
      }

      print(
        'Migration completed! Created $createdInvoices invoices, $failedInvoices failed',
      );
    } catch (e) {
      errorLogs.add('Migration failed: $e');
      print('Migration failed: $e');
    }

    return {
      'totalVehicles': totalVehicles,
      'processedVehicles': processedVehicles,
      'totalServices': totalServices,
      'processedServices': processedServices,
      'createdInvoices': createdInvoices,
      'failedInvoices': failedInvoices,
      'errorLogs': errorLogs,
      'successLogs': successLogs,
    };
  }
}
