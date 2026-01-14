import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

/// Open-Meteo API Servisi (ÜCRETSİZ - API KEY GEREKTİRMEZ)
///
/// OpenWeatherMap'in ücretsiz alternatifi.
/// Dökümantasyon: https://open-meteo.com/
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';
  static const String _geocodeUrl = 'https://geocoding-api.open-meteo.com/v1';

  /// Şehir adına göre koordinatları bul
  Future<Map<String, dynamic>?> _geocodeCity(String city) async {
    try {
      final uri = Uri.parse('$_geocodeUrl/search').replace(
        queryParameters: {
          'name': city,
          'count': '1',
          'language': 'tr',
          'format': 'json',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Şehir adına göre anlık hava durumu
  Future<WeatherData> getCurrentWeatherByCity(String city) async {
    try {
      // Önce şehrin koordinatlarını bul
      final geoData = await _geocodeCity(city);

      if (geoData == null) {
        throw WeatherException('Şehir bulunamadı: $city', 404);
      }

      final lat = geoData['latitude'] as double;
      final lon = geoData['longitude'] as double;
      final cityName = geoData['name'] as String? ?? city;
      final country = geoData['country_code'] as String? ?? '';

      return await _fetchWeather(lat, lon, cityName, country);
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Bağlantı hatası: $e', 0);
    }
  }

  /// Koordinatlara göre anlık hava durumu
  Future<WeatherData> getCurrentWeatherByLocation(
    double lat,
    double lon,
  ) async {
    try {
      return await _fetchWeather(lat, lon, 'Konumunuz', '');
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Bağlantı hatası: $e', 0);
    }
  }

  /// Hava durumu verilerini çek
  Future<WeatherData> _fetchWeather(
    double lat,
    double lon,
    String cityName,
    String country,
  ) async {
    final uri = Uri.parse('$_baseUrl/forecast').replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure',
        'daily': 'sunrise,sunset',
        'timezone': 'auto',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherData.fromOpenMeteo(data, cityName, country);
    } else {
      throw WeatherException('Hava durumu alınamadı', response.statusCode);
    }
  }

  /// 5 günlük hava durumu tahmini
  Future<List<ForecastData>> getForecast(String city) async {
    try {
      final geoData = await _geocodeCity(city);

      if (geoData == null) {
        throw WeatherException('Şehir bulunamadı: $city', 404);
      }

      final lat = geoData['latitude'] as double;
      final lon = geoData['longitude'] as double;

      return await _fetchForecast(lat, lon);
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Bağlantı hatası: $e', 0);
    }
  }

  /// Koordinatlara göre tahmin
  Future<List<ForecastData>> _fetchForecast(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/forecast').replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max,relative_humidity_2m_mean',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ForecastData.fromOpenMeteoDaily(data);
    } else {
      throw WeatherException('Tahmin alınamadı', response.statusCode);
    }
  }

  /// Günlük tahminleri grupla
  List<ForecastData> getDailyForecast(List<ForecastData> forecasts) {
    return forecasts;
  }
}

/// Popüler Türkiye şehirleri
class PopularCities {
  static const List<String> turkey = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya',
    'Adana',
    'Konya',
    'Gaziantep',
    'Mersin',
    'Diyarbakır',
    'Kayseri',
    'Eskişehir',
    'Trabzon',
    'Samsun',
    'Denizli',
  ];

  static const List<String> world = [
    'London',
    'New York',
    'Paris',
    'Tokyo',
    'Dubai',
    'Moscow',
    'Berlin',
    'Rome',
    'Sydney',
    'Toronto',
  ];
}

/// Weather API Hatası
class WeatherException implements Exception {
  final String message;
  final int statusCode;

  WeatherException(this.message, this.statusCode);

  @override
  String toString() => 'WeatherException: $message (Code: $statusCode)';
}
