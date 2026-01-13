import 'package:flutter/foundation.dart';

/// Post media türleri
enum MediaType {
  image,
  video,
  carousel;

  static MediaType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'carousel':
        return MediaType.carousel;
      default:
        return MediaType.image;
    }
  }

  String get value => name;
}

/// Post Model - Immutable, thread-safe
///
/// Instagram benzeri post yapısı:
/// - Tek veya çoklu medya desteği (carousel)
/// - Like, comment, save durumları
/// - Kullanıcı bilgileri (author)
@immutable
class PostModel {
  final String id;
  final String userId;
  final String? caption;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final String? location;
  final int likeCount;
  final int commentCount;
  final bool isArchived;
  final DateTime createdAt;

  // Author bilgileri (join ile gelir)
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool? authorIsVerified;

  // Kullanıcı etkileşim durumları
  final bool isLiked;
  final bool isSaved;

  const PostModel({
    required this.id,
    required this.userId,
    this.caption,
    required this.mediaUrls,
    this.mediaType = MediaType.image,
    this.location,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isArchived = false,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.authorIsVerified,
    this.isLiked = false,
    this.isSaved = false,
  });

  /// JSON'dan PostModel oluştur
  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    bool? isLiked,
    bool? isSaved,
  }) {
    // Media URLs - tek string veya array olabilir
    List<String> mediaUrls = [];
    if (json['media_urls'] is List) {
      mediaUrls = List<String>.from(json['media_urls'] ?? []);
    } else if (json['media_url'] != null) {
      mediaUrls = [json['media_url'] as String];
    }

    // Author bilgileri - nested object veya flat olabilir
    String? authorUsername;
    String? authorAvatarUrl;
    bool? authorIsVerified;

    if (json['author'] is Map) {
      final author = json['author'] as Map<String, dynamic>;
      authorUsername = author['username'] as String?;
      authorAvatarUrl = author['avatar_url'] as String?;
      authorIsVerified = author['is_verified'] as bool?;
    } else if (json['users'] is Map) {
      // Supabase join formatı
      final user = json['users'] as Map<String, dynamic>;
      authorUsername = user['username'] as String?;
      authorAvatarUrl = user['avatar_url'] as String?;
      authorIsVerified = user['is_verified'] as bool?;
    } else {
      authorUsername = json['author_username'] as String?;
      authorAvatarUrl = json['author_avatar_url'] as String?;
      authorIsVerified = json['author_is_verified'] as bool?;
    }

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      caption: json['caption'] as String?,
      mediaUrls: mediaUrls,
      mediaType: MediaType.fromString(json['media_type'] as String?),
      location: json['location'] as String?,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      authorIsVerified: authorIsVerified,
      isLiked: isLiked ?? false,
      isSaved: isSaved ?? false,
    );
  }

  /// PostModel'i JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'caption': caption,
      'media_urls': mediaUrls,
      'media_type': mediaType.value,
      'location': location,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Yeni post oluşturmak için JSON (id ve timestamp hariç)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'caption': caption,
      'media_urls': mediaUrls,
      'media_type': mediaType.value,
      'location': location,
    };
  }

  /// Immutable copy with pattern
  PostModel copyWith({
    String? id,
    String? userId,
    String? caption,
    List<String>? mediaUrls,
    MediaType? mediaType,
    String? location,
    int? likeCount,
    int? commentCount,
    bool? isArchived,
    DateTime? createdAt,
    String? authorUsername,
    String? authorAvatarUrl,
    bool? authorIsVerified,
    bool? isLiked,
    bool? isSaved,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      caption: caption ?? this.caption,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      location: location ?? this.location,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  /// Carousel mı kontrol et
  bool get isCarousel => mediaUrls.length > 1;

  /// İlk medya URL'i
  String? get primaryMediaUrl => mediaUrls.isNotEmpty ? mediaUrls.first : null;

  /// Görüntüleme formatında zaman (örn: "2 saat önce")
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes}dk';
    if (difference.inHours < 24) return '${difference.inHours}sa';
    if (difference.inDays < 7) return '${difference.inDays}g';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}h';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}ay';
    return '${(difference.inDays / 365).floor()}y';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PostModel(id: $id, author: $authorUsername)';
}
