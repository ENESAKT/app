import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

/// Notification Service - Bildirimleri yönetir
///
/// Single Responsibility: Notification CRUD ve realtime
/// Realtime WebSocket desteği
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Realtime subscription
  RealtimeChannel? _channel;
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();

  /// Realtime bildirim stream'i
  Stream<NotificationModel> get onNotification =>
      _notificationController.stream;

  // ==================== FETCH ====================

  /// Bildirimleri getir (sayfalama destekli)
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('notifications')
          .select('''
            *,
            actor:actor_id(username, avatar_url),
            post:post_id(media_urls)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getNotifications error: $e');
      return [];
    }
  }

  /// Okunmamış bildirim sayısı
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('❌ getUnreadCount error: $e');
      return 0;
    }
  }

  // ==================== ACTIONS ====================

  /// Bildirimi okundu olarak işaretle
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('❌ markAsRead error: $e');
      return false;
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      print('❌ markAllAsRead error: $e');
      return false;
    }
  }

  /// Bildirim sil
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      print('❌ deleteNotification error: $e');
      return false;
    }
  }

  // ==================== CREATE (Internal use) ====================

  /// Yeni bildirim oluştur (genelde trigger ile yapılır)
  Future<bool> createNotification({
    required String userId,
    required String actorId,
    required NotificationType type,
    String? postId,
    String? commentId,
  }) async {
    // Kendine bildirim gönderme
    if (userId == actorId) return false;

    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'actor_id': actorId,
        'type': type.value,
        'post_id': postId,
        'comment_id': commentId,
      });
      return true;
    } catch (e) {
      print('❌ createNotification error: $e');
      return false;
    }
  }

  // ==================== REALTIME ====================

  /// Realtime bildirimleri dinlemeye başla
  void startListening(String userId) {
    _channel?.unsubscribe();

    _channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            try {
              // Yeni bildirimi tam olarak çek (join'lerle birlikte)
              final notificationId = payload.newRecord['id'] as String;
              final fullNotification = await _client
                  .from('notifications')
                  .select('''
                    *,
                    actor:actor_id(username, avatar_url),
                    post:post_id(media_urls)
                  ''')
                  .eq('id', notificationId)
                  .single();

              final notification = NotificationModel.fromJson(fullNotification);
              _notificationController.add(notification);
            } catch (e) {
              print('❌ Realtime notification parse error: $e');
            }
          },
        )
        .subscribe();

    print('🔔 Bildirim dinleme başlatıldı: $userId');
  }

  /// Dinlemeyi durdur
  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    print('🔕 Bildirim dinleme durduruldu');
  }

  /// Servisi temizle
  void dispose() {
    stopListening();
    _notificationController.close();
  }
}
