import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ChatService - Mesajlaşma işlemleri için servis
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Mesaj gönder
  Future<Map<String, dynamic>?> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      if (currentUserId == null) throw Exception('Kullanıcı giriş yapmamış');
      if (content.trim().isEmpty) throw Exception('Mesaj boş olamaz');

      final message = await _client
          .from('messages')
          .insert({
            'sender_id': currentUserId!,
            'receiver_id': receiverId,
            'content': content.trim(),
            'is_read': false,
          })
          .select()
          .single();

      return message;
    } catch (e) {
      print('❌ Mesaj gönderme hatası: $e');
      rethrow;
    }
  }

  /// İki kullanıcı arasındaki mesajları getir
  Future<List<Map<String, dynamic>>> getMessages({
    required String otherUserId,
    int limit = 50,
  }) async {
    try {
      if (currentUserId == null) return [];

      final messages = await _client
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
          )
          .order('created_at', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      print('❌ Mesaj alma hatası: $e');
      return [];
    }
  }

  /// Realtime mesaj dinle (Stream)
  Stream<List<Map<String, dynamic>>> watchMessages({
    required String otherUserId,
  }) {
    if (currentUserId == null) return const Stream.empty();

    final userId = currentUserId!;
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((messages) {
          return messages
              .where(
                (m) =>
                    (m['sender_id'] == userId &&
                        m['receiver_id'] == otherUserId) ||
                    (m['sender_id'] == otherUserId &&
                        m['receiver_id'] == userId),
              )
              .toList();
        });
  }

  /// Mesajları okundu olarak işaretle
  Future<void> markAsRead({required String senderId}) async {
    try {
      if (currentUserId == null) return;

      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('sender_id', senderId)
          .eq('receiver_id', currentUserId!)
          .eq('is_read', false);
    } catch (e) {
      print('❌ Okundu işaretleme hatası: $e');
    }
  }

  /// Son konuşmaları getir
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      if (currentUserId == null) return [];

      final messages = await _client
          .from('messages')
          .select('*, sender:sender_id(*), receiver:receiver_id(*)')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      Map<String, Map<String, dynamic>> conversationMap = {};

      for (var message in messages) {
        final otherUserId = message['sender_id'] == currentUserId
            ? message['receiver_id']
            : message['sender_id'];

        final otherUser = message['sender_id'] == currentUserId
            ? message['receiver']
            : message['sender'];

        if (!conversationMap.containsKey(otherUserId)) {
          final unreadCount = await _getUnreadCount(otherUserId);
          conversationMap[otherUserId] = {
            'other_user': otherUser,
            'last_message': message,
            'unread_count': unreadCount,
          };
        }
      }

      return conversationMap.values.toList();
    } catch (e) {
      print('❌ Konuşma listesi hatası: $e');
      return [];
    }
  }

  Future<int> _getUnreadCount(String senderId) async {
    try {
      if (currentUserId == null) return 0;

      final result = await _client
          .from('messages')
          .select()
          .eq('sender_id', senderId)
          .eq('receiver_id', currentUserId!)
          .eq('is_read', false);

      return result.length;
    } catch (e) {
      return 0;
    }
  }

  /// Toplam okunmamış mesaj sayısı
  Future<int> getTotalUnreadCount() async {
    try {
      if (currentUserId == null) return 0;

      final result = await _client
          .from('messages')
          .select()
          .eq('receiver_id', currentUserId!)
          .eq('is_read', false);

      return result.length;
    } catch (e) {
      return 0;
    }
  }

  /// Mesaj silme
  Future<bool> deleteMessage({required String messageId}) async {
    try {
      if (currentUserId == null) return false;

      await _client
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', currentUserId!);

      return true;
    } catch (e) {
      print('❌ Mesaj silme hatası: $e');
      return false;
    }
  }
}
