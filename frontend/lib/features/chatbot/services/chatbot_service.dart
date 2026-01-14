import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_keys.dart';

/// OpenAI - Sohbet Botu Servisi
///
/// API: https://platform.openai.com/
/// Ücretli - Kullanım başına ödeme
class ChatbotService {
  static const String _baseUrl = 'https://api.openai.com/v1';

  /// Sohbet tamamlama (chat completion)
  Future<ChatCompletionResponse> createChatCompletion({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 1000,
    double topP = 1.0,
    double frequencyPenalty = 0.0,
    double presencePenalty = 0.0,
  }) async {
    try {
      if (ApiKeys.openAI.isEmpty) {
        throw ChatbotException('OpenAI API anahtarı ayarlanmamış', 0);
      }

      final uri = Uri.parse('$_baseUrl/chat/completions');

      final payload = {
        'model': model,
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'temperature': temperature,
        'max_tokens': maxTokens,
        'top_p': topP,
        'frequency_penalty': frequencyPenalty,
        'presence_penalty': presencePenalty,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAI}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ChatCompletionResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw ChatbotException(
          errorData['error']['message'] ?? 'Sohbet yanıtı başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatbotException) rethrow;
      throw ChatbotException('Bağlantı hatası: $e', 0);
    }
  }

  /// Basit bir sohbet yöntemi (kullanıcı mesajına yanıt üretir)
  Future<String> sendMessage({
    required String userMessage,
    String model = 'gpt-3.5-turbo',
    List<ChatMessage> conversationHistory = const [],
  }) async {
    try {
      final messages = [
        ...conversationHistory,
        ChatMessage(role: 'user', content: userMessage),
      ];

      final response = await createChatCompletion(
        model: model,
        messages: messages,
      );

      if (response.choices.isNotEmpty) {
        return response.choices.first.message.content;
      } else {
        throw ChatbotException('Geçersiz yanıt alındı', 0);
      }
    } catch (e) {
      if (e is ChatbotException) rethrow;
      throw ChatbotException('Mesaj gönderme hatası: $e', 0);
    }
  }

  /// Dallama (turbo) sohbet yöntemi
  Future<Stream<String>> streamChatCompletion({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
  }) async {
    try {
      if (ApiKeys.openAI.isEmpty) {
        throw ChatbotException('OpenAI API anahtarı ayarlanmamış', 0);
      }

      // Note: Streaming requires a different approach and is more complex
      // For now, we'll simulate streaming by returning the full response
      final response = await createChatCompletion(
        model: model,
        messages: messages,
        temperature: temperature,
      );

      // Simulate streaming by splitting the response
      final content = response.choices.isNotEmpty
          ? response.choices.first.message.content
          : '';
      final parts = content.split(' ');

      return Stream.fromIterable(parts.map((part) => '$part '));
    } catch (e) {
      if (e is ChatbotException) rethrow;
      throw ChatbotException('Akış hatası: $e', 0);
    }
  }

  /// Mevcut sohbet modellerini listele
  Future<List<ChatModel>> listModels() async {
    try {
      if (ApiKeys.openAI.isEmpty) {
        throw ChatbotException('OpenAI API anahtarı ayarlanmamış', 0);
      }

      final uri = Uri.parse('$_baseUrl/models');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${ApiKeys.openAI}'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> modelsData = data['data'];
        return modelsData
            .map((modelData) => ChatModel.fromJson(modelData))
            .toList();
      } else {
        final errorData = json.decode(response.body);
        throw ChatbotException(
          errorData['error']['message'] ?? 'Modeller alınamadı',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ChatbotException) rethrow;
      throw ChatbotException('Model listeleme hatası: $e', 0);
    }
  }

  /// Kullanıcıya özel sistem mesajı ile sohbet başlat
  Future<ChatCompletionResponse> startConversation({
    required String userPrompt,
    String systemPrompt = 'Sen yardımcı bir yapay zekasın.',
    String model = 'gpt-3.5-turbo',
  }) async {
    try {
      final messages = [
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(role: 'user', content: userPrompt),
      ];

      return await createChatCompletion(model: model, messages: messages);
    } catch (e) {
      if (e is ChatbotException) rethrow;
      throw ChatbotException('Sohbet başlatma hatası: $e', 0);
    }
  }
}

/// Sohbet Mesajı Modeli
class ChatMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

/// Sohbet Tamamlama Yanıtı Modeli
class ChatCompletionResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChatChoice> choices;
  final Map<String, dynamic>? usage;

  ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id'] ?? '',
      object: json['object'] ?? '',
      created: json['created'] ?? 0,
      model: json['model'] ?? '',
      choices: (json['choices'] as List<dynamic>)
          .map((choice) => ChatChoice.fromJson(choice))
          .toList(),
      usage: json['usage'] as Map<String, dynamic>?,
    );
  }
}

/// Sohbet Seçeneği Modeli
class ChatChoice {
  final int index;
  final ChatMessage message;
  final String? finishReason;

  ChatChoice({required this.index, required this.message, this.finishReason});

  factory ChatChoice.fromJson(Map<String, dynamic> json) {
    return ChatChoice(
      index: json['index'] ?? 0,
      message: ChatMessage.fromJson(json['message']),
      finishReason: json['finish_reason'],
    );
  }
}

/// Sohbet Modeli
class ChatModel {
  final String id;
  final String object;
  final int created;
  final Map<String, dynamic>? ownedBy;

  ChatModel({
    required this.id,
    required this.object,
    required this.created,
    this.ownedBy,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      object: json['object'] ?? '',
      created: json['created'] ?? 0,
      ownedBy: json['owned_by'] as Map<String, dynamic>?,
    );
  }
}

/// Chatbot API Hatası
class ChatbotException implements Exception {
  final String message;
  final int statusCode;

  ChatbotException(this.message, this.statusCode);

  @override
  String toString() => 'ChatbotException: $message (Code: $statusCode)';
}
