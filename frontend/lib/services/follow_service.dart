import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Follow Service - Takip işlemleri
///
/// Single Responsibility: Follower/Following yönetimi
/// Optimistic UI için hızlı response
class FollowService {
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ==================== FOLLOW ACTIONS ====================

  /// Kullanıcıyı takip et
  Future<bool> follow(String followerId, String followingId) async {
    try {
      await _client.from('followers').insert({
        'follower_id': followerId,
        'following_id': followingId,
      });

      print('✅ Takip edildi: $followerId -> $followingId');
      return true;
    } catch (e) {
      print('❌ follow error: $e');
      return false;
    }
  }

  /// Takibi bırak
  Future<bool> unfollow(String followerId, String followingId) async {
    try {
      await _client
          .from('followers')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);

      print('✅ Takip bırakıldı: $followerId -> $followingId');
      return true;
    } catch (e) {
      print('❌ unfollow error: $e');
      return false;
    }
  }

  /// Takip et/bırak toggle
  Future<bool> toggleFollow({
    required String followerId,
    required String followingId,
    required bool isFollowing,
  }) async {
    if (isFollowing) {
      return await unfollow(followerId, followingId);
    } else {
      return await follow(followerId, followingId);
    }
  }

  // ==================== QUERIES ====================

  /// Takip ediliyor mu kontrol et
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final response = await _client
          .from('followers')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ isFollowing error: $e');
      return false;
    }
  }

  /// Takipçileri getir
  Future<List<Map<String, dynamic>>> getFollowers({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('followers')
          .select(
            '*, users!followers_follower_id_fkey(id, username, avatar_url, bio)',
          )
          .eq('following_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((f) {
        final user = f['users'] as Map<String, dynamic>? ?? {};
        return {
          'id': user['id'],
          'username': user['username'],
          'avatar_url': user['avatar_url'],
          'bio': user['bio'],
          'followed_at': f['created_at'],
        };
      }).toList();
    } catch (e) {
      print('❌ getFollowers error: $e');
      return [];
    }
  }

  /// Takip edilenleri getir
  Future<List<Map<String, dynamic>>> getFollowing({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('followers')
          .select(
            '*, users!followers_following_id_fkey(id, username, avatar_url, bio)',
          )
          .eq('follower_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((f) {
        final user = f['users'] as Map<String, dynamic>? ?? {};
        return {
          'id': user['id'],
          'username': user['username'],
          'avatar_url': user['avatar_url'],
          'bio': user['bio'],
          'followed_at': f['created_at'],
        };
      }).toList();
    } catch (e) {
      print('❌ getFollowing error: $e');
      return [];
    }
  }

  // ==================== COUNTS ====================

  /// Takipçi sayısını getir
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _client
          .from('followers')
          .select('id')
          .eq('following_id', userId);

      return (response as List).length;
    } catch (e) {
      print('❌ getFollowerCount error: $e');
      return 0;
    }
  }

  /// Takip edilen sayısını getir
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _client
          .from('followers')
          .select('id')
          .eq('follower_id', userId);

      return (response as List).length;
    } catch (e) {
      print('❌ getFollowingCount error: $e');
      return 0;
    }
  }

  /// Profil istatistiklerini getir (posts, followers, following)
  Future<Map<String, int>> getProfileStats(String userId) async {
    try {
      // Paralel olarak çek
      final results = await Future.wait([
        _client
            .from('posts')
            .select('id')
            .eq('user_id', userId)
            .eq('is_archived', false),
        _client.from('followers').select('id').eq('following_id', userId),
        _client.from('followers').select('id').eq('follower_id', userId),
      ]);

      return {
        'posts': (results[0] as List).length,
        'followers': (results[1] as List).length,
        'following': (results[2] as List).length,
      };
    } catch (e) {
      print('❌ getProfileStats error: $e');
      return {'posts': 0, 'followers': 0, 'following': 0};
    }
  }

  // ==================== SUGGESTIONS ====================

  /// Önerilen kullanıcılar (takip etmediklerin, popüler olanlar)
  Future<List<Map<String, dynamic>>> getSuggestions({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // Takip edilenleri al
      final followingResponse = await _client
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (followingResponse as List)
          .map((f) => f['following_id'] as String)
          .toList();

      // Kendini de hariç tut
      followingIds.add(userId);

      // Takip edilmemiş kullanıcıları getir
      final usersResponse = await _client
          .from('users')
          .select('id, username, avatar_url, bio')
          .not('id', 'in', '(${followingIds.join(',')})')
          .limit(limit);

      return List<Map<String, dynamic>>.from(usersResponse);
    } catch (e) {
      print('❌ getSuggestions error: $e');
      return [];
    }
  }

  // ==================== MUTUAL ====================

  /// Ortak takipçileri getir
  Future<List<Map<String, dynamic>>> getMutualFollowers({
    required String userId1,
    required String userId2,
    int limit = 10,
  }) async {
    try {
      // userId1'in takipçileri
      final followers1 = await _client
          .from('followers')
          .select('follower_id')
          .eq('following_id', userId1);

      final followerIds1 = (followers1 as List)
          .map((f) => f['follower_id'] as String)
          .toSet();

      // userId2'nin takipçileri
      final followers2 = await _client
          .from('followers')
          .select('follower_id')
          .eq('following_id', userId2);

      final followerIds2 = (followers2 as List)
          .map((f) => f['follower_id'] as String)
          .toSet();

      // Kesişim
      final mutualIds = followerIds1.intersection(followerIds2).toList();

      if (mutualIds.isEmpty) return [];

      // Kullanıcı bilgilerini al
      final usersResponse = await _client
          .from('users')
          .select('id, username, avatar_url')
          .inFilter('id', mutualIds)
          .limit(limit);

      return List<Map<String, dynamic>>.from(usersResponse);
    } catch (e) {
      print('❌ getMutualFollowers error: $e');
      return [];
    }
  }
}
