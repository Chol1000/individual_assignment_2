import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _notificationsEnabled = true;
  bool _emailUpdatesEnabled = true;
  List<Map<String, dynamic>> _notifications = [];

  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailUpdatesEnabled => _emailUpdatesEnabled;
  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> loadNotificationSettings() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      _notificationsEnabled = doc.data()?['notificationsEnabled'] ?? true;
      _emailUpdatesEnabled = doc.data()?['emailUpdatesEnabled'] ?? true;
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'notificationsEnabled': enabled,
      });
      _notificationsEnabled = enabled;
      notifyListeners();
    }
  }

  Future<void> toggleEmailUpdates(bool enabled) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'emailUpdatesEnabled': enabled,
      });
      _emailUpdatesEnabled = enabled;
      notifyListeners();
    }
  }

  void listenToNotifications() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
        _notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          data['time'] = data['createdAt']?.toDate() ?? DateTime.now();
          return data;
        }).toList();
        notifyListeners();
      });
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
      });
    }
  }
}