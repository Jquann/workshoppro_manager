import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/communication_model.dart';

class CommunicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'communications';

  // Create a new communication record
  Future<String> createCommunication(CommunicationModel communication) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(communication.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create communication: $e');
    }
  }

  // Get communications for a specific customer with improved error handling
  Stream<List<CommunicationModel>> getCustomerCommunications(String customerId) {
    print('Setting up communication stream for customer: $customerId');
    
    try {
      // First try without orderBy to avoid index issues
      return _firestore
          .collection(_collectionName)
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
        try {
          print('Received snapshot with ${snapshot.docs.length} documents');
          List<CommunicationModel> communications = [];
          
          for (var doc in snapshot.docs) {
            try {
              print('Processing document ${doc.id}');
              final communication = CommunicationModel.fromMap(doc.id, doc.data());
              communications.add(communication);
            } catch (e) {
              print('Error parsing document ${doc.id}: $e');
              print('Document data: ${doc.data()}');
            }
          }
          
          // Sort in memory instead of using Firestore orderBy
          communications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('Successfully processed ${communications.length} communications');
          return communications;
        } catch (e) {
          print('Error processing snapshot: $e');
          return <CommunicationModel>[];
        }
      }).handleError((error) {
        print('Stream error: $error');
        throw error;
      });
    } catch (e) {
      print('Error setting up communication stream: $e');
      return Stream.value(<CommunicationModel>[]);
    }
  }

  // Get all communications
  Stream<List<CommunicationModel>> getAllCommunications() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunicationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get communications by type
  Stream<List<CommunicationModel>> getCommunicationsByType(CommunicationType type) {
    return _firestore
        .collection(_collectionName)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunicationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get communications by status
  Stream<List<CommunicationModel>> getCommunicationsByStatus(CommunicationStatus status) {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunicationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get pending follow-ups
  Stream<List<CommunicationModel>> getPendingFollowUps() {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: CommunicationStatus.followUp.name)
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunicationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update communication
  Future<void> updateCommunication(String communicationId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(communicationId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update communication: $e');
    }
  }

  // Update communication status
  Future<void> updateCommunicationStatus(String communicationId, CommunicationStatus status) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(communicationId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update communication status: $e');
    }
  }

  // Delete communication
  Future<void> deleteCommunication(String communicationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(communicationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete communication: $e');
    }
  }

  // Get communication statistics for a customer
  Future<Map<String, int>> getCustomerCommunicationStats(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('customerId', isEqualTo: customerId)
          .get();

      Map<String, int> stats = {
        'total': 0,
        'phone': 0,
        'email': 0,
        'meeting': 0,
        'completed': 0,
        'pending': 0,
        'followUp': 0,
      };

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        stats['total'] = stats['total']! + 1;
        
        String type = data['type'] ?? '';
        String status = data['status'] ?? '';
        
        if (stats.containsKey(type)) {
          stats[type] = stats[type]! + 1;
        }
        
        if (stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get communication stats: $e');
    }
  }

  // Search communications
  Future<List<CommunicationModel>> searchCommunications(String query, {String? customerId}) async {
    try {
      Query queryRef = _firestore.collection(_collectionName);
      
      if (customerId != null) {
        queryRef = queryRef.where('customerId', isEqualTo: customerId);
      }
      
      QuerySnapshot snapshot = await queryRef
          .orderBy('createdAt', descending: true)
          .get();

      List<CommunicationModel> communications = snapshot.docs
          .map((doc) => CommunicationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((comm) {
            String searchText = '${comm.subject} ${comm.description} ${comm.customerName}'.toLowerCase();
            return searchText.contains(query.toLowerCase());
          })
          .toList();

      return communications;
    } catch (e) {
      throw Exception('Failed to search communications: $e');
    }
  }

  // Get recent communications (last 7 days)
  Stream<List<CommunicationModel>> getRecentCommunications({int days = 7}) {
    DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return _firestore
        .collection(_collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunicationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get communication count for a customer
  Future<int> getCustomerCommunicationCount(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('customerId', isEqualTo: customerId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting communication count: $e');
      return 0;
    }
  }

  // Test basic Firestore connectivity
  Future<Map<String, dynamic>> testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      
      // Test 1: Basic connectivity
      await _firestore.collection('test').limit(1).get();
      print('✓ Basic Firestore connection successful');
      
      // Test 2: Check if communications collection exists
      QuerySnapshot snapshot = await _firestore.collection(_collectionName).limit(1).get();
      print('✓ Communications collection accessible, found ${snapshot.docs.length} documents');
      
      // Test 3: Try to get all communications (no filters)
      QuerySnapshot allComms = await _firestore.collection(_collectionName).get();
      print('✓ All communications query successful, found ${allComms.docs.length} total documents');
      
      return {
        'success': true,
        'totalCommunications': allComms.docs.length,
        'collectionExists': true,
      };
    } catch (e) {
      print('✗ Firestore connection test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Create a test communication
  Future<String?> createTestCommunication(String customerId, String customerName) async {
    try {
      print('Creating test communication...');
      
      Map<String, dynamic> testData = {
        'customerId': customerId,
        'customerName': customerName,
        'type': 'note',
        'subject': 'Test Communication',
        'description': 'This is a test communication to verify the system is working.',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'attachments': [],
      };

      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(testData);
      
      print('✓ Test communication created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('✗ Failed to create test communication: $e');
      return null;
    }
  }
}