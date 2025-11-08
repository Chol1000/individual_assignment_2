import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHandler extends StatefulWidget {
  final Widget child;
  
  const NotificationHandler({
    super.key,
    required this.child,
  });

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showInAppNotification(message.notification!);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  void _showInAppNotification(RemoteNotification notification) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (notification.body != null) ...[
              const SizedBox(height: 4),
              Text(
                notification.body!,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF667EEA),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to appropriate screen based on notification type
          },
        ),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification data
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'swap_request':
      case 'swap_status':
        // Navigate to My Books screen
        break;
      case 'chat_message':
        // Navigate to Chats screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}