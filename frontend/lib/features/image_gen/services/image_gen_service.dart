import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_keys.dart';

/// DeepAI - Görsel Üretme Servisi
///
/// API: https://deepai.org/
/// Ücretsiz deneme mevcut
class ImageGenService {
  static const String _baseUrl = 'https://api.deepai.org/api';

  /// Metinden görsel üretimi (text to image)
  Future<ImageGenerationResult> generateImageFromText({
    required String text,
    String model = 'text2img', // Default model
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      if (ApiKeys.deepAI.isEmpty) {
        throw ImageGenException('DeepAI API anahtarı ayarlanmamış', 0);
      }

      final uri = Uri.parse('$_baseUrl/$model');

      final payload = {'text': text, ...?additionalParams};

      final response = await http.post(
        uri,
        headers: {'api-key': ApiKeys.deepAI},
        body: payload,
      );

      if (response.statusCode == 200) {
        // Response typically contains JSON with output URL
        final Map<String, dynamic> data = json.decode(response.body);
        final String outputUrl = data['output_url'] ?? '';
        return ImageGenerationResult(
          imageUrl: outputUrl,
          taskId: data['id'],
          status: 'completed',
        );
      } else {
        final errorData = json.decode(response.body);
        throw ImageGenException(
          errorData['error'] ?? 'Görüntü üretimi başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ImageGenException) rethrow;
      throw ImageGenException('Bağlantı hatası: $e', 0);
    }
  }

  /// Varolan görseli işleme (image processing)
  Future<ImageProcessingResult> processImage({
    required String imageUrl,
    String model = 'torch-srgan', // Default enhancement model
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      if (ApiKeys.deepAI.isEmpty) {
        throw ImageGenException('DeepAI API anahtarı ayarlanmamış', 0);
      }

      final uri = Uri.parse('$_baseUrl/$model');

      final payload = {'image': imageUrl, ...?additionalParams};

      final response = await http.post(
        uri,
        headers: {'api-key': ApiKeys.deepAI},
        body: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String outputUrl = data['output_url'] ?? '';
        return ImageProcessingResult(
          processedImageUrl: outputUrl,
          originalImageUrl: imageUrl,
          taskId: data['id'],
        );
      } else {
        final errorData = json.decode(response.body);
        throw ImageGenException(
          errorData['error'] ?? 'Görüntü işleme başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ImageGenException) rethrow;
      throw ImageGenException('Bağlantı hatası: $e', 0);
    }
  }

  /// NSFW (not safe for work) içeriği tespiti
  Future<NsfwDetectionResult> detectNsfwContent(String imageUrl) async {
    try {
      if (ApiKeys.deepAI.isEmpty) {
        throw ImageGenException('DeepAI API anahtarı ayarlanmamış', 0);
      }

      final uri = Uri.parse('$_baseUrl/nsfw-detector');

      final payload = {'image': imageUrl};

      final response = await http.post(
        uri,
        headers: {'api-key': ApiKeys.deepAI},
        body: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return NsfwDetectionResult.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw ImageGenException(
          errorData['error'] ?? 'NSFW tespiti başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ImageGenException) rethrow;
      throw ImageGenException('Bağlantı hatası: $e', 0);
    }
  }

  /// Görsel etiketleme (image tagging)
  Future<ImageTaggingResult> tagImage(String imageUrl) async {
    try {
      if (ApiKeys.deepAI.isEmpty) {
        throw ImageGenException('DeepAI API anahtarı ayarlanmamış', 0);
      }

      final uri = Uri.parse('$_baseUrl/densecap');

      final payload = {'image': imageUrl};

      final response = await http.post(
        uri,
        headers: {'api-key': ApiKeys.deepAI},
        body: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ImageTaggingResult.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw ImageGenException(
          errorData['error'] ?? 'Görüntü etiketleme başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ImageGenException) rethrow;
      throw ImageGenException('Bağlantı hatası: $e', 0);
    }
  }

  /// Jeneratif görsel üretimi (advanced image generation)
  Future<ImageGenerationResult> generateAdvancedImage({
    required String prompt,
    String model = 'text2img',
    int batchSize = 1,
    String imageHeight = '512',
    String imageWidth = '512',
  }) async {
    try {
      if (ApiKeys.deepAI.isEmpty) {
        throw ImageGenException('DeepAI API anahtarı ayarlanmamış', 0);
      }

      final uri = Uri.parse('$_baseUrl/$model');

      final payload = {
        'prompt': prompt,
        'batch_size': batchSize.toString(),
        'height': imageHeight,
        'width': imageWidth,
      };

      final response = await http.post(
        uri,
        headers: {'api-key': ApiKeys.deepAI},
        body: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String outputUrl = data['output_url'] ?? '';
        return ImageGenerationResult(
          imageUrl: outputUrl,
          taskId: data['id'],
          status: 'completed',
        );
      } else {
        final errorData = json.decode(response.body);
        throw ImageGenException(
          errorData['error'] ?? 'Gelişmiş görüntü üretimi başarısız',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ImageGenException) rethrow;
      throw ImageGenException('Bağlantı hatası: $e', 0);
    }
  }
}

/// Görsel Üretim Sonucu Modeli
class ImageGenerationResult {
  final String imageUrl;
  final String? taskId;
  final String status;

  ImageGenerationResult({
    required this.imageUrl,
    this.taskId,
    required this.status,
  });
}

/// Görsel İşleme Sonucu Modeli
class ImageProcessingResult {
  final String processedImageUrl;
  final String originalImageUrl;
  final String? taskId;

  ImageProcessingResult({
    required this.processedImageUrl,
    required this.originalImageUrl,
    this.taskId,
  });
}

/// NSFW Tespiti Sonucu Modeli
class NsfwDetectionResult {
  final double nsfwScore;
  final double safeScore;
  final String imageUrl;

  NsfwDetectionResult({
    required this.nsfwScore,
    required this.safeScore,
    required this.imageUrl,
  });

  factory NsfwDetectionResult.fromJson(Map<String, dynamic> json) {
    final output = json['output'] as Map<String, dynamic>?;
    return NsfwDetectionResult(
      nsfwScore: (output?['nsfw_score'] as num?)?.toDouble() ?? 0.0,
      safeScore: (output?['safe_score'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['output_url'] ?? '',
    );
  }
}

/// Görsel Etiketleme Sonucu Modeli
class ImageTaggingResult {
  final List<ImageTag> tags;
  final String imageUrl;

  ImageTaggingResult({required this.tags, required this.imageUrl});

  factory ImageTaggingResult.fromJson(Map<String, dynamic> json) {
    final List<ImageTag> tags = [];
    final output = json['output'] as Map<String, dynamic>?;
    final captions = output?['captions'] as List<dynamic>? ?? [];

    for (final caption in captions) {
      if (caption is Map<String, dynamic>) {
        tags.add(
          ImageTag(
            text: caption['caption'] ?? '',
            confidence: (caption['confidence'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }
    }

    return ImageTaggingResult(tags: tags, imageUrl: json['output_url'] ?? '');
  }
}

/// Görsel Etiketi Modeli
class ImageTag {
  final String text;
  final double confidence;

  ImageTag({required this.text, required this.confidence});
}

/// Image Gen API Hatası
class ImageGenException implements Exception {
  final String message;
  final int statusCode;

  ImageGenException(this.message, this.statusCode);

  @override
  String toString() => 'ImageGenException: $message (Code: $statusCode)';
}
