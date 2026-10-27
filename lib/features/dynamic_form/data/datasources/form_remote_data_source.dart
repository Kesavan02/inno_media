import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

abstract class FormRemoteDataSource {
  Future<void> submitFormToFirestore(Map<String, dynamic> submission);
  Future<List<Map<String, dynamic>>> getFirestoreSubmissions();
  Future<String?> getRemoteFormSchema(String schemaId);
  Future<void> saveRemoteFormSchema(String schemaId, String title, String jsonString);
}

class FormRemoteDataSourceImpl implements FormRemoteDataSource {
  final FirebaseFirestore? firestore;

  FormRemoteDataSourceImpl({this.firestore});

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitFormToFirestore(Map<String, dynamic> submission) async {
    try {
      final docId = submission['id'] as String? ??
          'sub_${DateTime.now().millisecondsSinceEpoch}';

      final firestorePayload = Map<String, dynamic>.from(submission);
      firestorePayload['syncedAt'] = FieldValue.serverTimestamp();

      await _db
          .collection('form_submissions')
          .doc(docId)
          .set(firestorePayload, SetOptions(merge: true));
      debugPrint('[Firestore] Form submission synced successfully: $docId');
    } catch (e) {
      debugPrint('[Firestore] submitFormToFirestore notice: $e');
      // Non-blocking: local persistence remains intact
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFirestoreSubmissions() async {
    try {
      final snapshot = await _db
          .collection('form_submissions')
          .orderBy('submittedAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('[Firestore] getFirestoreSubmissions notice: $e');
      return [];
    }
  }

  @override
  Future<String?> getRemoteFormSchema(String schemaId) async {
    try {
      final doc = await _db.collection('form_schemas').doc(schemaId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['rawJson'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('[Firestore] getRemoteFormSchema notice: $e');
      return null;
    }
  }

  @override
  Future<void> saveRemoteFormSchema(
      String schemaId, String title, String jsonString) async {
    try {
      await _db.collection('form_schemas').doc(schemaId).set({
        'id': schemaId,
        'title': title,
        'rawJson': jsonString,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[Firestore] Form schema $schemaId synced to Firestore');
    } catch (e) {
      debugPrint('[Firestore] saveRemoteFormSchema notice: $e');
    }
  }
}
