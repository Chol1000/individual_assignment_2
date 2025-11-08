import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isEmailVerified => FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null && user.emailVerified) {
      // Check if Firestore needs to be updated
      await _authService.syncEmailVerificationStatus(user.uid, user.emailVerified);
      _currentUser = await _authService.getCurrentUserData();
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      
      if (user != null) {
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn(
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _authService.updateUserData(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  Future<void> checkEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.emailVerified) {
          // Update Firestore document to reflect email verification
          await _authService.updateEmailVerificationStatus(user.uid, true);
          _currentUser = await _authService.getCurrentUserData();
          notifyListeners();
        } else {
          _setError('Email not yet verified. Please check your email and click the verification link.');
        }
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> refreshUser() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        _currentUser = await _authService.getCurrentUserData();
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }
}