import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.sendEmailVerification();
        
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          emailVerified: false,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        return userModel;
      }
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
    return null;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        if (!credential.user!.emailVerified) {
          throw Exception('Please verify your email before signing in');
        }

        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data()!, credential.user!.uid);
        }
      }
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!, user.uid);
      }
    }
    return null;
  }

  Future<void> updateUserData(UserModel userModel) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userModel.id)
        .update(userModel.toMap());
  }

  Future<void> updateEmailVerificationStatus(String userId, bool isVerified) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'emailVerified': isVerified});
  }

  Future<void> syncEmailVerificationStatus(String userId, bool authVerified) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final firestoreVerified = userData['emailVerified'] ?? false;
        
        // If Firebase Auth says verified but Firestore says not verified, update Firestore
        if (authVerified && !firestoreVerified) {
          await updateEmailVerificationStatus(userId, true);
        }
      }
    } catch (e) {
      print('Error syncing email verification: $e');
    }
  }
}