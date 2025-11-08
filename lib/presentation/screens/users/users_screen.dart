import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../chats/chat_screen.dart';
import '../../../data/services/firestore_service.dart';

/// Screen displaying all registered users for direct messaging.
/// Allows users to start conversations with any other user in the system.
/// Features user profile pictures and real-time user data.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      final users = await _firestoreService.getAllUsers();
      
      setState(() {
        _users = users.where((user) => user['id'] != currentUserId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: const Text(
          'Users',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _startChat(user),
                          leading: _buildUserAvatar(user),
                          title: Text(
                            user['name'] ?? 'Unknown User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            user['email'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _startChat(user),
                            icon: const Icon(Icons.chat_bubble_outline),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _startChat(Map<String, dynamic> otherUser) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Create or get existing chat
    final chatId = await chatProvider.createOrGetChat(
      participants: [currentUser.id, otherUser['id'] ?? ''],
      participantNames: [currentUser.name, otherUser['name'] ?? 'Unknown User'],
    );

    if (chatId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: otherUser['name'] ?? 'Unknown User',
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat')),
        );
      }
    }
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final profileImageUrl = user['profileImageUrl'] as String?;
    
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      if (profileImageUrl.startsWith('assets/')) {
        // Asset image
        return CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage(profileImageUrl),
          onBackgroundImageError: (exception, stackTrace) {
            // Fallback to initials if asset fails to load
          },
          child: profileImageUrl.startsWith('assets/') ? null : Text(
            user['name']?.isNotEmpty == true ? user['name'][0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      } else {
        // Network image
        return CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(profileImageUrl),
          onBackgroundImageError: (exception, stackTrace) {
            // Fallback to initials if network image fails to load
          },
        );
      }
    }
    
    // Fallback to initials
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.primaryDark,
      child: Text(
        user['name']?.isNotEmpty == true ? user['name'][0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}