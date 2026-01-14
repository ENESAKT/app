/// Super App - Merkezi API Anahtarları
///
/// Tüm harici API anahtarları burada tutulur.
/// ⚠️ GÜVENLİK: Bu dosyayı .gitignore'a ekleyin!
///
/// Kullanım:
/// ```dart
/// import 'package:frontend/core/constants/api_keys.dart';
/// final url = '[https://api.example.com?key=$](https://api.example.com?key=$){ApiKeys.openWeatherMap}';
/// ```
class ApiKeys {
  // Private constructor - instance oluşturulamaz
  ApiKeys._();

  // ═══════════════════════════════════════════════════════════════════
  // 1. OPENWEATHERMAP - Hava Durumu API
  // ═══════════════════════════════════════════════════════════════════
  static const String openWeatherMap = '';

  // ═══════════════════════════════════════════════════════════════════
  // 2. UNSPLASH - Duvar Kağıdı/Görsel API
  // ═══════════════════════════════════════════════════════════════════
  static const String unsplash = '';

  // ═══════════════════════════════════════════════════════════════════
  // 3. NEWSAPI - Haber API
  // ═══════════════════════════════════════════════════════════════════
  static const String newsApi = '';

  // ═══════════════════════════════════════════════════════════════════
  // 4. COINGECKO - Kripto Para API
  // ═══════════════════════════════════════════════════════════════════
  // Not: Public key olduğu için bazen izin verilir ama boşaltmak en temizi
  static const String coinGecko = ''; 

  // ═══════════════════════════════════════════════════════════════════
  // 5. OPENAI - Sohbet Botu (GPT) / Google Gemini API
  // ═══════════════════════════════════════════════════════════════════
  // ⚠️ GÜVENLİK: API Key silindi (GitHub'a gönderilmemeli)
  static const String googleGemini = '';

  // ═══════════════════════════════════════════════════════════════════
  // 6. GEOAPIFY - Harita API
  // ═══════════════════════════════════════════════════════════════════
  static const String geoapify = '';  

  // ═══════════════════════════════════════════════════════════════════
  // 7. REST COUNTRIES - Ülke Bilgileri API
  // ═══════════════════════════════════════════════════════════════════
  static const String restCountries = ''; 

  // ═══════════════════════════════════════════════════════════════════
  // 8. HUGGING FACE - Yapay Zeka Modelleri API
  // ═══════════════════════════════════════════════════════════════════
  // ⚠️ GÜVENLİK: API Key silindi (Push hatasına sebep olan buydu!)
  static const String huggingFace = '';

  // ═══════════════════════════════════════════════════════════════════
  // 9. FINNHUB - Borsa/Finans API
  // ═══════════════════════════════════════════════════════════════════
  static const String finnhub = '';

  // ═══════════════════════════════════════════════════════════════════
  // 10. EXCHANGERATE-API - Döviz Çevirici API
  // ═══════════════════════════════════════════════════════════════════
  static const String exchangeRate = '';

  // ═══════════════════════════════════════════════════════════════════
  // 11. DEEPAI - Görsel Üretme API
  // ═══════════════════════════════════════════════════════════════════
  static const String deepAI = '';
}