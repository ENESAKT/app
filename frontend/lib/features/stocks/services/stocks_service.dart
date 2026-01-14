import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_keys.dart';

/// Finnhub - Borsa/Finans Servisi
///
/// API: https://finnhub.io/
/// Ücretsiz plan mevcut
class StocksService {
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  /// Hisse senedi fiyat bilgilerini getirir
  Future<StockQuote> getStockQuote(String symbol) async {
    try {
      final uri = Uri.parse('$_baseUrl/quote').replace(
        queryParameters: {
          'symbol': symbol.toUpperCase(),
          if (ApiKeys.finnhub.isNotEmpty) 'token': ApiKeys.finnhub,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return StockQuote.fromJson(data);
      } else {
        throw StocksException(
          'Hisse fiyatı alınamadı: $symbol',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StocksException) rethrow;
      throw StocksException('Bağlantı hatası: $e', 0);
    }
  }

  /// Hisse senedi temel bilgilerini getirir
  Future<StockProfile> getStockProfile(String symbol) async {
    try {
      final uri = Uri.parse('$_baseUrl/stock/profile2').replace(
        queryParameters: {
          'symbol': symbol.toUpperCase(),
          if (ApiKeys.finnhub.isNotEmpty) 'token': ApiKeys.finnhub,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return StockProfile.fromJson(data);
      } else {
        throw StocksException(
          'Hisse profili alınamadı: $symbol',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StocksException) rethrow;
      throw StocksException('Bağlantı hatası: $e', 0);
    }
  }

  /// Hisse senedi haberlerini getirir
  Future<List<StockNews>> getStockNews(String symbol, {int count = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/company-news').replace(
        queryParameters: {
          'symbol': symbol.toUpperCase(),
          'from': DateTime.now()
              .subtract(const Duration(days: 30))
              .toString()
              .split(' ')[0],
          'to': DateTime.now().toString().split(' ')[0],
          if (ApiKeys.finnhub.isNotEmpty) 'token': ApiKeys.finnhub,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => StockNews.fromJson(json)).toList();
      } else {
        throw StocksException(
          'Hisse haberleri alınamadı: $symbol',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StocksException) rethrow;
      throw StocksException('Bağlantı hatası: $e', 0);
    }
  }

  /// Kripto para fiyat bilgilerini getirir
  Future<StockQuote> getCryptoQuote(String symbol) async {
    try {
      // For crypto, Finnhub uses a different format like BTCUSDT
      final cryptoSymbol = '${symbol.toUpperCase()}USDT';

      final uri = Uri.parse('$_baseUrl/quote').replace(
        queryParameters: {
          'symbol': cryptoSymbol,
          if (ApiKeys.finnhub.isNotEmpty) 'token': ApiKeys.finnhub,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return StockQuote.fromJson(data);
      } else {
        throw StocksException(
          'Kripto fiyatı alınamadı: $symbol',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is StocksException) rethrow;
      throw StocksException('Bağlantı hatası: $e', 0);
    }
  }

  /// Global borsa indekslerini getirir
  Future<List<StockQuote>> getIndicesQuotes(List<String> indices) async {
    try {
      final List<StockQuote> results = [];
      for (final index in indices) {
        try {
          final quote = await getStockQuote(index);
          results.add(quote);
        } catch (e) {
          // Continue with other indices even if one fails
          continue;
        }
      }
      return results;
    } catch (e) {
      if (e is StocksException) rethrow;
      throw StocksException('İndeksler alınamadı: $e', 0);
    }
  }
}

/// Hisse Fiyat Modeli
class StockQuote {
  final double? currentPrice;
  final double? highPrice;
  final double? lowPrice;
  final double? openPrice;
  final double? previousClosePrice;
  final double? change;
  final double? percentChange;
  final int? timestamp;

  StockQuote({
    this.currentPrice,
    this.highPrice,
    this.lowPrice,
    this.openPrice,
    this.previousClosePrice,
    this.change,
    this.percentChange,
    this.timestamp,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      currentPrice: (json['c'] as num?)?.toDouble(),
      highPrice: (json['h'] as num?)?.toDouble(),
      lowPrice: (json['l'] as num?)?.toDouble(),
      openPrice: (json['o'] as num?)?.toDouble(),
      previousClosePrice: (json['pc'] as num?)?.toDouble(),
      change: (json['d'] as num?)?.toDouble(),
      percentChange: (json['dp'] as num?)?.toDouble(),
      timestamp: json['t'],
    );
  }
}

/// Hisse Profili Modeli
class StockProfile {
  final String? symbol;
  final String? name;
  final String? logo;
  final String? industry;
  final String? sector;
  final String? country;
  final String? currency;
  final String? exchange;
  final String? marketCapitalization;
  final String? employees;
  final String? website;
  final String? description;

  StockProfile({
    this.symbol,
    this.name,
    this.logo,
    this.industry,
    this.sector,
    this.country,
    this.currency,
    this.exchange,
    this.marketCapitalization,
    this.employees,
    this.website,
    this.description,
  });

  factory StockProfile.fromJson(Map<String, dynamic> json) {
    return StockProfile(
      symbol: json['ticker'],
      name: json['name'],
      logo: json['logo'],
      industry: json['finnhubIndustry'],
      sector: json['sector'],
      country: json['country'],
      currency: json['currency'],
      exchange: json['exchange'],
      marketCapitalization: json['marketCapitalization']?.toString(),
      employees: json['employees']?.toString(),
      website: json['weburl'],
      description: json['ipo'],
    );
  }
}

/// Hisse Haberleri Modeli
class StockNews {
  final String? category;
  final String? headline;
  final String? summary;
  final String? url;
  final String? image;
  final String? source;
  final int? datetime;

  StockNews({
    this.category,
    this.headline,
    this.summary,
    this.url,
    this.image,
    this.source,
    this.datetime,
  });

  factory StockNews.fromJson(Map<String, dynamic> json) {
    return StockNews(
      category: json['category'],
      headline: json['headline'],
      summary: json['summary'],
      url: json['url'],
      image: json['image'],
      source: json['source'],
      datetime: json['datetime'],
    );
  }
}

/// Stocks API Hatası
class StocksException implements Exception {
  final String message;
  final int statusCode;

  StocksException(this.message, this.statusCode);

  @override
  String toString() => 'StocksException: $message (Code: $statusCode)';
}
