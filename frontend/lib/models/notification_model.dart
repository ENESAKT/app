import 'package:flutter/foundation.dart';

/// Bildirim türleri
enum NotificationType {
  like,
  comment,
  follow,
  mention,
  storyReply,
  message;

  static NotificationType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      case 'story_reply':
        return NotificationType.storyReply;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.like;
    }
  }

  String get value {
    switch (this) {
      case NotificationType.storyReply:
        return 'story_reply';
      default:
        return name;
    }
  }

  /// Bildirimin Türkçe açıklaması
  String get description {
    switch (this) {
      case NotificationType.like:
        return 'gönderini beğendi';
      case NotificationType.comment:
        return 'yorum yaptı';
      case NotificationType.follow:
        return 'seni takip etmeye başladı';
      case NotificationType.mention:
        return 'senden bahsetti';
      case NotificationType.storyReply:
        return 'hikayene yanıt verdi';
      case NotificationType.message:
        return 'sana mesaj gönderdi';
    }
  }
}

/// Notification Model - Immutable
///
/// Bildirim yapısı:
/// - Like, comment, follow, mention türleri
/// - İlgili post/comment referansları
/// - Okundu durumu
@immutable
class NotificationModel {
  final String id;
  final String userId;
  final String actorId;
  final NotificationType type;
  final String? postId;
  final String? commentId;
  final bool isRead;
  final DateTime createdAt;

  // Actor bilgileri (bildirimi tetikleyen kullanıcı)
  final String? actorUsername;
  final String? actorAvatarUrl;

  // İlgili post önizlemesi (varsa)
  final String? postThumbnailUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.postId,
    this.commentId,
    this.isRead = false,
    required this.createdAt,
    this.actorUsername,
    this.actorAvatarUrl,
    this.postThumbnailUrl,
  });

  /// JSON'dan NotificationModel oluştur
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Actor bilgileri
    String? actorUsername;
    String? actorAvatarUrl;

    if (json['actor'] is Map) {
      final actor = json['actor'] as Map<String, dynamic>;
      actorUsername = actor['username'] as String?;
      actorAvatarUrl = actor['avatar_url'] as String?;
    }

    // Post thumbnail
    String? postThumbnailUrl;
    if (json['post'] is Map) {
      final post = json['post'] as Map<String, dynamic>;
      final mediaUrls = post['media_urls'] as List?;
      if (mediaUrls != null && mediaUrls.isNotEmpty) {
        postThumbnailUrl = mediaUrls.first as String?;
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: NotificationType.fromString(json['type'] as String?),
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actorUsername: actorUsername,
      actorAvatarUrl: actorAvatarUrl,
      postThumbnailUrl: postThumbnailUrl,
    );
  }

  /// NotificationModel'i JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'type': type.value,
      'post_id': postId,
      'comment_id': commentId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Immutable copy with pattern
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? actorId,
    NotificationType? type,
    String? postId,
    String? commentId,
    bool? isRead,
    DateTime? createdAt,
    String? actorUsername,
    String? actorAvatarUrl,
    String? postThumbnailUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actorUsername: actorUsername ?? this.actorUsername,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
      postThumbnailUrl: postThumbnailUrl ?? this.postThumbnailUrl,
    );
  }

  /// Bildirim mesajı
  String get message => '@${actorUsername ?? "Birisi"} ${type.description}';

  /// Post'a navigasyon gerekiyor mu?
  bool get hasPostContext => postId != null;

  /// Görüntüleme formatında zaman
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes}dk';
    if (difference.inHours < 24) return '${difference.inHours}sa';
    if (difference.inDays < 7) return '${difference.inDays}g';
    return '${(difference.inDays / 7).floor()}h';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NotificationModel(id: $id, type: ${type.value}, actor: $actorUsername)';
}
