import 'package:flutter/foundation.dart';

/// Story media türleri
enum StoryMediaType {
  image,
  video;

  static StoryMediaType fromString(String? value) {
    return value?.toLowerCase() == 'video'
        ? StoryMediaType.video
        : StoryMediaType.image;
  }

  String get value => name;
}

/// Story Model - Immutable
///
/// 24 saatlik story yapısı:
/// - Otomatik süre dolumu
/// - Görüntülenme sayısı
/// - Görüntüleyenler listesi
@immutable
class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final int viewCount;
  final DateTime expiresAt;
  final DateTime createdAt;

  // Author bilgileri
  final String? authorUsername;
  final String? authorAvatarUrl;

  // Kullanıcı durumu
  final bool isViewed;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    this.mediaType = StoryMediaType.image,
    this.viewCount = 0,
    required this.expiresAt,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.isViewed = false,
  });

  /// JSON'dan StoryModel oluştur
  factory StoryModel.fromJson(Map<String, dynamic> json, {bool? isViewed}) {
    // Author bilgileri
    String? authorUsername;
    String? authorAvatarUrl;

    if (json['users'] is Map) {
      final user = json['users'] as Map<String, dynamic>;
      authorUsername = user['username'] as String?;
      authorAvatarUrl = user['avatar_url'] as String?;
    }

    return StoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: json['media_url'] as String,
      mediaType: StoryMediaType.fromString(json['media_type'] as String?),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      isViewed: isViewed ?? false,
    );
  }

  /// StoryModel'i JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType.value,
      'view_count': viewCount,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Yeni story oluşturmak için JSON
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType.value,
    };
  }

  /// Immutable copy with pattern
  StoryModel copyWith({
    String? id,
    String? userId,
    String? mediaUrl,
    StoryMediaType? mediaType,
    int? viewCount,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? authorUsername,
    String? authorAvatarUrl,
    bool? isViewed,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      viewCount: viewCount ?? this.viewCount,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  /// Story süresi dolmuş mu?
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Kalan süre (saniye)
  int get remainingSeconds {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Kalan süre yüzdesi (0.0 - 1.0)
  double get remainingPercentage {
    const totalDuration = 24 * 60 * 60; // 24 saat
    return remainingSeconds / totalDuration;
  }

  /// Ne kadar önce oluşturuldu
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 60) return '${difference.inMinutes}dk';
    return '${difference.inHours}sa';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StoryModel(id: $id, author: $authorUsername, expired: $isExpired)';
}

/// Bir kullanıcının tüm story'lerini gruplar
@immutable
class UserStories {
  final String userId;
  final String? username;
  final String? avatarUrl;
  final List<StoryModel> stories;
  final bool hasUnviewed;

  const UserStories({
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.stories,
    this.hasUnviewed = false,
  });

  /// En son story
  StoryModel? get latestStory => stories.isNotEmpty ? stories.last : null;

  /// Toplam story sayısı
  int get count => stories.length;

  /// Görüntülenmemiş story sayısı
  int get unviewedCount => stories.where((s) => !s.isViewed).length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStories && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
