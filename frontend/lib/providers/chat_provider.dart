import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHAT PROVIDER - Mesajlaşma Yönetimi (Riverpod)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Bu dosya mesajlaşma işlemlerini Riverpod ile yönetir.
/// - conversationsProvider: Konuşma listesi
/// - messagesProvider: Belirli bir sohbetin mesajları
/// - unreadCountProvider: Okunmamış mesaj sayısı

// ══════════════════════════════════════════════════════════════════════════
// KONUŞMA LİSTESİ
// ══════════════════════════════════════════════════════════════════════════

/// Tüm konuşmaları çeken FutureProvider
/// Her konuşma için son mesaj ve karşı tarafın bilgisini içerir
final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  if (currentUserId == null) return [];

  try {
    // Tüm mesajları al (gönderilen ve alınan)
    final allMessages = await client
        .from('messages')
        .select('*, sender:sender_id(*), receiver:receiver_id(*)')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .order('created_at', ascending: false);

    // Her kullanıcı için son mesajı grupla
    final Map<String, Map<String, dynamic>> conversationsMap = {};

    for (var message in allMessages) {
      final senderId = message['sender_id'];
      final receiverId = message['receiver_id'];
      final otherUserId = senderId == currentUserId ? receiverId : senderId;

      // Eğer bu kullanıcıyla bir konuşma yoksa, ekle
      if (!conversationsMap.containsKey(otherUserId)) {
        conversationsMap[otherUserId] = message;
      }
    }

    return conversationsMap.values.toList();
  } catch (e) {
    print('❌ Konuşma listesi çekme hatası: $e');
    return [];
  }
});

// ══════════════════════════════════════════════════════════════════════════
// MESAJLAR (STREAM)
// ══════════════════════════════════════════════════════════════════════════

/// Belirli bir sohbetin mesajlarını dinleyen StreamProvider
/// Kullanım: ref.watch(messagesStreamProvider('other-user-id'))
final messagesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      otherUserId,
    ) {
      final client = ref.watch(supabaseClientProvider);
      final currentUserId = ref.watch(currentUserIdProvider);

      if (currentUserId == null) {
        return Stream.value([]);
      }

      return client
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true)
          .map((data) {
            // Sadece bu iki kullanıcı arasındaki mesajları filtrele
            return data.where((message) {
              final senderId = message['sender_id'];
              final receiverId = message['receiver_id'];
              return (senderId == currentUserId && receiverId == otherUserId) ||
                  (senderId == otherUserId && receiverId == currentUserId);
            }).toList();
          });
    });

// ══════════════════════════════════════════════════════════════════════════
// OKUNMAMIŞ MESAJ SAYISI
// ══════════════════════════════════════════════════════════════════════════

/// Toplam okunmamış mesaj sayısı
final unreadCountProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  if (currentUserId == null) return 0;

  try {
    final response = await client
        .from('messages')
        .select()
        .eq('receiver_id', currentUserId)
        .eq('is_read', false);
    return response.length;
  } catch (e) {
    print('❌ Okunmamış mesaj sayısı hatası: $e');
    return 0;
  }
});

// ══════════════════════════════════════════════════════════════════════════
// MESAJ GÖNDERME (NOTIFIER)
// ══════════════════════════════════════════════════════════════════════════

/// Mesaj gönderme işlemleri için Notifier
class ChatNotifier extends StateNotifier<bool> {
  final Ref ref;

  ChatNotifier(this.ref) : super(false);

  SupabaseClient get _client => ref.read(supabaseClientProvider);
  String? get _currentUserId => ref.read(currentUserIdProvider);

  /// Mesaj gönder
  Future<bool> sendMessage(String receiverId, String content) async {
    if (_currentUserId == null || content.trim().isEmpty) return false;

    state = true; // Yükleniyor

    try {
      await _client.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': receiverId,
        'content': content.trim(),
        'is_read': false,
      });

      state = false;
      return true;
    } catch (e) {
      print('❌ Mesaj gönderme hatası: $e');
      state = false;
      return false;
    }
  }

  /// Mesajları okundu olarak işaretle
  Future<void> markAsRead(String senderId) async {
    if (_currentUserId == null) return;

    try {
      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('sender_id', senderId)
          .eq('receiver_id', _currentUserId!)
          .eq('is_read', false);
    } catch (e) {
      print('❌ Okundu işaretleme hatası: $e');
    }
  }
}

/// ChatNotifier provider
final chatNotifierProvider = StateNotifierProvider<ChatNotifier, bool>((ref) {
  return ChatNotifier(ref);
});
