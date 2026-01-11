import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/update_info.dart';

/// OTA Update Servisi
///
/// Sorumluluklar:
/// - Mevcut uygulama versiyonunu kontrol etme
/// - Supabase'den en son versiyonu getirme
/// - Semantik versiyon karşılaştırması
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Mevcut uygulama versiyonunu al
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version; // Örn: "1.0.0"
    } catch (e) {
      print('❌ Versiyon alma hatası: $e');
      return '0.0.0';
    }
  }

  /// Güncelleme kontrolü - Varsa UpdateInfo dön, yoksa null
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      print('🔍 Güncelleme kontrol ediliyor...');

      // 1. Mevcut versiyon
      final currentVersion = await getCurrentVersion();
      print('   - Mevcut versiyon: $currentVersion');

      // 2. Supabase'den en son versiyon
      final response = await _client
          .from('app_versions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('   - Supabase\'de versiyon kaydı yok');
        return null;
      }

      final latestUpdate = UpdateInfo.fromJson(response);
      print('   - Supabase versiyon: ${latestUpdate.versionNumber}');

      // 3. Versiyon karşılaştırması
      if (_isNewerVersion(latestUpdate.versionNumber, currentVersion)) {
        print('✅ Yeni güncelleme mevcut!');
        print('   - Zorunlu: ${latestUpdate.forceUpdate}');
        print('   - Mesaj: ${latestUpdate.updateMessage}');
        return latestUpdate;
      } else {
        print('✓ Uygulama güncel');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Güncelleme kontrolü hatası: $e');
      print('Stack: $stackTrace');
      return null;
    }
  }

  /// Semantik versiyon karşılaştırması
  /// Returns: true if newVersion > currentVersion
  bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Eksik parçaları 0 ile doldur
      while (newParts.length < 3) newParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      // Major.Minor.Patch karşılaştırması
      for (int i = 0; i < 3; i++) {
        if (newParts[i] > currentParts[i]) {
          return true; // Yeni versiyon daha büyük
        } else if (newParts[i] < currentParts[i]) {
          return false; // Mevcut versiyon daha büyük
        }
        // Eşitse bir sonraki kısmı kontrol et
      }

      return false; // Eşit versiyonlar
    } catch (e) {
      print('⚠️ Versiyon karşılaştırma hatası: $e');

      // Fallback: String karşılaştırması
      return newVersion.compareTo(currentVersion) > 0;
    }
  }

  /// Versiyon bilgilerini formatlı string olarak dön
  String formatVersion(String version) {
    final parts = version.split('.');
    if (parts.length == 3) {
      return 'v${parts[0]}.${parts[1]}.${parts[2]}';
    }
    return 'v$version';
  }

  /// İki versiyon arasındaki farkı açıkla
  String getUpdateTypeDescription(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      while (newParts.length < 3) newParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      if (newParts[0] > currentParts[0]) {
        return 'Büyük Güncelleme'; // Major update
      } else if (newParts[1] > currentParts[1]) {
        return 'Yeni Özellikler'; // Minor update
      } else if (newParts[2] > currentParts[2]) {
        return 'Hata Düzeltmeleri'; // Patch update
      }

      return 'Güncelleme';
    } catch (e) {
      return 'Güncelleme';
    }
  }
}
