import 'package:flutter/foundation.dart';

/// Comment Model - Immutable
///
/// Yorum yapısı:
/// - Parent-child ilişkisi (yanıtlar için)
/// - Beğeni sayısı
/// - Yazar bilgileri
@immutable
class CommentModel {
  final String id;
  final String userId;
  final String postId;
  final String? parentId;
  final String content;
  final int likeCount;
  final DateTime createdAt;

  // Author bilgileri
  final String? authorUsername;
  final String? authorAvatarUrl;

  // Kullanıcı etkileşim durumu
  final bool isLiked;

  // Alt yorumlar (replies)
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    this.parentId,
    required this.content,
    this.likeCount = 0,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
    this.isLiked = false,
    this.replies = const [],
  });

  /// JSON'dan CommentModel oluştur
  factory CommentModel.fromJson(Map<String, dynamic> json, {bool? isLiked}) {
    // Author bilgileri
    String? authorUsername;
    String? authorAvatarUrl;

    if (json['users'] is Map) {
      final user = json['users'] as Map<String, dynamic>;
      authorUsername = user['username'] as String?;
      authorAvatarUrl = user['avatar_url'] as String?;
    } else if (json['author'] is Map) {
      final author = json['author'] as Map<String, dynamic>;
      authorUsername = author['username'] as String?;
      authorAvatarUrl = author['avatar_url'] as String?;
    } else {
      authorUsername = json['author_username'] as String?;
      authorAvatarUrl = json['author_avatar_url'] as String?;
    }

    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      isLiked: isLiked ?? false,
    );
  }

  /// CommentModel'i JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'parent_id': parentId,
      'content': content,
      'like_count': likeCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Yeni yorum oluşturmak için JSON
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'post_id': postId,
      'parent_id': parentId,
      'content': content,
    };
  }

  /// Immutable copy with pattern
  CommentModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? parentId,
    String? content,
    int? likeCount,
    DateTime? createdAt,
    String? authorUsername,
    String? authorAvatarUrl,
    bool? isLiked,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }

  /// Yanıt mı kontrol et
  bool get isReply => parentId != null;

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
    return other is CommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CommentModel(id: $id, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
}
