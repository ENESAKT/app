// Profile Feature Service
// Bu servis, profil özelliği için ek işlevler sağlar
// Ana profil işlemleri supabase_service.dart içinde zaten mevcuttur

import '../../../services/supabase_service.dart';

/// Profile Service - Profil modülü için yardımcı servis
class ProfileService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Kullanıcı profilini getir
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _supabaseService.getUser(userId);
  }

  /// Takipçi sayısını getir (Demo - Gerçek implementasyon için DB tablosu gerekir)
  Future<int> getFollowersCount(String userId) async {
    // TODO: Gerçek implementasyonda followers tablosundan çekilecek
    return 1234; // Demo değer
  }

  /// Takip edilen sayısını getir (Demo)
  Future<int> getFollowingCount(String userId) async {
    // TODO: Gerçek implementasyonda following tablosundan çekilecek
    return 567; // Demo değer
  }

  /// Kullanıcının paylaşımlarını getir (Demo)
  Future<List<String>> getUserPosts(String userId) async {
    // TODO: Gerçek implementasyonda posts tablosundan çekilecek
    return List.generate(
      18,
      (index) =>
          'https://picsum.photos/seed/${userId.hashCode + index}/300/300',
    );
  }

  /// Kullanıcıyı takip et
  Future<bool> followUser(String targetUserId) async {
    try {
      // TODO: Gerçek implementasyonda followers tablosuna kayıt eklenecek
      print('👤 Kullanıcı takip edildi: $targetUserId');
      return true;
    } catch (e) {
      print('❌ Takip hatası: $e');
      return false;
    }
  }

  /// Takibi bırak
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      // TODO: Gerçek implementasyonda followers tablosundan kayıt silinecek
      print('👤 Takip bırakıldı: $targetUserId');
      return true;
    } catch (e) {
      print('❌ Takip bırakma hatası: $e');
      return false;
    }
  }
}
