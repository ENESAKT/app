// Chat Feature Service - Mentor GPT
// Bu servis, AI chat özelliği için işlevler sağlar

import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/api_keys.dart';

/// Mentor GPT Service - AI sohbet servisi
class MentorGptService {
  GenerativeModel? _model;
  ChatSession? _chat;

  /// AI modelini başlat
  void initialize() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: ApiKeys.googleGemini,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );

    // Mentor GPT için sistem promptu ile chat başlat
    _chat = _model?.startChat(
      history: [
        Content.text(_systemPrompt),
        Content.model([TextPart(_welcomeMessage)]),
      ],
    );
  }

  /// Sistem promptu - Mentor GPT'nin karakteri
  static const String _systemPrompt = '''
Sen "Mentor GPT" adında bir kişisel gelişim ve kariyer mentorüsün.
Kullanıcılara:
- Kariyer tavsiyeleri
- Kişisel gelişim önerileri
- Motivasyon desteği
- Hedef belirleme yardımı
- Teknik konularda rehberlik
sağlıyorsun.

Özelliklerin:
- Arkadaş canlısı ve destekleyici bir ton kullan
- Emoji kullanarak mesajlarını renklendir
- Kısa ve öz cevaplar ver
- Pratik ve uygulanabilir öneriler sun
- Türkçe yanıt ver
''';

  /// Hoşgeldin mesajı
  static const String _welcomeMessage = '''
Merhaba! 👋 Ben Mentor GPT, kişisel AI asistanınızım.

Size kariyer, kişisel gelişim, teknik konular ve daha fazlasında yardımcı olabilirim. Nasıl yardımcı olabilirim?
''';

  /// AI'a mesaj gönder ve yanıt al
  Future<String> sendMessage(String message) async {
    if (_model == null || _chat == null) {
      initialize();
    }

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? 'Yanıt alınamadı.';
    } catch (e) {
      print('❌ Mentor GPT hatası: $e');
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Sohbeti sıfırla
  void resetChat() {
    _chat = _model?.startChat(
      history: [
        Content.text(_systemPrompt),
        Content.model([TextPart(_welcomeMessage)]),
      ],
    );
  }

  /// Hoşgeldin mesajını döndür
  String getWelcomeMessage() {
    return _welcomeMessage;
  }
}
