import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/chats/chat_screen.dart';
import '../../core/theme/app_theme.dart';

class UserProfileModal extends StatelessWidget {
  final String userId;
  final String userName;

  const UserProfileModal({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // User profile content
            FutureBuilder<Map<String, dynamic>?>(
              future: _getUserProfile(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                final userProfile = snapshot.data;
                final profileImageUrl = userProfile?['profileImageUrl'] as String?;
                final email = userProfile?['email'] as String? ?? '';
                final emailVerified = userProfile?['emailVerified'] as bool? ?? false;

                return Column(
                  children: [
                    // Profile picture
                    _buildProfilePicture(profileImageUrl),
                    const SizedBox(height: 16),
                    
                    // User name
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Email
                    if (email.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (emailVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Message button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startChat(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.message, size: 20),
                        label: const Text(
                          'Send Message',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(String? profileImageUrl) {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      if (profileImageUrl.startsWith('assets/')) {
        return CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(profileImageUrl),
        );
      } else {
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(profileImageUrl),
        );
      }
    }
    
    // Fallback to initials
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  Future<void> _startChat(BuildContext context) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    // Don't allow chatting with yourself
    if (currentUser.id == userId) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message yourself!")),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Create or get existing chat
    final chatId = await chatProvider.createOrGetChat(
      participants: [currentUser.id, userId],
      participantNames: [currentUser.name, userName],
    );

    if (chatId != null && context.mounted) {
      Navigator.pop(context); // Close modal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: userName,
            otherUserId: userId,
          ),
        ),
      );
    } else {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat')),
        );
      }
    }
  }
}