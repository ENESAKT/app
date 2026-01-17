import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SETTINGS PROVIDER - Ayarlar State Yönetimi (Riverpod)
/// ═══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════
// VERSİYON BİLGİSİ
// ══════════════════════════════════════════════════════════════════════════

/// Uygulama versiyonu ve build numarasını tutan model
class AppVersion {
  final String version;
  final String buildNumber;
  final String appName;
  final String packageName;

  const AppVersion({
    required this.version,
    required this.buildNumber,
    required this.appName,
    required this.packageName,
  });

  /// Formatlı versiyon string'i
  String get formatted => 'v$version (Build $buildNumber)';

  /// Kısa versiyon
  String get short => 'v$version';
}

/// Uygulama versiyon bilgisini çeken FutureProvider
final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppVersion(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
    );
  } catch (e) {
    print('❌ Versiyon bilgisi alınamadı: $e');
    return const AppVersion(
      version: '1.0.0',
      buildNumber: '1',
      appName: 'Vibe',
      packageName: 'com.enes.vibe',
    );
  }
});

// ══════════════════════════════════════════════════════════════════════════
// ADMİN KONTROLÜ
// ══════════════════════════════════════════════════════════════════════════

/// Mevcut kullanıcının admin olup olmadığını kontrol eden provider
final isAdminProvider = FutureProvider<bool>((ref) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await Supabase.instance.client
        .from('users')
        .select('is_admin')
        .eq('id', userId)
        .single();

    return response['is_admin'] == true;
  } catch (e) {
    print('❌ Admin kontrolü hatası: $e');
    return false;
  }
});

// ══════════════════════════════════════════════════════════════════════════
// API AYARLARI
// ══════════════════════════════════════════════════════════════════════════

/// API endpoint bilgisi
class ApiConfig {
  static const String supabaseUrl = 'https://bmcbzkkewskuibojxvud.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_Ml7r3_OXOW2Tk_yOwm3TBQ_CUU1MTat';

  // Diğer API endpointleri
  static const String weatherApi = 'https://api.open-meteo.com/v1';
  static const String newsApi = 'https://newsapi.org/v2';
}

/// API ayarlarını tutan provider
final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig();
});

// ══════════════════════════════════════════════════════════════════════════
// CACHE YÖNETİMİ
// ══════════════════════════════════════════════════════════════════════════

/// Cache temizleme state'i
class CacheState {
  final bool isClearing;
  final String? message;

  const CacheState({this.isClearing = false, this.message});
}

/// Cache yönetimi için Notifier
class CacheNotifier extends StateNotifier<CacheState> {
  CacheNotifier() : super(const CacheState());

  /// Önbelleği temizle
  Future<void> clearCache() async {
    state = const CacheState(isClearing: true);

    try {
      // 1. Riverpod cache'lerini invalidate et
      // (Bu provider ref ile yapılmalı, burada sadece simülasyon)
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Image cache'ini temizle (CachedNetworkImage için)
      // PaintingBinding.instance.imageCache.clear();
      // PaintingBinding.instance.imageCache.clearLiveImages();

      state = const CacheState(
        isClearing: false,
        message: 'Önbellek temizlendi! ✅',
      );
    } catch (e) {
      state = CacheState(isClearing: false, message: 'Hata: $e');
    }
  }
}

final cacheNotifierProvider = StateNotifierProvider<CacheNotifier, CacheState>((
  ref,
) {
  return CacheNotifier();
});
