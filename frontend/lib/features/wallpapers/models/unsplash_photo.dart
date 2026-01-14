/// Unsplash / Lorem Picsum Fotoğraf Modeli
///
/// Her iki API'den dönen fotoğraf verilerini temsil eder.

class UnsplashPhoto {
  final String id;
  final String? description;
  final String? altDescription;
  final int width;
  final int height;
  final String color;
  final UnsplashUrls urls;
  final UnsplashUser user;
  final int likes;
  final DateTime createdAt;

  UnsplashPhoto({
    required this.id,
    this.description,
    this.altDescription,
    required this.width,
    required this.height,
    required this.color,
    required this.urls,
    required this.user,
    required this.likes,
    required this.createdAt,
  });

  /// Unsplash API parser
  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    return UnsplashPhoto(
      id: json['id'] ?? '',
      description: json['description'],
      altDescription: json['alt_description'],
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      color: json['color'] ?? '#CCCCCC',
      urls: UnsplashUrls.fromJson(json['urls'] ?? {}),
      user: UnsplashUser.fromJson(json['user'] ?? {}),
      likes: json['likes'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Lorem Picsum API parser (ÜCRETSİZ)
  factory UnsplashPhoto.fromPicsum(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '0';
    final width = json['width'] ?? 1920;
    final height = json['height'] ?? 1080;
    final author = json['author'] ?? 'Unknown';
    final downloadUrl = json['download_url'] ?? '';

    return UnsplashPhoto(
      id: id,
      description: 'Photo by $author',
      altDescription: 'Beautiful landscape photograph',
      width: width,
      height: height,
      color: _generateColorFromId(id),
      urls: UnsplashUrls(
        raw: downloadUrl,
        full: 'https://picsum.photos/id/$id/$width/$height',
        regular: 'https://picsum.photos/id/$id/1080/720',
        small: 'https://picsum.photos/id/$id/400/300',
        thumb: 'https://picsum.photos/id/$id/200/150',
      ),
      user: UnsplashUser(
        id: author.hashCode.toString(),
        username: author.toLowerCase().replaceAll(' ', '_'),
        name: author,
        bio: 'Photographer on Lorem Picsum',
        profileImage: 'https://i.pravatar.cc/150?u=$author',
        portfolioUrl: 'https://picsum.photos',
      ),
      likes: (id.hashCode % 1000).abs(),
      createdAt: DateTime.now().subtract(Duration(days: id.hashCode % 365)),
    );
  }

  /// Seed-based Picsum photo (arama için)
  factory UnsplashPhoto.fromPicsumSeed(String seed, String query) {
    final id = seed;
    final width = 1920;
    final height = 1080;

    return UnsplashPhoto(
      id: id,
      description: 'Photo related to "$query"',
      altDescription: query,
      width: width,
      height: height,
      color: _generateColorFromId(id),
      urls: UnsplashUrls(
        raw: 'https://picsum.photos/seed/$query$id/$width/$height',
        full: 'https://picsum.photos/seed/$query$id/$width/$height',
        regular: 'https://picsum.photos/seed/$query$id/1080/720',
        small: 'https://picsum.photos/seed/$query$id/400/300',
        thumb: 'https://picsum.photos/seed/$query$id/200/150',
      ),
      user: UnsplashUser(
        id: id,
        username: 'picsum_$id',
        name: 'Picsum Artist $id',
        bio: 'Contributing to open-source imagery',
        profileImage: 'https://i.pravatar.cc/150?u=$id',
        portfolioUrl: 'https://picsum.photos',
      ),
      likes: (int.tryParse(id) ?? 0) * 3,
      createdAt: DateTime.now().subtract(Duration(days: int.tryParse(id) ?? 0)),
    );
  }

  /// ID'den renk üret
  static String _generateColorFromId(String id) {
    final colors = [
      '#E91E63',
      '#9C27B0',
      '#673AB7',
      '#3F51B5',
      '#2196F3',
      '#03A9F4',
      '#00BCD4',
      '#009688',
      '#4CAF50',
      '#8BC34A',
      '#CDDC39',
      '#FFEB3B',
      '#FFC107',
      '#FF9800',
      '#FF5722',
      '#795548',
    ];
    return colors[(id.hashCode % colors.length).abs()];
  }

  /// Aspect ratio hesapla (Masonry grid için)
  double get aspectRatio => width / height;

  /// Hex color'ı Flutter Color'a çevir
  int get colorValue {
    String hex = color.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return int.parse(hex, radix: 16);
  }
}

/// Unsplash URL'leri
class UnsplashUrls {
  final String raw;
  final String full;
  final String regular;
  final String small;
  final String thumb;

  UnsplashUrls({
    required this.raw,
    required this.full,
    required this.regular,
    required this.small,
    required this.thumb,
  });

  factory UnsplashUrls.fromJson(Map<String, dynamic> json) {
    return UnsplashUrls(
      raw: json['raw'] ?? '',
      full: json['full'] ?? '',
      regular: json['regular'] ?? '',
      small: json['small'] ?? '',
      thumb: json['thumb'] ?? '',
    );
  }
}

/// Unsplash Kullanıcı Bilgisi
class UnsplashUser {
  final String id;
  final String username;
  final String name;
  final String? bio;
  final String? profileImage;
  final String? portfolioUrl;

  UnsplashUser({
    required this.id,
    required this.username,
    required this.name,
    this.bio,
    this.profileImage,
    this.portfolioUrl,
  });

  factory UnsplashUser.fromJson(Map<String, dynamic> json) {
    return UnsplashUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? 'Unknown',
      bio: json['bio'],
      profileImage: json['profile_image']?['medium'],
      portfolioUrl: json['portfolio_url'],
    );
  }
}
