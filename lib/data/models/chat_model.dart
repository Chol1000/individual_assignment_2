class ChatModel {
  final String id;
  final List<String> participants;
  final List<String> participantNames;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? swapId;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageTime,
    this.swapId,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: List<String>.from(map['participantNames'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      swapId: map['swapId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      if (swapId != null) 'swapId': swapId,
    };
  }
}