class UserModel {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? city;
  final String? bio;
  final List<String>? interests;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.age,
    this.city,
    this.bio,
    this.interests,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName!;
    }
    return username;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      age: json['age'],
      city: json['city'],
      bio: json['bio'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'age': age,
      'city': city,
      'bio': bio,
      'interests': interests,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}
