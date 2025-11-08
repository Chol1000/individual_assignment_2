import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Individual chat screen for real-time messaging between two users.
/// Displays message history with WhatsApp-style bubbles and allows sending new messages.
/// Features profile pictures, timestamps, and automatic scrolling to latest messages.
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  /// Controller for the message input field
  final TextEditingController _messageController = TextEditingController();
  
  /// Controller for scrolling the messages list
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false)
          .listenToMessages(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            _buildAppBarAvatar(),
            const SizedBox(width: 8),
            Text(
              widget.otherUserName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }



  /// Builds the scrollable list of chat messages in reverse order (newest at bottom).
  /// Shows loading state and empty state when appropriate.
  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        final messages = chatProvider.messages;
        
        if (messages.isEmpty) {
          return _buildEmptyState();
        }



        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
            final isMe = message.senderId == currentUserId;
            
            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  /// Builds individual message bubble with different styling for sent/received messages.
  /// Includes timestamp and profile picture for received messages.
  Widget _buildMessageBubble(message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildOtherUserAvatar(message.senderId, message.senderName),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor : AppTheme.primaryDark,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: isMe ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.black54 : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the message input area with text field and send button.
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first message to ${widget.otherUserName}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Sends a new message to the chat and clears the input field.
  /// Validates message content and user authentication before sending.
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      _messageController.clear();
      
      await chatProvider.sendMessage(
        widget.chatId,
        authProvider.currentUser!.id,
        authProvider.currentUser!.name,
        message,
      );
    }
  }

  Widget _buildAppBarAvatar() {
    if (widget.otherUserId != null) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: _getUserProfile(widget.otherUserId!),
        builder: (context, snapshot) {
          final userProfile = snapshot.data;
          final profileImageUrl = userProfile?['profileImageUrl'] as String?;
          
          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            if (profileImageUrl.startsWith('assets/')) {
              return CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(profileImageUrl),
              );
            } else {
              return CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(profileImageUrl),
              );
            }
          }
          
          // Fallback to initials
          return CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          );
        },
      );
    }
    
    // Fallback when no user ID provided
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildOtherUserAvatar(String senderId, String senderName) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(senderId),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final profileImageUrl = userProfile?['profileImageUrl'] as String?;
        
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          if (profileImageUrl.startsWith('assets/')) {
            return CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(profileImageUrl),
            );
          } else {
            return CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(profileImageUrl),
            );
          }
        }
        
        // Fallback to initials
        return CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}