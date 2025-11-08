class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final bool emailVerified;
  final DateTime createdAt;
  final bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.emailVerified,
    required this.createdAt,
    this.notificationsEnabled = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      emailVerified: map['emailVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'emailVerified': emailVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  UserModel copyWith({
    String? name,
    String? profileImageUrl,
    bool? emailVerified,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}