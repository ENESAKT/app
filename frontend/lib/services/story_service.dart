import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';

/// Story Service - Stories CRUD ve görüntüleme işlemleri
///
/// Single Responsibility: Story işlemlerini yönetir
/// 24 saat sonra otomatik silinme mantığı
class StoryService {
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;
  StoryService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ==================== FEED ====================

  /// Takip edilenlerin aktif story'lerini getir (gruplu)
  Future<List<UserStories>> getStoryFeed(String userId) async {
    try {
      // 1. Takip edilenlerin ID'lerini al
      final followingResponse = await _client
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (followingResponse as List)
          .map((f) => f['following_id'] as String)
          .toList();

      // Kendini de ekle (en başa)
      followingIds.insert(0, userId);

      // 2. Aktif story'leri al (süresi dolmamış)
      final now = DateTime.now().toIso8601String();
      final storiesResponse = await _client
          .from('stories')
          .select('*, users!stories_user_id_fkey(username, avatar_url)')
          .inFilter('user_id', followingIds)
          .gt('expires_at', now)
          .order('created_at', ascending: true);

      // 3. Görüntülenmiş story'leri al
      final viewedResponse = await _client
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', userId);

      final viewedStoryIds = (viewedResponse as List)
          .map((v) => v['story_id'] as String)
          .toSet();

      // 4. Kullanıcıya göre grupla
      final Map<String, List<StoryModel>> groupedStories = {};
      final Map<String, Map<String, dynamic>> userInfoMap = {};

      for (final storyJson in storiesResponse as List) {
        final storyUserId = storyJson['user_id'] as String;
        final storyId = storyJson['id'] as String;
        final isViewed = viewedStoryIds.contains(storyId);

        final story = StoryModel.fromJson(storyJson, isViewed: isViewed);

        if (!groupedStories.containsKey(storyUserId)) {
          groupedStories[storyUserId] = [];

          // Kullanıcı bilgilerini sakla
          if (storyJson['users'] is Map) {
            userInfoMap[storyUserId] =
                storyJson['users'] as Map<String, dynamic>;
          }
        }
        groupedStories[storyUserId]!.add(story);
      }

      // 5. UserStories listesi oluştur
      final List<UserStories> result = [];

      for (final entry in groupedStories.entries) {
        final userInfo = userInfoMap[entry.key];
        final stories = entry.value;
        final hasUnviewed = stories.any((s) => !s.isViewed);

        result.add(
          UserStories(
            userId: entry.key,
            username: userInfo?['username'] as String?,
            avatarUrl: userInfo?['avatar_url'] as String?,
            stories: stories,
            hasUnviewed: hasUnviewed,
          ),
        );
      }

      // 6. Görüntülenmemişleri öne al, sonra zamana göre sırala
      result.sort((a, b) {
        if (a.userId == userId) return -1; // Kendi story'n hep başta
        if (b.userId == userId) return 1;
        if (a.hasUnviewed != b.hasUnviewed) {
          return a.hasUnviewed ? -1 : 1;
        }
        return (b.latestStory?.createdAt ?? DateTime(0)).compareTo(
          a.latestStory?.createdAt ?? DateTime(0),
        );
      });

      return result;
    } catch (e) {
      print('❌ getStoryFeed error: $e');
      return [];
    }
  }

  /// Belirli bir kullanıcının story'lerini getir
  Future<List<StoryModel>> getUserStories(
    String userId, {
    String? viewerId,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('stories')
          .select('*, users!stories_user_id_fkey(username, avatar_url)')
          .eq('user_id', userId)
          .gt('expires_at', now)
          .order('created_at', ascending: true);

      Set<String> viewedStoryIds = {};
      if (viewerId != null) {
        final viewedResponse = await _client
            .from('story_views')
            .select('story_id')
            .eq('viewer_id', viewerId);
        viewedStoryIds = (viewedResponse as List)
            .map((v) => v['story_id'] as String)
            .toSet();
      }

      return (response as List).map((json) {
        final storyId = json['id'] as String;
        return StoryModel.fromJson(
          json,
          isViewed: viewedStoryIds.contains(storyId),
        );
      }).toList();
    } catch (e) {
      print('❌ getUserStories error: $e');
      return [];
    }
  }

  // ==================== STORY CRUD ====================

  /// Yeni story oluştur
  Future<StoryModel?> createStory({
    required String userId,
    required String mediaUrl,
    StoryMediaType mediaType = StoryMediaType.image,
  }) async {
    try {
      final response = await _client
          .from('stories')
          .insert({
            'user_id': userId,
            'media_url': mediaUrl,
            'media_type': mediaType.value,
          })
          .select('*, users!stories_user_id_fkey(username, avatar_url)')
          .single();

      print('✅ Story oluşturuldu: ${response['id']}');
      return StoryModel.fromJson(response);
    } catch (e) {
      print('❌ createStory error: $e');
      return null;
    }
  }

  /// Story sil
  Future<bool> deleteStory(String storyId) async {
    try {
      await _client.from('stories').delete().eq('id', storyId);
      print('✅ Story silindi: $storyId');
      return true;
    } catch (e) {
      print('❌ deleteStory error: $e');
      return false;
    }
  }

  // ==================== VIEWS ====================

  /// Story görüntüleme kaydet
  Future<void> markAsViewed(String storyId, String viewerId) async {
    try {
      // Daha önce görüntülenmişse atla (upsert)
      await _client.from('story_views').upsert({
        'story_id': storyId,
        'viewer_id': viewerId,
      }, onConflict: 'story_id,viewer_id');

      // View count artır
      await _client.rpc(
        'increment_story_view_count',
        params: {'story_id_param': storyId},
      );
    } catch (e) {
      print('❌ markAsViewed error: $e');
    }
  }

  /// Story görüntüleyenleri getir
  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    try {
      final response = await _client
          .from('story_views')
          .select('*, users!story_views_viewer_id_fkey(username, avatar_url)')
          .eq('story_id', storyId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ getStoryViewers error: $e');
      return [];
    }
  }

  // ==================== CLEANUP ====================

  /// Süresi dolmuş story'leri sil (genelde backend'de scheduled job ile yapılır)
  Future<int> cleanupExpiredStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('stories')
          .delete()
          .lt('expires_at', now)
          .select('id');

      final count = (response as List).length;
      print('✅ $count süresi dolmuş story silindi');
      return count;
    } catch (e) {
      print('❌ cleanupExpiredStories error: $e');
      return 0;
    }
  }

  // ==================== REALTIME ====================

  /// Realtime story güncellemeleri
  Stream<List<Map<String, dynamic>>> watchStories() {
    final now = DateTime.now().toIso8601String();
    return _client
        .from('stories')
        .stream(primaryKey: ['id'])
        .gt('expires_at', now)
        .order('created_at', ascending: false);
  }
}
