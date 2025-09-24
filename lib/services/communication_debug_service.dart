import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/communication_model.dart';

class CommunicationDebugService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'communications';

  // Test basic Firestore connection
  Future<bool> testConnection() async {
    try {
      // Try to read any document from any collection
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  // Test if communications collection exists and has data
  Future<Map<String, dynamic>> testCommunicationsCollection() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collectionName).limit(5).get();
      
      return {
        'success': true,
        'documentCount': snapshot.docs.length,
        'collectionExists': true,
        'sampleData': snapshot.docs.isNotEmpty 
            ? snapshot.docs.first.data() 
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'collectionExists': false,
      };
    }
  }

  // Test specific customer communications query
  Future<Map<String, dynamic>> testCustomerQuery(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('customerId', isEqualTo: customerId)
          .get();
      
      return {
        'success': true,
        'documentCount': snapshot.docs.length,
        'customerId': customerId,
        'documents': snapshot.docs.map((doc) => {
          'id': doc.id,
          'data': doc.data(),
        }).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'customerId': customerId,
      };
    }
  }

  // Simplified stream without orderBy (which might require an index)
  Stream<List<CommunicationModel>> getCustomerCommunicationsSimple(String customerId) {
    return _firestore
        .collection(_collectionName)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      try {
        print('Snapshot received with ${snapshot.docs.length} documents');
        return snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            print('Processing document ${doc.id}: $data');
            return CommunicationModel.fromMap(doc.id, data);
          } catch (e) {
            print('Error parsing document ${doc.id}: $e');
            return null;
          }
        }).where((comm) => comm != null).cast<CommunicationModel>().toList();
      } catch (e) {
        print('Error processing snapshot: $e');
        return <CommunicationModel>[];
      }
    }).handleError((error) {
      print('Stream error: $error');
    });
  }

  // Create a sample communication for testing
  Future<String?> createSampleCommunication(String customerId, String customerName) async {
    try {
      CommunicationModel sample = CommunicationModel(
        id: '', // Will be set by Firestore
        customerId: customerId,
        customerName: customerName,
        type: CommunicationType.note,
        subject: 'Test Communication',
        description: 'This is a test communication created for debugging.',
        status: CommunicationStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachments: [],
      );

      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(sample.toMap());
      
      print('Sample communication created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating sample communication: $e');
      return null;
    }
  }
}