import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  static Future<void> createUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.id).set(user.toMap());
  }

  static Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(userId).update(data);
  }

  static Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }
}