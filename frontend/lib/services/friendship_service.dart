import 'package:supabase_flutter/supabase_flutter.dart';

/// Arkadaşlık Servisi - Temiz servis katmanı (Clean Architecture)
///
/// Sorumluluklar:
/// - Kullanıcı arama
/// - Arkadaşlık istekleri (gönderme, kabul etme, reddetme)
/// - Arkadaş listesi yönetimi
/// - İstek durumu kontrolü
class FriendshipService {
  static final FriendshipService _instance = FriendshipService._internal();
  factory FriendshipService() => _instance;
  FriendshipService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Kullanıcı ara (username veya email ile)
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      print('🔍 Kullanıcı aranıyor: $query');

      // Username veya email'de ara (case-insensitive)
      final response = await _client
          .from('users')
          .select()
          .neq('id', currentUserId) // Kendisi hariç
          .or('username.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      print('✅ ${response.length} kullanıcı bulundu');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Arama hatası: $e');
      throw Exception('Kullanıcı araması başarısız: $e');
    }
  }

  /// Arkadaşlık isteği gönder
  Future<bool> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      print('📤 Arkadaşlık isteği gönderiliyor: $fromUserId → $toUserId');

      // ID'leri sırala (küçük olan önce - tutarlılık için)
      final userId1 = fromUserId.compareTo(toUserId) < 0
          ? fromUserId
          : toUserId;
      final userId2 = fromUserId.compareTo(toUserId) < 0
          ? toUserId
          : fromUserId;

      // Mevcut ilişki var mı kontrol et
      final existing = await _client
          .from('friendships')
          .select()
          .eq('user_id_1', userId1)
          .eq('user_id_2', userId2)
          .maybeSingle();

      if (existing != null) {
        print('⚠️ Zaten bir ilişki var');
        return false;
      }

      // Yeni istek oluştur
      await _client.from('friendships').insert({
        'user_id_1': userId1,
        'user_id_2': userId2,
        'status': 'pending',
        'requested_by': fromUserId,
      });

      print('✅ İstek gönderildi');
      return true;
    } catch (e) {
      print('❌ İstek gönderme hatası: $e');
      if (e.toString().contains('unique')) {
        return false; // Duplicate key hatası
      }
      throw Exception('İstek gönderilemedi: $e');
    }
  }

  /// Gelen arkadaşlık isteklerini getir
  Future<List<Map<String, dynamic>>> getPendingRequests({
    required String userId,
  }) async {
    try {
      print('📥 Gelen istekler alınıyor: $userId');

      // Bana gönderilen pending istekler
      final requests = await _client
          .from('friendships')
          .select('*, requester:requested_by(*)')
          .eq('status', 'pending')
          .or('user_id_1.eq.$userId,user_id_2.eq.$userId')
          .neq('requested_by', userId); // Kendimin gönderdikleri hariç

      print('✅ ${requests.length} istek bulundu');
      return List<Map<String, dynamic>>.from(requests);
    } catch (e) {
      print('❌ İstek alma hatası: $e');
      throw Exception('İstekler alınamadı: $e');
    }
  }

  /// Arkadaşlık isteğini kabul et
  Future<bool> acceptFriendRequest({required String requestId}) async {
    try {
      print('✅ İstek kabul ediliyor: $requestId');

      await _client
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      print('✅ İstek kabul edildi');
      return true;
    } catch (e) {
      print('❌ Kabul etme hatası: $e');
      throw Exception('İstek kabul edilemedi: $e');
    }
  }

  /// Arkadaşlık isteğini reddet/sil
  Future<bool> rejectFriendRequest({required String requestId}) async {
    try {
      print('❌ İstek reddediliyor: $requestId');

      // Tamamen sil (rejected status yerine)
      await _client.from('friendships').delete().eq('id', requestId);

      print('✅ İstek silindi');
      return true;
    } catch (e) {
      print('❌ Reddetme hatası: $e');
      throw Exception('İstek reddedilemedi: $e');
    }
  }

  /// Arkadaş listesini getir (accepted)
  Future<List<Map<String, dynamic>>> getFriends({
    required String userId,
  }) async {
    try {
      print('👥 Arkadaşlar alınıyor: $userId');

      final friendships = await _client
          .from('friendships')
          .select('*, user1:user_id_1(*), user2:user_id_2(*)')
          .eq('status', 'accepted')
          .or('user_id_1.eq.$userId,user_id_2.eq.$userId');

      // Karşı tarafın bilgilerini çıkar
      List<Map<String, dynamic>> friends = [];
      for (var friendship in friendships) {
        final user1 = friendship['user1'];
        final user2 = friendship['user2'];

        // Kendisi hangisi değilse onu arkadaş listesine ekle
        if (user1 != null && user1['id'] != userId) {
          friends.add(user1);
        } else if (user2 != null && user2['id'] != userId) {
          friends.add(user2);
        }
      }

      print('✅ ${friends.length} arkadaş bulundu');
      return friends;
    } catch (e) {
      print('❌ Arkadaş listesi alma hatası: $e');
      throw Exception('Arkadaşlar alınamadı: $e');
    }
  }

  /// İki kullanıcı arasındaki ilişki durumunu kontrol et
  /// Returns: null (yok), 'pending_sent' (istek gönderdim), 'pending_received' (istek aldım), 'friends' (arkadaşız)
  Future<String?> checkFriendshipStatus({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final userId1 = currentUserId.compareTo(otherUserId) < 0
          ? currentUserId
          : otherUserId;
      final userId2 = currentUserId.compareTo(otherUserId) < 0
          ? otherUserId
          : currentUserId;

      final friendship = await _client
          .from('friendships')
          .select()
          .eq('user_id_1', userId1)
          .eq('user_id_2', userId2)
          .maybeSingle();

      if (friendship == null) {
        return null; // İlişki yok
      }

      final status = friendship['status'];
      final requestedBy = friendship['requested_by'];

      if (status == 'accepted') {
        return 'friends';
      } else if (status == 'pending') {
        if (requestedBy == currentUserId) {
          return 'pending_sent'; // Ben gönderdim
        } else {
          return 'pending_received'; // Bana gönderildi
        }
      }

      return null;
    } catch (e) {
      print('❌ Durum kontrolü hatası: $e');
      return null;
    }
  }

  /// Gönderilen istekleri getir (bekleniyor)
  Future<List<Map<String, dynamic>>> getSentRequests({
    required String userId,
  }) async {
    try {
      final requests = await _client
          .from('friendships')
          .select('*, receiver:user_id_1(*), receiver2:user_id_2(*)')
          .eq('status', 'pending')
          .eq('requested_by', userId);

      // Karşı tarafın bilgilerini çıkar
      List<Map<String, dynamic>> sentTo = [];
      for (var request in requests) {
        final user1 = request['receiver'];
        final user2 = request['receiver2'];

        if (user1 != null && user1['id'] != userId) {
          sentTo.add({...user1, 'friendship_id': request['id']});
        } else if (user2 != null && user2['id'] != userId) {
          sentTo.add({...user2, 'friendship_id': request['id']});
        }
      }

      return sentTo;
    } catch (e) {
      print('❌ Gönderilen istekler alma hatası: $e');
      return [];
    }
  }
}
