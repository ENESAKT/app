import '../models/news_article.dart';

/// GNews / MediaStack API Servisi (ÜCRETSİZ ALTERNATİF)
///
/// NewsAPI yerine ücretsiz API kullanımı.
/// Not: Ücretsiz API'lar sınırlı olduğu için demo veriler de dahil edildi.
///
/// Alternatifler:
/// - GNews API: https://gnews.io/ (10 çağrı/gün ücretsiz)
/// - MediaStack: https://mediastack.com/ (500 çağrı/ay ücretsiz)
/// - Currents API: https://currentsapi.services/
class NewsService {
  // Demo haber verileri (API key olmadan çalışması için)
  static final List<Map<String, dynamic>> _demoNews = [
    {
      'title': 'Yapay Zeka Teknolojisinde Çığır Açan Gelişme',
      'description':
          'Yeni nesil yapay zeka modeli, insan benzeri akıl yürütme yetenekleri sergiliyor. Uzmanlar bu gelişmenin sektörü köklü bir şekilde değiştireceğini öngörüyor.',
      'urlToImage': 'https://picsum.photos/seed/ai-news/800/450',
      'url': 'https://example.com/ai-news',
      'source': {'name': 'Teknoloji Haber'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
      'author': 'Teknoloji Editörü',
    },
    {
      'title': 'Ekonomide Yeni Dönem: Merkez Bankası Faiz Kararını Açıkladı',
      'description':
          'Merkez Bankası, beklentilerin üzerinde bir faiz kararı alarak piyasaları şaşırttı. Analistler bu kararın enflasyonla mücadelede önemli bir adım olduğunu belirtiyor.',
      'urlToImage': 'https://picsum.photos/seed/economy/800/450',
      'url': 'https://example.com/economy',
      'source': {'name': 'Ekonomi Gündem'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 4))
          .toIso8601String(),
      'author': 'Ekonomi Masası',
    },
    {
      'title': 'Süper Lig\'de Hafta Sonu Kritik Maçlar',
      'description':
          'Şampiyonluk yarışında kritik bir hafta sonu yaşanacak. Lider takımın zorlu deplasman maçı, taraftarları heyecanlandırıyor.',
      'urlToImage': 'https://picsum.photos/seed/football/800/450',
      'url': 'https://example.com/sports',
      'source': {'name': 'Spor Arena'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 6))
          .toIso8601String(),
      'author': 'Spor Servisi',
    },
    {
      'title': 'Sağlık Bakanlığı Yeni Kış Tedbirlerini Açıkladı',
      'description':
          'Kış aylarının yaklaşmasıyla birlikte Sağlık Bakanlığı, hastanelerde alınacak yeni tedbirleri kamuoyuyla paylaştı.',
      'urlToImage': 'https://picsum.photos/seed/health/800/450',
      'url': 'https://example.com/health',
      'source': {'name': 'Sağlık Haberleri'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 8))
          .toIso8601String(),
      'author': 'Sağlık Editörü',
    },
    {
      'title': 'Yeni iPhone Modeli Türkiye\'de Satışa Sunuldu',
      'description':
          'Apple\'ın en yeni akıllı telefon modeli bugün itibarıyla Türkiye\'de satışa çıktı. Mağazaların önünde uzun kuyruklar oluştu.',
      'urlToImage': 'https://picsum.photos/seed/iphone/800/450',
      'url': 'https://example.com/tech',
      'source': {'name': 'Teknoloji Dünyası'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 10))
          .toIso8601String(),
      'author': 'Teknoloji Muhabiri',
    },
    {
      'title': 'İstanbul\'da Hava Kirliliği Alarm Seviyesinde',
      'description':
          'Meteoroloji uzmanları, hava kalitesinin tehlikeli seviyelere ulaştığını belirterek vatandaşları dikkatli olmaya çağırdı.',
      'urlToImage': 'https://picsum.photos/seed/weather-news/800/450',
      'url': 'https://example.com/environment',
      'source': {'name': 'Çevre Haberleri'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 12))
          .toIso8601String(),
      'author': 'Çevre Editörü',
    },
    {
      'title': 'Yeni Eğitim-Öğretim Yılı Başladı',
      'description':
          'Milyonlarca öğrenci bugün ders başı yaptı. Milli Eğitim Bakanı, yeni eğitim yılı için önemli açıklamalar yaptı.',
      'urlToImage': 'https://picsum.photos/seed/education/800/450',
      'url': 'https://example.com/education',
      'source': {'name': 'Eğitim Haber'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 14))
          .toIso8601String(),
      'author': 'Eğitim Servisi',
    },
    {
      'title': 'Turizm Sektöründe Rekor! Bu Yıl 50 Milyon Turist Bekleniyor',
      'description':
          'Türkiye turizm sektörü, 2024 yılında tüm zamanların rekorunu kırmaya hazırlanıyor. Otel doluluk oranları yüzde 90\'ı aştı.',
      'urlToImage': 'https://picsum.photos/seed/tourism/800/450',
      'url': 'https://example.com/tourism',
      'source': {'name': 'Turizm Gazetesi'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 16))
          .toIso8601String(),
      'author': 'Turizm Masası',
    },
    {
      'title': 'Elektrikli Araç Satışlarında Patlama Yaşanıyor',
      'description':
          'Elektrikli araç satışları geçen yıla göre yüzde 150 arttı. Yerli otomobil TOGG büyük ilgi görüyor.',
      'urlToImage': 'https://picsum.photos/seed/electric-car/800/450',
      'url': 'https://example.com/auto',
      'source': {'name': 'Otomobil Dünyası'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 18))
          .toIso8601String(),
      'author': 'Otomotiv Editörü',
    },
    {
      'title': 'Netflix Yeni Türk Dizisi İçin Hazırlıklar Başladı',
      'description':
          'Dünya devi Netflix, Türkiye\'de çekeceği yeni dizinin hazırlıklarına başladı. Oyuncu kadrosu yakında açıklanacak.',
      'urlToImage': 'https://picsum.photos/seed/entertainment/800/450',
      'url': 'https://example.com/entertainment',
      'source': {'name': 'Magazin Haber'},
      'publishedAt': DateTime.now()
          .subtract(const Duration(hours: 20))
          .toIso8601String(),
      'author': 'Magazin Servisi',
    },
  ];

  /// Kategoriye göre demo haberler
  static final Map<String, List<Map<String, dynamic>>> _categoryNews = {
    'general': _demoNews,
    'technology': [
      {
        'title': 'Quantum Bilgisayar Devrimi: IBM\'den Çığır Açan Duyuru',
        'description':
            'IBM, dünyanın en güçlü quantum bilgisayarını tanıttı. 1000 kübitlik işlemci, bilim dünyasını heyecanlandırdı.',
        'urlToImage': 'https://picsum.photos/seed/quantum/800/450',
        'url': 'https://example.com/quantum',
        'source': {'name': 'Tech Daily'},
        'publishedAt': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'author': 'Tech Reporter',
      },
      {
        'title': 'ChatGPT\'nin Yeni Versiyonu Türkçe\'yi Çok Daha İyi Anlıyor',
        'description':
            'OpenAI\'ın yeni güncellemesi, Türkçe dil desteğini önemli ölçüde geliştirdi.',
        'urlToImage': 'https://picsum.photos/seed/chatgpt/800/450',
        'url': 'https://example.com/chatgpt',
        'source': {'name': 'AI News'},
        'publishedAt': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'author': 'AI Specialist',
      },
    ],
    'sports': [
      {
        'title': 'Galatasaray, Şampiyonlar Ligi\'nde Tarih Yazdı',
        'description':
            'Sarı-kırmızılılar, güçlü rakibini mağlup ederek gruptan çıkmayı garantiledi.',
        'urlToImage': 'https://picsum.photos/seed/gs/800/450',
        'url': 'https://example.com/gs',
        'source': {'name': 'Spor Sayfası'},
        'publishedAt': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'author': 'Spor Muhabiri',
      },
    ],
    'business': [
      {
        'title': 'Borsa İstanbul\'da Rekor Üstüne Rekor',
        'description':
            'BIST 100 endeksi tüm zamanların en yüksek seviyesini gördü.',
        'urlToImage': 'https://picsum.photos/seed/borsa/800/450',
        'url': 'https://example.com/borsa',
        'source': {'name': 'Finans Gündem'},
        'publishedAt': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'author': 'Finans Editörü',
      },
    ],
    'health': [
      {
        'title': 'Grip Aşısı Kampanyası Başladı',
        'description':
            'Sağlık Bakanlığı, ücretsiz grip aşısı uygulamasını başlattı.',
        'urlToImage': 'https://picsum.photos/seed/vaccine/800/450',
        'url': 'https://example.com/vaccine',
        'source': {'name': 'Sağlık Gündem'},
        'publishedAt': DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
        'author': 'Sağlık Muhabiri',
      },
    ],
    'science': [
      {
        'title': 'NASA\'dan Mars\'ta Su Bulunduğuna Dair Yeni Kanıtlar',
        'description':
            'Mars keşif aracı, kızıl gezegende sıvı su izleri buldu.',
        'urlToImage': 'https://picsum.photos/seed/mars/800/450',
        'url': 'https://example.com/mars',
        'source': {'name': 'Bilim Dünyası'},
        'publishedAt': DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        'author': 'Bilim Editörü',
      },
    ],
    'entertainment': [
      {
        'title': 'Oscar Adayları Açıklandı: Türk Yapımı Film de Listede',
        'description':
            'Akademi Ödülleri için aday gösterilen filmler belli oldu. Türk sineması gurur yaşıyor.',
        'urlToImage': 'https://picsum.photos/seed/oscar/800/450',
        'url': 'https://example.com/oscar',
        'source': {'name': 'Sinema Günlüğü'},
        'publishedAt': DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
        'author': 'Sinema Yazarı',
      },
    ],
  };

  /// Manşetleri getir (Demo veriler kullanılıyor)
  Future<List<NewsArticle>> getTopHeadlines({
    String country = 'tr',
    NewsCategory? category,
    int pageSize = 20,
    int page = 1,
  }) async {
    // Simüle edilmiş gecikme
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      List<Map<String, dynamic>> newsData;

      if (category != null && _categoryNews.containsKey(category.value)) {
        newsData = _categoryNews[category.value]!;
      } else {
        newsData = _demoNews;
      }

      // Sayfalama
      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final paginatedData = newsData.length > start
          ? newsData.sublist(start, end.clamp(0, newsData.length))
          : newsData;

      return paginatedData.map((json) => NewsArticle.fromJson(json)).toList();
    } catch (e) {
      throw NewsException('Haberler yüklenemedi: $e', 0);
    }
  }

  /// Haber ara (Demo veriler içinde arama)
  Future<List<NewsArticle>> searchNews(
    String query, {
    String sortBy = 'publishedAt',
    String language = 'tr',
    int pageSize = 20,
    int page = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final searchResults = _demoNews.where((news) {
        final title = (news['title'] as String).toLowerCase();
        final description =
            (news['description'] as String?)?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase()) ||
            description.contains(query.toLowerCase());
      }).toList();

      return searchResults.map((json) => NewsArticle.fromJson(json)).toList();
    } catch (e) {
      throw NewsException('Arama başarısız: $e', 0);
    }
  }

  /// Kaynaklardan haberleri getir
  Future<List<NewsArticle>> getNewsBySources(
    List<String> sources, {
    int pageSize = 20,
    int page = 1,
  }) async {
    return getTopHeadlines(pageSize: pageSize, page: page);
  }

  /// Mevcut haber kaynaklarını listele
  Future<List<NewsSource>> getSources({
    String? category,
    String? language,
    String? country,
  }) async {
    return [
      NewsSource(
        id: 'teknoloji-haber',
        name: 'Teknoloji Haber',
        description: 'Teknoloji dünyasından son haberler',
        url: 'https://example.com',
        category: 'technology',
        language: 'tr',
        country: 'tr',
      ),
      NewsSource(
        id: 'spor-arena',
        name: 'Spor Arena',
        description: 'Spor dünyasından dakika dakika',
        url: 'https://example.com',
        category: 'sports',
        language: 'tr',
        country: 'tr',
      ),
      NewsSource(
        id: 'ekonomi-gundem',
        name: 'Ekonomi Gündem',
        description: 'Ekonomi ve finans haberleri',
        url: 'https://example.com',
        category: 'business',
        language: 'tr',
        country: 'tr',
      ),
    ];
  }
}

/// Haber Kaynağı Modeli
class NewsSource {
  final String id;
  final String name;
  final String? description;
  final String? url;
  final String? category;
  final String? language;
  final String? country;

  NewsSource({
    required this.id,
    required this.name,
    this.description,
    this.url,
    this.category,
    this.language,
    this.country,
  });

  factory NewsSource.fromJson(Map<String, dynamic> json) {
    return NewsSource(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      url: json['url'],
      category: json['category'],
      language: json['language'],
      country: json['country'],
    );
  }
}

/// News API Hatası
class NewsException implements Exception {
  final String message;
  final int statusCode;

  NewsException(this.message, this.statusCode);

  @override
  String toString() => 'NewsException: $message (Code: $statusCode)';
}
