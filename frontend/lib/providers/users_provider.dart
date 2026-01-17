import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// USERS PROVIDER - Kullanıcı Listesi Yönetimi (Riverpod)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Bu dosya kullanıcı listelerini Riverpod ile yönetir.
/// - allUsersProvider: Tüm kullanıcıları çeker (kendisi hariç)
/// - searchUsersProvider: Kullanıcı arama
/// - userByIdProvider: Belirli kullanıcı bilgisi

// ══════════════════════════════════════════════════════════════════════════
// TÜM KULLANICILAR
// ══════════════════════════════════════════════════════════════════════════

/// Tüm kullanıcıları çeken FutureProvider (mevcut kullanıcı hariç)
/// Keşfet sayfasında kullanılır
final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  try {
    final query = client.from('users').select();

    // Mevcut kullanıcıyı hariç tut
    final response = currentUserId != null
        ? await query
              .neq('id', currentUserId)
              .order('created_at', ascending: false)
              .limit(50)
        : await query.order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('❌ Kullanıcı listesi çekme hatası: $e');
    return [];
  }
});

// ══════════════════════════════════════════════════════════════════════════
// KULLANICI ARAMA
// ══════════════════════════════════════════════════════════════════════════

/// Arama sorgusu state'i
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Kullanıcı arama sonuçları
final searchUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || query.length < 2) return [];

  final client = ref.watch(supabaseClientProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  try {
    final baseQuery = client
        .from('users')
        .select()
        .ilike('username', '%$query%');

    final response = currentUserId != null
        ? await baseQuery.neq('id', currentUserId).limit(20)
        : await baseQuery.limit(20);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('❌ Kullanıcı arama hatası: $e');
    return [];
  }
});

// ══════════════════════════════════════════════════════════════════════════
// TEK KULLANICI
// ══════════════════════════════════════════════════════════════════════════

/// Belirli bir kullanıcının bilgilerini çeker
/// Kullanım: ref.watch(userByIdProvider('user-id'))
final userByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((
  ref,
  userId,
) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return response;
  } catch (e) {
    print('❌ Kullanıcı bilgisi çekme hatası: $e');
    return null;
  }
});

// ══════════════════════════════════════════════════════════════════════════
// ARKADAŞLAR
// ══════════════════════════════════════════════════════════════════════════

/// Kabul edilmiş arkadaşları çeker
final friendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  if (currentUserId == null) return [];

  try {
    final response = await client
        .from('friendships')
        .select('*, user1:user_id_1(*), user2:user_id_2(*)')
        .eq('status', 'accepted')
        .or('user_id_1.eq.$currentUserId,user_id_2.eq.$currentUserId');

    // Karşı tarafın bilgilerini çıkar
    List<Map<String, dynamic>> friends = [];
    for (var friendship in response) {
      final user1 = friendship['user1'];
      final user2 = friendship['user2'];

      Map<String, dynamic>? friend;
      if (user1 != null && user1['id'] != currentUserId) {
        friend = Map<String, dynamic>.from(user1);
      } else if (user2 != null && user2['id'] != currentUserId) {
        friend = Map<String, dynamic>.from(user2);
      }

      if (friend != null && friend['id'] != null) {
        friends.add(friend);
      }
    }

    return friends;
  } catch (e) {
    print('❌ Arkadaş listesi çekme hatası: $e');
    return [];
  }
});
