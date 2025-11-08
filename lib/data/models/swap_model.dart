class SwapModel {
  final String id;
  final String targetBookId;
  final String targetBookTitle;
  final String targetBookAuthor;
  final String targetBookCondition;
  final String targetBookImageUrl;
  final String offeredBookId;
  final String offeredBookTitle;
  final String offeredBookAuthor;
  final String offeredBookCondition;
  final String offeredBookImageUrl;
  final String requesterId;
  final String requesterName;
  final String ownerId;
  final String ownerName;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SwapModel({
    required this.id,
    required this.targetBookId,
    required this.targetBookTitle,
    required this.targetBookAuthor,
    required this.targetBookCondition,
    required this.targetBookImageUrl,
    required this.offeredBookId,
    required this.offeredBookTitle,
    required this.offeredBookAuthor,
    required this.offeredBookCondition,
    required this.offeredBookImageUrl,
    required this.requesterId,
    required this.requesterName,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory SwapModel.fromMap(Map<String, dynamic> map, String id) {
    return SwapModel(
      id: id,
      targetBookId: map['targetBookId'] ?? '',
      targetBookTitle: map['targetBookTitle'] ?? '',
      targetBookAuthor: map['targetBookAuthor'] ?? '',
      targetBookCondition: map['targetBookCondition'] ?? '',
      targetBookImageUrl: map['targetBookImageUrl'] ?? '',
      offeredBookId: map['offeredBookId'] ?? '',
      offeredBookTitle: map['offeredBookTitle'] ?? '',
      offeredBookAuthor: map['offeredBookAuthor'] ?? '',
      offeredBookCondition: map['offeredBookCondition'] ?? '',
      offeredBookImageUrl: map['offeredBookImageUrl'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      status: map['status'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetBookId': targetBookId,
      'targetBookTitle': targetBookTitle,
      'targetBookAuthor': targetBookAuthor,
      'targetBookCondition': targetBookCondition,
      'targetBookImageUrl': targetBookImageUrl,
      'offeredBookId': offeredBookId,
      'offeredBookTitle': offeredBookTitle,
      'offeredBookAuthor': offeredBookAuthor,
      'offeredBookCondition': offeredBookCondition,
      'offeredBookImageUrl': offeredBookImageUrl,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  SwapModel copyWith({
    String? status,
    DateTime? updatedAt,
  }) {
    return SwapModel(
      id: id,
      targetBookId: targetBookId,
      targetBookTitle: targetBookTitle,
      targetBookAuthor: targetBookAuthor,
      targetBookCondition: targetBookCondition,
      targetBookImageUrl: targetBookImageUrl,
      offeredBookId: offeredBookId,
      offeredBookTitle: offeredBookTitle,
      offeredBookAuthor: offeredBookAuthor,
      offeredBookCondition: offeredBookCondition,
      offeredBookImageUrl: offeredBookImageUrl,
      requesterId: requesterId,
      requesterName: requesterName,
      ownerId: ownerId,
      ownerName: ownerName,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}