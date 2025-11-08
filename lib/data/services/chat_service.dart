import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort by lastMessageTime, putting chats with messages first
          chats.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
          
          return chats;
        });
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> createOrGetChat({
    required String swapId,
    required String user1Id,
    required String user1Name,
    required String user2Id,
    required String user2Name,
  }) async {
    try {
      // Check if chat already exists for this swap
      final existingChat = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('swapId', isEqualTo: swapId)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chat = ChatModel(
        id: '',
        participants: [user1Id, user2Id],
        participantNames: [user1Name, user2Name],
        swapId: swapId,
      );

      final docRef = await _firestore
          .collection(AppConstants.chatsCollection)
          .add(chat.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Future<String> createDirectChat({
    required List<String> participants,
    required List<String> participantNames,
  }) async {
    try {
      // Check if chat already exists between these users
      final existingChat = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('participants', arrayContains: participants[0])
          .get();

      for (final doc in existingChat.docs) {
        final data = doc.data();
        final chatParticipants = List<String>.from(data['participants'] ?? []);
        if (chatParticipants.length == 2 && 
            chatParticipants.contains(participants[1]) &&
            data['swapId'] == null) {
          return doc.id;
        }
      }

      // Create new direct chat
      final chat = ChatModel(
        id: '',
        participants: participants,
        participantNames: participantNames,
      );

      final docRef = await _firestore
          .collection(AppConstants.chatsCollection)
          .add(chat.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create direct chat: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    try {
      final messageModel = MessageModel(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .collection(AppConstants.messagesCollection)
          .add(messageModel.toMap());

      // Update chat's last message
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({
        'lastMessage': message,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });

      // Get chat participants to send notification to other user
      final chatDoc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();
      
      if (chatDoc.exists) {
        final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
        final targetUserId = participants.firstWhere((id) => id != senderId, orElse: () => '');
        
        if (targetUserId.isNotEmpty) {
          await NotificationService.addLocalNotification(
            userId: targetUserId,
            title: 'New message from $senderName',
            body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
            type: 'chat_message',
            data: {
              'chatId': chatId,
              'senderName': senderName,
            },
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}