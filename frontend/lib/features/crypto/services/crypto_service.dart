import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_keys.dart';

/// CoinGecko - Kripto Para Servisi
///
/// Ücretsiz API: https://www.coingecko.com/api
/// API key gerektirmez (rate limit var)
class CryptoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  /// Belirtilen coinlerin fiyat bilgilerini getirir
  Future<List<CryptoCoin>> getCoinsPrice(
    List<String> ids, {
    List<String> vsCurrencies = const ['usd'],
  }) async {
    try {
      final idsParam = ids.join(',');
      final currenciesParam = vsCurrencies.join(',');

      final uri = Uri.parse('$_baseUrl/simple/price').replace(
        queryParameters: {
          'ids': idsParam,
          'vs_currencies': currenciesParam,
          if (ApiKeys.coinGecko.isNotEmpty)
            'x_cg_demo_api_key': ApiKeys.coinGecko,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert the simple price data to CryptoCoin objects
        final List<CryptoCoin> coins = [];
        for (final entry in data.entries) {
          final String id = entry.key;
          final Map<String, dynamic> prices = entry.value;

          coins.add(
            CryptoCoin(
              id: id,
              symbol: id.substring(0, id.length > 3 ? 3 : id.length),
              name: id,
              currentPrice: prices[vsCurrencies.first] ?? 0.0,
              priceChangePercentage24h:
                  0.0, // Would need another API call to get this
            ),
          );
        }

        return coins;
      } else {
        throw CryptoException(
          'Kripto fiyatları alınamadı',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is CryptoException) rethrow;
      throw CryptoException('Bağlantı hatası: $e', 0);
    }
  }

  /// Popüler kripto paraları getirir
  Future<List<CryptoCoin>> getPopularCoins({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/coins/markets').replace(
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': perPage.toString(),
          'page': page.toString(),
          'sparkline': 'false',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CryptoCoin.fromJson(json)).toList();
      } else {
        throw CryptoException(
          'Popüler kripto paralar alınamadı',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is CryptoException) rethrow;
      throw CryptoException('Bağlantı hatası: $e', 0);
    }
  }

  /// Coin detaylarını getirir
  Future<CryptoCoinDetails> getCoinDetails(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/coins/$id');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CryptoCoinDetails.fromJson(data);
      } else {
        throw CryptoException(
          'Coin detayları alınamadı: $id',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is CryptoException) rethrow;
      throw CryptoException('Bağlantı hatası: $e', 0);
    }
  }

  /// Trending kripto paraları getirir
  Future<List<CryptoCoin>> getTrendingCoins() async {
    try {
      final uri = Uri.parse('$_baseUrl/search/trending');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> coinsData = data['coins'] as List<dynamic>;

        // Extract coin IDs and fetch detailed info
        final List<String> coinIds = [];
        for (final coinData in coinsData) {
          final coinInfo = coinData['item'] as Map<String, dynamic>;
          coinIds.add(coinInfo['id'] as String);
        }

        if (coinIds.isNotEmpty) {
          return await getPopularCoins(perPage: coinIds.length);
        }

        return [];
      } else {
        throw CryptoException('Trenddekiler alınamadı', response.statusCode);
      }
    } catch (e) {
      if (e is CryptoException) rethrow;
      throw CryptoException('Bağlantı hatası: $e', 0);
    }
  }
}

/// Kripto Para Modeli
class CryptoCoin {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double? priceChangePercentage24h;
  final double? marketCap;
  final double? totalVolume;
  final String? image;
  final int? rank;

  CryptoCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    this.priceChangePercentage24h,
    this.marketCap,
    this.totalVolume,
    this.image,
    this.rank,
  });

  factory CryptoCoin.fromJson(Map<String, dynamic> json) {
    return CryptoCoin(
      id: json['id'] ?? '',
      symbol: json['symbol']?.toString().toUpperCase() ?? '',
      name: json['name'] ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num?)
          ?.toDouble(),
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      image: json['image'],
      rank: json['market_cap_rank'],
    );
  }
}

/// Kripto Para Detay Modeli
class CryptoCoinDetails {
  final String id;
  final String symbol;
  final String name;
  final String description;
  final String? image;
  final Map<String, dynamic>? marketData;
  final Map<String, dynamic>? communityData;
  final Map<String, dynamic>? developerData;

  CryptoCoinDetails({
    required this.id,
    required this.symbol,
    required this.name,
    required this.description,
    this.image,
    this.marketData,
    this.communityData,
    this.developerData,
  });

  factory CryptoCoinDetails.fromJson(Map<String, dynamic> json) {
    return CryptoCoinDetails(
      id: json['id'] ?? '',
      symbol: json['symbol']?.toString().toUpperCase() ?? '',
      name: json['name'] ?? '',
      description:
          ((json['description'] as Map<String, dynamic>?)?.values.firstOrNull)
              ?.toString() ??
          '',
      image: json['image']?['large'],
      marketData: json['market_data'] as Map<String, dynamic>?,
      communityData: json['community_data'] as Map<String, dynamic>?,
      developerData: json['developer_data'] as Map<String, dynamic>?,
    );
  }
}

/// Crypto API Hatası
class CryptoException implements Exception {
  final String message;
  final int statusCode;

  CryptoException(this.message, this.statusCode);

  @override
  String toString() => 'CryptoException: $message (Code: $statusCode)';
}
