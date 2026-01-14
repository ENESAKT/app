import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/unsplash_photo.dart';

/// Picsum + Lorem Picsum API Servisi (ÜCRETSİZ - API KEY GEREKTİRMEZ)
///
/// Unsplash yerine kullanılabilecek ücretsiz alternatif.
///
/// Ayrıca Pexels benzeri ücretsiz kaynaklar:
/// - Lorem Picsum: https://picsum.photos/
/// - Lorem Space: https://lorem.space/
class UnsplashService {
  static const String _picsumUrl = 'https://picsum.photos';

  /// Rastgele/popüler fotoğrafları getir
  Future<List<UnsplashPhoto>> getPhotos({
    int page = 1,
    int perPage = 20,
    String orderBy = 'popular',
  }) async {
    try {
      final uri = Uri.parse('$_picsumUrl/v2/list').replace(
        queryParameters: {'page': page.toString(), 'limit': perPage.toString()},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UnsplashPhoto.fromPicsum(json)).toList();
      } else {
        throw UnsplashException('Fotoğraflar yüklenemedi', response.statusCode);
      }
    } catch (e) {
      if (e is UnsplashException) rethrow;
      throw UnsplashException('Bağlantı hatası: $e', 0);
    }
  }

  /// Fotoğraf ara (Picsum aramayı desteklemiyor, benzer fotoğraflar döndür)
  Future<UnsplashSearchResult> searchPhotos(
    String query, {
    int page = 1,
    int perPage = 20,
    String? color,
    String? orientation,
  }) async {
    try {
      // Picsum arama desteklemiyor ama seed ile tutarlı sonuçlar verebiliriz
      final seed = query.hashCode.abs();
      final photos = <UnsplashPhoto>[];

      for (int i = 0; i < perPage; i++) {
        final id = (seed + i + (page - 1) * perPage) % 1000;
        photos.add(UnsplashPhoto.fromPicsumSeed(id.toString(), query));
      }

      return UnsplashSearchResult(total: 1000, totalPages: 50, photos: photos);
    } catch (e) {
      if (e is UnsplashException) rethrow;
      throw UnsplashException('Bağlantı hatası: $e', 0);
    }
  }

  /// Tek fotoğraf detayını getir
  Future<UnsplashPhoto> getPhotoById(String id) async {
    try {
      final uri = Uri.parse('$_picsumUrl/id/$id/info');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UnsplashPhoto.fromPicsum(data);
      } else {
        throw UnsplashException('Fotoğraf bulunamadı', response.statusCode);
      }
    } catch (e) {
      if (e is UnsplashException) rethrow;
      throw UnsplashException('Bağlantı hatası: $e', 0);
    }
  }

  /// Koleksiyonları getir (Demo veriler)
  Future<List<UnsplashCollection>> getCollections({
    int page = 1,
    int perPage = 10,
  }) async {
    // Demo koleksiyonlar
    return [
      UnsplashCollection(
        id: '1',
        title: 'Doğa',
        description: 'Doğa fotoğrafları',
        totalPhotos: 100,
        coverPhotoUrl: 'https://picsum.photos/seed/nature/400/300',
      ),
      UnsplashCollection(
        id: '2',
        title: 'Şehir',
        description: 'Şehir manzaraları',
        totalPhotos: 80,
        coverPhotoUrl: 'https://picsum.photos/seed/city/400/300',
      ),
      UnsplashCollection(
        id: '3',
        title: 'Teknoloji',
        description: 'Teknoloji görselleri',
        totalPhotos: 60,
        coverPhotoUrl: 'https://picsum.photos/seed/tech/400/300',
      ),
    ];
  }
}

/// Arama Sonucu Modeli
class UnsplashSearchResult {
  final int total;
  final int totalPages;
  final List<UnsplashPhoto> photos;

  UnsplashSearchResult({
    required this.total,
    required this.totalPages,
    required this.photos,
  });

  factory UnsplashSearchResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> results = json['results'] ?? [];
    return UnsplashSearchResult(
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      photos: results.map((p) => UnsplashPhoto.fromJson(p)).toList(),
    );
  }
}

/// Koleksiyon Modeli
class UnsplashCollection {
  final String id;
  final String title;
  final String? description;
  final int totalPhotos;
  final String? coverPhotoUrl;

  UnsplashCollection({
    required this.id,
    required this.title,
    this.description,
    required this.totalPhotos,
    this.coverPhotoUrl,
  });

  factory UnsplashCollection.fromJson(Map<String, dynamic> json) {
    return UnsplashCollection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      totalPhotos: json['total_photos'] ?? 0,
      coverPhotoUrl: json['cover_photo']?['urls']?['regular'],
    );
  }
}

/// Unsplash API Hatası
class UnsplashException implements Exception {
  final String message;
  final int statusCode;

  UnsplashException(this.message, this.statusCode);

  @override
  String toString() => 'UnsplashException: $message (Code: $statusCode)';
}
