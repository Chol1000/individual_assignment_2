import 'package:flutter/material.dart';
import '../../data/models/message_model.dart';
import '../../data/models/chat_model.dart';
import '../../data/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  List<ChatModel> _userChats = [];
  List<MessageModel> _currentChatMessages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatModel> get chats => _userChats;
  List<ChatModel> get userChats => _userChats;
  List<MessageModel> get messages => _currentChatMessages;
  List<MessageModel> get currentChatMessages => _currentChatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToUserChats(String userId) {
    _chatService.getUserChats(userId).listen((chats) {
      _userChats = chats;
      notifyListeners();
    });
  }

  void listenToMessages(String chatId) {
    _chatService.getChatMessages(chatId).listen((messages) {
      _currentChatMessages = messages;
      notifyListeners();
    });
  }

  void listenToChatMessages(String chatId) {
    _chatService.getChatMessages(chatId).listen((messages) {
      _currentChatMessages = messages;
      notifyListeners();
    });
  }

  Future<String?> createOrGetChat({
    String? swapId,
    String? user1Id,
    String? user1Name,
    String? user2Id,
    String? user2Name,
    List<String>? participants,
    List<String>? participantNames,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      String? chatId;
      
      if (participants != null && participantNames != null) {
        // Direct user chat
        chatId = await _chatService.createDirectChat(
          participants: participants,
          participantNames: participantNames,
        );
      } else if (swapId != null && user1Id != null && user1Name != null && user2Id != null && user2Name != null) {
        // Swap-based chat
        chatId = await _chatService.createOrGetChat(
          swapId: swapId,
          user1Id: user1Id,
          user1Name: user1Name,
          user2Id: user2Id,
          user2Name: user2Name,
        );
      }
      
      _setLoading(false);
      return chatId;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<bool> sendMessage(
    String chatId,
    String senderId,
    String senderName,
    String message,
  ) async {
    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
      );
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void clearMessages() {
    _currentChatMessages = [];
    notifyListeners();
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


}