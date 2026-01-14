import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_keys.dart';

/// ExchangeRate-API - Döviz Çevirici Servisi
///
/// API: https://www.exchangerate-api.com/
/// Ücretsiz plan mevcut
class CurrencyService {
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  /// Belirtilen para birimine göre döviz kurlarını getirir
  Future<CurrencyRates> getCurrencyRates(String baseCurrency) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/${ApiKeys.exchangeRate}/latest/$baseCurrency',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['result'] == 'success') {
          return CurrencyRates.fromJson(data);
        } else {
          throw CurrencyException(
            data['error-type'] ?? 'Bilinmeyen hata',
            response.statusCode,
          );
        }
      } else {
        throw CurrencyException('Döviz kurları alınamadı', response.statusCode);
      }
    } catch (e) {
      if (e is CurrencyException) rethrow;
      throw CurrencyException('Bağlantı hatası: $e', 0);
    }
  }

  /// Belirtilen para birimleri arasında döviz dönüşümü yapar
  Future<double> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    try {
      // First get the rates with the base currency
      final rates = await getCurrencyRates(fromCurrency.toUpperCase());

      // Check if target currency exists in rates
      if (rates.conversionRates.containsKey(toCurrency.toUpperCase())) {
        final rate = rates.conversionRates[toCurrency.toUpperCase()]!;
        return amount * rate;
      } else {
        throw CurrencyException('Desteklenmeyen para birimi: $toCurrency', 0);
      }
    } catch (e) {
      if (e is CurrencyException) rethrow;
      throw CurrencyException('Dönüşüm hatası: $e', 0);
    }
  }

  /// Belirli para birimleri arasındaki oranı getirir
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      final rates = await getCurrencyRates(fromCurrency.toUpperCase());

      if (rates.conversionRates.containsKey(toCurrency.toUpperCase())) {
        return rates.conversionRates[toCurrency.toUpperCase()]!;
      } else {
        throw CurrencyException(
          'Oran bulunamadı: $fromCurrency -> $toCurrency',
          0,
        );
      }
    } catch (e) {
      if (e is CurrencyException) rethrow;
      throw CurrencyException('Oran alma hatası: $e', 0);
    }
  }

  /// Mevcut tüm para birimlerini getirir
  Future<Map<String, String>> getSupportedCurrencies() async {
    try {
      final uri = Uri.parse('$_baseUrl/${ApiKeys.exchangeRate}/codes');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['result'] == 'success') {
          final Map<String, String> currencies = {};
          final List<dynamic> codes = data['supported_codes'];
          for (final code in codes) {
            if (code is List && code.length >= 2) {
              currencies[code[0]] = code[1];
            }
          }
          return currencies;
        } else {
          throw CurrencyException(
            data['error-type'] ?? 'Bilinmeyen hata',
            response.statusCode,
          );
        }
      } else {
        throw CurrencyException(
          'Desteklenen para birimleri alınamadı',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is CurrencyException) rethrow;
      throw CurrencyException('Bağlantı hatası: $e', 0);
    }
  }

  /// Belirli para birimleri için özel oranları getirir
  Future<Map<String, double>> getSpecificRates(
    String baseCurrency,
    List<String> targetCurrencies,
  ) async {
    try {
      final allRates = await getCurrencyRates(baseCurrency);
      final Map<String, double> specificRates = {};

      for (final currency in targetCurrencies) {
        if (allRates.conversionRates.containsKey(currency.toUpperCase())) {
          specificRates[currency.toUpperCase()] =
              allRates.conversionRates[currency.toUpperCase()]!;
        }
      }

      return specificRates;
    } catch (e) {
      if (e is CurrencyException) rethrow;
      throw CurrencyException('Belirli oranlar alınamadı: $e', 0);
    }
  }
}

/// Döviz Kurları Modeli
class CurrencyRates {
  final String baseCode;
  final Map<String, double> conversionRates;
  final DateTime lastUpdated;

  CurrencyRates({
    required this.baseCode,
    required this.conversionRates,
    required this.lastUpdated,
  });

  factory CurrencyRates.fromJson(Map<String, dynamic> json) {
    final Map<String, double> rates = {};
    final Map<String, dynamic> ratesData =
        json['conversion_rates'] as Map<String, dynamic>;

    ratesData.forEach((key, value) {
      if (value is num) {
        rates[key] = value.toDouble();
      }
    });

    return CurrencyRates(
      baseCode: json['base_code'] ?? '',
      conversionRates: rates,
      lastUpdated:
          DateTime.tryParse(json['time_last_update_utc'] ?? '') ??
          DateTime.now(),
    );
  }
}

/// Currency API Hatası
class CurrencyException implements Exception {
  final String message;
  final int statusCode;

  CurrencyException(this.message, this.statusCode);

  @override
  String toString() => 'CurrencyException: $message (Code: $statusCode)';
}
