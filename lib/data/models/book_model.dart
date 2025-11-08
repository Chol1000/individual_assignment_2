class BookModel {
  final String id;
  final String title;
  final String author;
  final String condition;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final bool isAvailable;
  final List<String>? pendingRequests;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.isAvailable = true,
    this.pendingRequests,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      condition: map['condition'] ?? '',
      imageUrl: map['imageUrl'],
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isAvailable: map['isAvailable'] ?? true,
      pendingRequests: map['pendingRequests'] != null ? List<String>.from(map['pendingRequests']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isAvailable': isAvailable,
    };
  }

  BookModel copyWith({
    String? title,
    String? author,
    String? condition,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return BookModel(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId,
      ownerName: ownerName,
      createdAt: createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}