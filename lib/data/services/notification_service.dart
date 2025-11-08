import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add local notification to user's notification collection
  static Future<void> addLocalNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding local notification: $e');
    }
  }

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token and save to user document
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
    });
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }

  // Send notification for new swap request
  static Future<void> sendSwapRequestNotification({
    required String targetUserId,
    required String requesterName,
    required String bookTitle,
  }) async {
    await _sendNotification(
      targetUserId: targetUserId,
      title: 'New Swap Request',
      body: '$requesterName wants to swap for "$bookTitle"',
      data: {'type': 'swap_request'},
    );
  }

  // Send notification for swap status update
  static Future<void> sendSwapStatusNotification({
    required String targetUserId,
    required String status,
    required String bookTitle,
  }) async {
    final statusText = status == 'accepted' ? 'accepted' : 'rejected';
    await _sendNotification(
      targetUserId: targetUserId,
      title: 'Swap $statusText',
      body: 'Your swap request for "$bookTitle" was $statusText',
      data: {'type': 'swap_status', 'status': status},
    );
  }

  // Send notification for new chat message
  static Future<void> sendChatMessageNotification({
    required String targetUserId,
    required String senderName,
    required String message,
  }) async {
    await _sendNotification(
      targetUserId: targetUserId,
      title: 'New message from $senderName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      data: {'type': 'chat_message'},
    );
  }

  static Future<void> _sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // Get target user's FCM token
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken != null) {
        // Store notification in Firestore for Firebase Functions to send
        await _firestore.collection('notifications').add({
          'targetUserId': targetUserId,
          'fcmToken': fcmToken,
          'title': title,
          'body': body,
          'data': data,
          'createdAt': FieldValue.serverTimestamp(),
          'sent': false,
        });
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}