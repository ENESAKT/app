import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_keys.dart';

/// Hugging Face - Yapay Zeka Modelleri Servisi
///
/// API: https://huggingface.co/
/// Ücretsiz plan mevcut
class AiModelsService {
  static const String _baseUrl = 'https://api-inference.huggingface.co/models';

  /// Metinden metne dönüştürme (text generation)
  Future<AiTextResponse> generateText({
    required String model,
    required String prompt,
    Map<String, dynamic>? options,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$model');
      final payload = {
        'inputs': prompt,
        'options': options ?? {'wait_for_model': true},
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.huggingFace}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
          return AiTextResponse(text: data[0]['generated_text'] ?? '');
        } else {
          throw AiModelsException(
            'Geçersiz yanıt formatı',
            response.statusCode,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw AiModelsException(
          errorData['error'] ?? 'Metin üretimi başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AiModelsException) rethrow;
      throw AiModelsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Metin sınıflandırma
  Future<List<AiClassification>> classifyText({
    required String model,
    required String text,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$model');
      final payload = {
        'inputs': text,
        'options': {'wait_for_model': true},
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.huggingFace}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final List<Map<String, dynamic>> labels = data[0];
          return labels
              .map((label) => AiClassification.fromJson(label))
              .toList();
        } else {
          throw AiModelsException(
            'Sınıflandırma başarısız',
            response.statusCode,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw AiModelsException(
          errorData['error'] ?? 'Metin sınıflandırma başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AiModelsException) rethrow;
      throw AiModelsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Görüntüden metne dönüştürme (image to text)
  Future<AiImageCaption> generateImageCaption({
    required String model,
    required String imageUrl,
  }) async {
    try {
      // First download the image
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw AiModelsException(
          'Görüntü indirilemedi',
          imageResponse.statusCode,
        );
      }

      final uri = Uri.parse('$_baseUrl/$model');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.huggingFace}',
          'Content-Type': 'image/jpeg',
        },
        body: imageResponse.bodyBytes,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
          return AiImageCaption(caption: data[0]['generated_text'] ?? '');
        } else {
          throw AiModelsException(
            'Geçersiz yanıt formatı',
            response.statusCode,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw AiModelsException(
          errorData['error'] ?? 'Görüntü açıklaması başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AiModelsException) rethrow;
      throw AiModelsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Metinden görüntü üretimi (text to image)
  Future<AiImageGeneration> generateImage({
    required String model,
    required String prompt,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$model');
      final payload = {
        'inputs': prompt,
        'options': {'wait_for_model': true},
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.huggingFace}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        // Response is binary image data
        return AiImageGeneration(imageBytes: response.bodyBytes);
      } else {
        final errorData = json.decode(response.body);
        throw AiModelsException(
          errorData['error'] ?? 'Görüntü üretimi başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AiModelsException) rethrow;
      throw AiModelsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Model durumu kontrolü
  Future<ModelStatus> getModelStatus(String model) async {
    try {
      final uri = Uri.parse('$_baseUrl/$model/status');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${ApiKeys.huggingFace}'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ModelStatus.fromJson(data);
      } else {
        throw AiModelsException('Model durumu alınamadı', response.statusCode);
      }
    } catch (e) {
      if (e is AiModelsException) rethrow;
      throw AiModelsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Yaygın Hugging Face modelleri
  static const List<HfModel> commonModels = [
    HfModel('gpt2', 'text-generation', 'GPT-2 - Metin Üretimi'),
    HfModel('bert-base-uncased', 'fill-mask', 'BERT - Maskelenmiş Dil Modeli'),
    HfModel(
      'distilbert-base-uncased',
      'fill-mask',
      'DistilBERT - Hızlandırılmış BERT',
    ),
    HfModel(
      'facebook/bart-large-cnn',
      'summarization',
      'BART - Metin Özetleme',
    ),
    HfModel(
      'openai/whisper-base',
      'automatic-speech-recognition',
      'Whisper - Ses Tanıma',
    ),
    HfModel(
      'nlpconnect/vit-gpt2-image-captioning',
      'image-to-text',
      'ViT-GPT2 - Görüntü Açıklama',
    ),
    HfModel(
      'stabilityai/stable-diffusion-2-1',
      'text-to-image',
      'Stable Diffusion - Görüntü Üretimi',
    ),
  ];
}

/// AI Metin Yanıtı Modeli
class AiTextResponse {
  final String text;

  AiTextResponse({required this.text});
}

/// AI Sınıflandırma Modeli
class AiClassification {
  final String label;
  final double score;

  AiClassification({required this.label, required this.score});

  factory AiClassification.fromJson(Map<String, dynamic> json) {
    return AiClassification(
      label: json['label'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// AI Görüntü Açıklaması Modeli
class AiImageCaption {
  final String caption;

  AiImageCaption({required this.caption});
}

/// AI Görüntü Üretimi Modeli
class AiImageGeneration {
  final List<int> imageBytes;

  AiImageGeneration({required this.imageBytes});
}

/// Model Durumu Modeli
class ModelStatus {
  final String modelId;
  final String sha;
  final String pipelineTag;
  final bool private;
  final bool disabled;
  final String? gpu;
  final int? inferenceTime;

  ModelStatus({
    required this.modelId,
    required this.sha,
    required this.pipelineTag,
    required this.private,
    required this.disabled,
    this.gpu,
    this.inferenceTime,
  });

  factory ModelStatus.fromJson(Map<String, dynamic> json) {
    return ModelStatus(
      modelId: json['model_id'] ?? '',
      sha: json['sha'] ?? '',
      pipelineTag: json['pipeline_tag'] ?? '',
      private: json['private'] ?? false,
      disabled: json['disabled'] ?? false,
      gpu: json['gpu'],
      inferenceTime: json['inferenceTime'],
    );
  }
}

/// Hugging Face Model Bilgisi
class HfModel {
  final String id;
  final String task;
  final String name;

  const HfModel(this.id, this.task, this.name);
}

/// AI Models API Hatası
class AiModelsException implements Exception {
  final String message;
  final int statusCode;

  AiModelsException(this.message, this.statusCode);

  @override
  String toString() => 'AiModelsException: $message (Code: $statusCode)';
}
