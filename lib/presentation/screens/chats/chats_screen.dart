import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'chat_screen.dart';
import '../users/users_screen.dart';
import '../notifications/notifications_screen.dart';
import 'package:intl/intl.dart';

/// Screen displaying all chat conversations for the current user.
/// Shows list of active chats with other users, including last message preview.
/// Provides navigation to individual chat screens and user profiles.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        Provider.of<ChatProvider>(context, listen: false)
            .listenToUserChats(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.notifications
                  .where((n) => n['read'] != true)
                  .length;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildChatsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
    );
  }



  Widget _buildChatsList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Don't show loading spinner, just show empty state or chats
        // if (chatProvider.chats.isEmpty && chatProvider.error == null) {
        //   return const Center(
        //     child: CircularProgressIndicator(
        //       valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        //     ),
        //   );
        // }

        if (chatProvider.chats.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chatProvider.chats.length,
          itemBuilder: (context, index) {
            final chat = chatProvider.chats[index];
            final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
            final currentUserName = Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? '';
            
            final otherUserId = chat.participants.isNotEmpty
                ? chat.participants.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => chat.participants.first,
                  )
                : '';
            
            final otherUserName = chat.participantNames.isNotEmpty
                ? chat.participantNames.firstWhere(
                    (name) => name != currentUserName,
                    orElse: () => chat.participantNames.first,
                  )
                : 'Unknown User';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildChatItem(chat, otherUserId, otherUserName),
            );
          },
        );
      },
    );
  }

  Widget _buildChatItem(chat, String otherUserId, String otherUserName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chat.id,
                  otherUserName: otherUserName,
                  otherUserId: otherUserId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildChatAvatar(otherUserId, otherUserName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat.lastMessage ?? 'Tap to start chatting',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chat.lastMessage != null ? AppTheme.textSecondary : Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (chat.lastMessageTime != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(chat.lastMessageTime!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (chat.lastMessage != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Icon(Icons.chat_bubble_outline, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No chats yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          Text('Chats will appear after swap requests', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      // Today - show time
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(time);
    } else {
      // Older - show date
      return DateFormat('dd/MM/yy').format(time);
    }
  }

  Widget _buildChatAvatar(String userId, String userName) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(userId),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final profileImageUrl = userProfile?['profileImageUrl'] as String?;
        
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          if (profileImageUrl.startsWith('assets/')) {
            return CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(profileImageUrl),
            );
          } else {
            return CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(profileImageUrl),
            );
          }
        }
        
        // Fallback to gradient avatar with initials
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primaryDark.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}