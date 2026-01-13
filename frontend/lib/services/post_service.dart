import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

/// Post Service - CRUD operations for posts, likes, comments, saves
///
/// Single Responsibility: Post ve ilgili işlemleri yönetir
/// Dependency Injection: Supabase client constructor'dan alınabilir
class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ==================== FEED ====================

  /// Ana feed'i getir (takip edilenler + kendi postları)
  /// Sayfalama destekli
  Future<List<PostModel>> getFeed({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // 1. Takip edilenlerin ID'lerini al
      final followingResponse = await _client
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (followingResponse as List)
          .map((f) => f['following_id'] as String)
          .toList();

      // Kendini de ekle
      followingIds.add(userId);

      // 2. Bu kullanıcıların postlarını al
      final postsResponse = await _client
          .from('posts')
          .select(
            '*, users!posts_user_id_fkey(username, avatar_url, is_verified)',
          )
          .inFilter('user_id', followingIds)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // 3. Beğeni ve kaydetme durumlarını al
      final posts = await _enrichPostsWithUserState(
        postsResponse as List,
        userId,
      );

      return posts;
    } catch (e) {
      print('❌ getFeed error: $e');
      return [];
    }
  }

  /// Keşfet sayfası için popüler postlar
  Future<List<PostModel>> getExplorePosts({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('posts')
          .select(
            '*, users!posts_user_id_fkey(username, avatar_url, is_verified)',
          )
          .eq('is_archived', false)
          .order('like_count', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getExplorePosts error: $e');
      return [];
    }
  }

  /// Kullanıcının postlarını getir
  Future<List<PostModel>> getUserPosts({
    required String userId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('posts')
          .select(
            '*, users!posts_user_id_fkey(username, avatar_url, is_verified)',
          )
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getUserPosts error: $e');
      return [];
    }
  }

  /// Tek bir post getir
  Future<PostModel?> getPost(String postId, {String? currentUserId}) async {
    try {
      final response = await _client
          .from('posts')
          .select(
            '*, users!posts_user_id_fkey(username, avatar_url, is_verified)',
          )
          .eq('id', postId)
          .single();

      if (currentUserId != null) {
        final posts = await _enrichPostsWithUserState([
          response,
        ], currentUserId);
        return posts.isNotEmpty ? posts.first : null;
      }

      return PostModel.fromJson(response);
    } catch (e) {
      print('❌ getPost error: $e');
      return null;
    }
  }

  // ==================== POST CRUD ====================

  /// Yeni post oluştur
  Future<PostModel?> createPost({
    required String userId,
    required List<String> mediaUrls,
    String? caption,
    String? location,
    MediaType mediaType = MediaType.image,
  }) async {
    try {
      final response = await _client
          .from('posts')
          .insert({
            'user_id': userId,
            'media_urls': mediaUrls,
            'media_type': mediaType.value,
            'caption': caption,
            'location': location,
          })
          .select(
            '*, users!posts_user_id_fkey(username, avatar_url, is_verified)',
          )
          .single();

      print('✅ Post oluşturuldu: ${response['id']}');
      return PostModel.fromJson(response);
    } catch (e) {
      print('❌ createPost error: $e');
      return null;
    }
  }

  /// Post sil
  Future<bool> deletePost(String postId) async {
    try {
      await _client.from('posts').delete().eq('id', postId);
      print('✅ Post silindi: $postId');
      return true;
    } catch (e) {
      print('❌ deletePost error: $e');
      return false;
    }
  }

  /// Post arşivle/arşivden çıkar
  Future<bool> toggleArchive(String postId, bool archive) async {
    try {
      await _client
          .from('posts')
          .update({'is_archived': archive})
          .eq('id', postId);
      return true;
    } catch (e) {
      print('❌ toggleArchive error: $e');
      return false;
    }
  }

  // ==================== LIKES ====================

  /// Post beğen/beğeniyi kaldır (Optimistic UI için hızlı)
  Future<bool> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      if (isLiked) {
        // Beğeniyi kaldır
        await _client
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        // Like count azalt
        await _client.rpc(
          'decrement_like_count',
          params: {'post_id_param': postId},
        );
      } else {
        // Beğen
        await _client.from('likes').insert({
          'post_id': postId,
          'user_id': userId,
        });

        // Like count artır
        await _client.rpc(
          'increment_like_count',
          params: {'post_id_param': postId},
        );
      }
      return true;
    } catch (e) {
      print('❌ toggleLike error: $e');
      return false;
    }
  }

  /// Post beğenilmiş mi kontrol et
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final response = await _client
          .from('likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ==================== SAVES ====================

  /// Post kaydet/kaydı kaldır
  Future<bool> toggleSave({
    required String postId,
    required String userId,
    required bool isSaved,
  }) async {
    try {
      if (isSaved) {
        await _client
            .from('saved_posts')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await _client.from('saved_posts').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
      return true;
    } catch (e) {
      print('❌ toggleSave error: $e');
      return false;
    }
  }

  /// Kaydedilen postları getir
  Future<List<PostModel>> getSavedPosts(String userId) async {
    try {
      final response = await _client
          .from('saved_posts')
          .select(
            'posts(*,users!posts_user_id_fkey(username, avatar_url, is_verified))',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PostModel.fromJson(json['posts'], isSaved: true))
          .toList();
    } catch (e) {
      print('❌ getSavedPosts error: $e');
      return [];
    }
  }

  // ==================== COMMENTS ====================

  /// Yorumları getir (sayfalama destekli)
  Future<List<CommentModel>> getComments({
    required String postId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('comments')
          .select('*, users!comments_user_id_fkey(username, avatar_url)')
          .eq('post_id', postId)
          .isFilter('parent_id', null) // Sadece ana yorumlar
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => CommentModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getComments error: $e');
      return [];
    }
  }

  /// Yorum ekle
  Future<CommentModel?> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentId,
  }) async {
    try {
      final response = await _client
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
            'parent_id': parentId,
          })
          .select('*, users!comments_user_id_fkey(username, avatar_url)')
          .single();

      // Comment count artır
      await _client.rpc(
        'increment_comment_count',
        params: {'post_id_param': postId},
      );

      print('✅ Yorum eklendi');
      return CommentModel.fromJson(response);
    } catch (e) {
      print('❌ addComment error: $e');
      return null;
    }
  }

  /// Yorum sil
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await _client.from('comments').delete().eq('id', commentId);

      // Comment count azalt
      await _client.rpc(
        'decrement_comment_count',
        params: {'post_id_param': postId},
      );

      return true;
    } catch (e) {
      print('❌ deleteComment error: $e');
      return false;
    }
  }

  // ==================== HELPERS ====================

  /// Postlara kullanıcının beğeni/kaydetme durumunu ekle
  Future<List<PostModel>> _enrichPostsWithUserState(
    List<dynamic> postsJson,
    String userId,
  ) async {
    if (postsJson.isEmpty) return [];

    try {
      final postIds = postsJson.map((p) => p['id'] as String).toList();

      // Beğenileri al
      final likesResponse = await _client
          .from('likes')
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', postIds);

      final likedPostIds = (likesResponse as List)
          .map((l) => l['post_id'] as String)
          .toSet();

      // Kayıtları al
      final savesResponse = await _client
          .from('saved_posts')
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', postIds);

      final savedPostIds = (savesResponse as List)
          .map((s) => s['post_id'] as String)
          .toSet();

      // Postları oluştur
      return postsJson.map((json) {
        final postId = json['id'] as String;
        return PostModel.fromJson(
          json,
          isLiked: likedPostIds.contains(postId),
          isSaved: savedPostIds.contains(postId),
        );
      }).toList();
    } catch (e) {
      print('❌ _enrichPostsWithUserState error: $e');
      return postsJson.map((json) => PostModel.fromJson(json)).toList();
    }
  }

  /// Realtime post güncellemeleri (feed için)
  Stream<List<Map<String, dynamic>>> watchPosts() {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50);
  }
}
