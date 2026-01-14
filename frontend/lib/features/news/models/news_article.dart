/// Haber Makalesi Modeli
///
/// NewsAPI'den dönen haber verilerini temsil eder.

class NewsArticle {
  final String title;
  final String? description;
  final String? content;
  final String? urlToImage;
  final String url;
  final String source;
  final String? sourceId;
  final DateTime publishedAt;
  final String? author;

  NewsArticle({
    required this.title,
    this.description,
    this.content,
    this.urlToImage,
    required this.url,
    required this.source,
    this.sourceId,
    required this.publishedAt,
    this.author,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Başlık Yok',
      description: json['description'],
      content: json['content'],
      urlToImage: json['urlToImage'],
      url: json['url'] ?? '',
      source: json['source']?['name'] ?? 'Bilinmeyen Kaynak',
      sourceId: json['source']?['id'],
      publishedAt:
          DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      author: json['author'],
    );
  }

  /// Yayın tarihini formatla
  String get publishedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 7) {
      return '${publishedAt.day}.${publishedAt.month}.${publishedAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  /// Kısa açıklama
  String get shortDescription {
    if (description == null) return '';
    if (description!.length <= 100) return description!;
    return '${description!.substring(0, 100)}...';
  }

  /// Yazar ve kaynak bilgisi
  String get authorInfo {
    if (author != null && author!.isNotEmpty) {
      return '$author • $source';
    }
    return source;
  }
}

/// Haber Kategorileri
enum NewsCategory {
  general('general', 'Genel', '📰'),
  business('business', 'İş Dünyası', '💼'),
  technology('technology', 'Teknoloji', '💻'),
  science('science', 'Bilim', '🔬'),
  health('health', 'Sağlık', '🏥'),
  sports('sports', 'Spor', '⚽'),
  entertainment('entertainment', 'Eğlence', '🎬');

  final String value;
  final String label;
  final String emoji;

  const NewsCategory(this.value, this.label, this.emoji);
}

/// Ülke Kodları
class NewsCountry {
  static const Map<String, String> countries = {
    'tr': '🇹🇷 Türkiye',
    'us': '🇺🇸 ABD',
    'gb': '🇬🇧 İngiltere',
    'de': '🇩🇪 Almanya',
    'fr': '🇫🇷 Fransa',
  };
}
