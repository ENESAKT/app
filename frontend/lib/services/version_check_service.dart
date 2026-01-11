import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Versiyon kontrolü ve güncelleme bildirimi servisi
class VersionCheckService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Supabase'den güncel versiyon bilgilerini çeker ve yerel versiyon ile karşılaştırır
  ///
  /// Returns:
  /// - null: Güncelleme yok veya hata oluştu
  /// - Map: {'version': String, 'download_url': String} - Güncelleme mevcut
  Future<Map<String, String>?> checkForUpdate() async {
    try {
      // 1. Yerel uygulama versiyonunu al
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // örn: "1.0.0"

      print('📱 Yerel Versiyon: $currentVersion');

      // 2. Supabase'den güncel versiyon bilgisini çek
      final response = await _supabase
          .from('app_config')
          .select('current_version, download_url')
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('⚠️ Supabase\'de app_config kaydı bulunamadı');
        return null;
      }

      final latestVersion = response['current_version'] as String?;
      final downloadUrl = response['download_url'] as String?;

      if (latestVersion == null || downloadUrl == null) {
        print('⚠️ Versiyon bilgileri eksik');
        return null;
      }

      print('🌐 Güncel Versiyon: $latestVersion');

      // 3. Versiyon karşılaştırması
      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        print('✅ Güncelleme mevcut: $currentVersion → $latestVersion');
        return {'version': latestVersion, 'download_url': downloadUrl};
      } else {
        print('ℹ️ Uygulama güncel');
        return null;
      }
    } catch (e) {
      print('❌ Versiyon kontrolü hatası: $e');
      return null;
    }
  }

  /// Versiyon karşılaştırması yapar (basit string karşılaştırması)
  ///
  /// Örnek: "1.0.0" < "1.0.1" → true
  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      // Versiyon numaralarını parçalara ayır (örn: "1.0.0" → [1, 0, 0])
      final current = currentVersion.split('.').map(int.parse).toList();
      final latest = latestVersion.split('.').map(int.parse).toList();

      // Major, minor, patch sırasıyla karşılaştır
      for (int i = 0; i < 3; i++) {
        if (i >= current.length || i >= latest.length) {
          return false; // Geçersiz format
        }

        if (latest[i] > current[i]) {
          return true; // Güncelleme mevcut
        } else if (latest[i] < current[i]) {
          return false; // Yerel versiyon daha yeni
        }
        // Eşitse bir sonraki parçayı kontrol et
      }

      return false; // Versiyonlar eşit
    } catch (e) {
      print('⚠️ Versiyon karşılaştırma hatası: $e');
      return false;
    }
  }
}
