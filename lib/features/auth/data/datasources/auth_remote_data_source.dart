import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> syncUserToFirestore(UserModel user);
  Future<UserModel?> getUserFromFirestore(String mobile);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseFirestore? firestore;

  AuthRemoteDataSourceImpl({this.firestore});

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> syncUserToFirestore(UserModel user) async {
    try {
      final docId = user.mobile;
      final payload = user.toJson();
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await _db
          .collection('users')
          .doc(docId)
          .set(payload, SetOptions(merge: true));
      debugPrint('[Firestore] User profile synced for: $docId');
    } catch (e) {
      debugPrint('[Firestore] syncUserToFirestore notice: $e');
    }
  }

  @override
  Future<UserModel?> getUserFromFirestore(String mobile) async {
    try {
      final doc = await _db.collection('users').doc(mobile).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('[Firestore] getUserFromFirestore notice: $e');
      return null;
    }
  }
}
