class UserModel {
  final String id;
  final String username;
  final String email;
  final String profileImage;
  final String bio;
  final String status;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage = '',
    this.bio = '',
    this.status = 'Hey there! I am using Quick Chat',
    this.isOnline = false,
    this.lastSeen,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? '',
      bio: json['bio'] ?? '',
      status: json['status'] ?? 'Hey there! I am using Quick Chat',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen']) : null,
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'email': email,
        'profileImage': profileImage,
        'bio': bio,
        'status': status,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
        'isVerified': isVerified,
      };

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImage,
    String? bio,
    String? status,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
