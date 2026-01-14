import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_keys.dart';

/// REST Countries - Ülke Bilgileri Servisi
///
/// Ücretsiz API: https://restcountries.com/
/// API key gerektirmez
class CountriesService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';

  /// Belirtilen ada göre ülke bilgilerini getirir
  Future<List<Country>> getCountriesByName(String name) async {
    try {
      final uri = Uri.parse('$_baseUrl/name/$name');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Country.fromJson(json)).toList();
      } else {
        throw CountryException('Ülke bulunamadı: $name', response.statusCode);
      }
    } catch (e) {
      if (e is CountryException) rethrow;
      throw CountryException('Bağlantı hatası: $e', 0);
    }
  }

  /// Tüm ülkeleri getirir
  Future<List<Country>> getAllCountries() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/all?fields=name,capital,region,subregion,currencies,languages,flag,population,area,borders',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Country.fromJson(json)).toList();
      } else {
        throw CountryException('Tüm ülkeler alınamadı', response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw CountryException(
        'Ağ hatası: İnternet bağlantınızı kontrol edin',
        0,
      );
    } catch (e) {
      if (e is CountryException) rethrow;
      throw CountryException('Bağlantı hatası: $e', 0);
    }
  }

  /// ISO koduna göre ülke bilgisi getirir
  Future<Country> getCountryByCode(String countryCode) async {
    try {
      final uri = Uri.parse('$_baseUrl/alpha/$countryCode');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return Country.fromJson(data.first);
        } else {
          throw CountryException('Ülke bulunamadı: $countryCode', 404);
        }
      } else {
        throw CountryException(
          'Ülke alınamadı: $countryCode',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is CountryException) rethrow;
      throw CountryException('Bağlantı hatası: $e', 0);
    }
  }

  /// Bölgeye göre ülkeleri getirir
  Future<List<Country>> getCountriesByRegion(String region) async {
    try {
      final uri = Uri.parse('$_baseUrl/region/$region');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Country.fromJson(json)).toList();
      } else {
        throw CountryException(
          'Bölgedeki ülkeler alınamadı: $region',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is CountryException) rethrow;
      throw CountryException('Bağlantı hatası: $e', 0);
    }
  }
}

/// Ülke Modeli
class Country {
  final String name;
  final String? officialName;
  final String? capital;
  final String? region;
  final String? subregion;
  final Map<String, String>? currencies;
  final Map<String, String>? languages;
  final String? flag;
  final int? population;
  final double? area;
  final List<String>? borders;
  final String? coatOfArms;

  Country({
    required this.name,
    this.officialName,
    this.capital,
    this.region,
    this.subregion,
    this.currencies,
    this.languages,
    this.flag,
    this.population,
    this.area,
    this.borders,
    this.coatOfArms,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    final nameData = json['name'] as Map<String, dynamic>;

    return Country(
      name: nameData['common'] ?? '',
      officialName: nameData['official'],
      capital: json['capital'] != null && json['capital'].isNotEmpty
          ? (json['capital'] as List).first
          : null,
      region: json['region'],
      subregion: json['subregion'],
      currencies: _parseCurrencies(json['currencies']),
      languages: json['languages'] != null
          ? Map<String, String>.from(json['languages'])
          : null,
      flag: json['flag'],
      population: json['population'],
      area: json['area']?.toDouble(),
      borders: json['borders'] != null
          ? List<String>.from(json['borders'])
          : null,
      coatOfArms: json['coatOf Arms']?[0],
    );
  }

  static Map<String, String>? _parseCurrencies(
    Map<String, dynamic>? currenciesJson,
  ) {
    if (currenciesJson == null) return null;

    final Map<String, String> result = {};
    currenciesJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = value['name'] ?? '';
      }
    });
    return result;
  }
}

/// Country API Hatası
class CountryException implements Exception {
  final String message;
  final int statusCode;

  CountryException(this.message, this.statusCode);

  @override
  String toString() => 'CountryException: $message (Code: $statusCode)';
}
