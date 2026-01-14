/// Super App - Merkezi API Anahtarları
///
/// Tüm harici API anahtarları burada tutulur.
/// ⚠️ GÜVENLİK: Bu dosyayı .gitignore'a ekleyin!
///
/// Kullanım:
/// ```dart
/// import 'package:frontend/core/constants/api_keys.dart';
/// final url = 'https://api.example.com?key=${ApiKeys.openWeatherMap}';
/// ```
class ApiKeys {
  // Private constructor - instance oluşturulamaz
  ApiKeys._();

  // ═══════════════════════════════════════════════════════════════════
  // 1. OPENWEATHERMAP - Hava Durumu API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://openweathermap.org/api
  // Ücretsiz plan: 1000 çağrı/gün
  static const String openWeatherMap = '';

  // ═══════════════════════════════════════════════════════════════════
  // 2. UNSPLASH - Duvar Kağıdı/Görsel API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://unsplash.com/developers
  // Ücretsiz plan: 50 çağrı/saat
  static const String unsplash = '';

  // ═══════════════════════════════════════════════════════════════════
  // 3. NEWSAPI - Haber API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://newsapi.org/
  // Ücretsiz plan: 100 çağrı/gün (Developer)
  static const String newsApi = '';

  // ═══════════════════════════════════════════════════════════════════
  // 4. COINGECKO - Kripto Para API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://www.coingecko.com/api
  // ✅ Ücretsiz - API key gerektirmez (rate limit var)
  static const String coinGecko = '';

  // ═══════════════════════════════════════════════════════════════════
  // 5. OPENAI - Sohbet Botu (GPT) API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://platform.openai.com/
  // Ücretli - Kullanım başına ödeme
  static const String openAI = '';

  // ═══════════════════════════════════════════════════════════════════
  // 6. MAPBOX - Harita API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://www.mapbox.com/
  // Ücretsiz plan: 50,000 harita yüklemesi/ay
  static const String mapbox = '';

  // ═══════════════════════════════════════════════════════════════════
  // 7. REST COUNTRIES - Ülke Bilgileri API
  // ═══════════════════════════════════════════════════════════════════
  // URL: https://restcountries.com/
  // ✅ Tamamen ücretsiz - API key gerektirmez
  // (Boş bırakılabilir)

  // ═══════════════════════════════════════════════════════════════════
  // 8. HUGGING FACE - Yapay Zeka Modelleri API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://huggingface.co/
  // Ücretsiz plan mevcut
  static const String huggingFace = '';

  // ═══════════════════════════════════════════════════════════════════
  // 9. FINNHUB - Borsa/Finans API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://finnhub.io/
  // Ücretsiz plan: 60 çağrı/dakika
  static const String finnhub = '';

  // ═══════════════════════════════════════════════════════════════════
  // 10. EXCHANGERATE-API - Döviz Çevirici API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://www.exchangerate-api.com/
  // Ücretsiz plan: 1500 çağrı/ay
  static const String exchangeRate = '';

  // ═══════════════════════════════════════════════════════════════════
  // 11. DEEPAI - Görsel Üretme API
  // ═══════════════════════════════════════════════════════════════════
  // Kayıt: https://deepai.org/
  // Ücretsiz deneme mevcut
  static const String deepAI = '';
}
