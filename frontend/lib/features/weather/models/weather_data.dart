/// Hava Durumu Veri Modeli
///
/// Open-Meteo ve OpenWeatherMap API'den dönen verileri temsil eder.

class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final int windDeg;
  final String description;
  final String icon;
  final String condition;
  final int pressure;
  final int visibility;
  final int clouds;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime timestamp;

  WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.description,
    required this.icon,
    required this.condition,
    required this.pressure,
    required this.visibility,
    required this.clouds,
    required this.sunrise,
    required this.sunset,
    required this.timestamp,
  });

  /// OpenWeatherMap JSON parser
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final wind = json['wind'] ?? {};
    final weather = (json['weather'] as List?)?.first ?? {};
    final sys = json['sys'] ?? {};
    final clouds = json['clouds'] ?? {};

    return WeatherData(
      cityName: json['name'] ?? 'Bilinmiyor',
      country: sys['country'] ?? '',
      temperature: (main['temp'] ?? 0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      tempMin: (main['temp_min'] ?? 0).toDouble(),
      tempMax: (main['temp_max'] ?? 0).toDouble(),
      humidity: main['humidity'] ?? 0,
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      windDeg: wind['deg'] ?? 0,
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '01d',
      condition: weather['main'] ?? 'Clear',
      pressure: main['pressure'] ?? 0,
      visibility: json['visibility'] ?? 0,
      clouds: clouds['all'] ?? 0,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
        (sys['sunrise'] ?? 0) * 1000,
      ),
      sunset: DateTime.fromMillisecondsSinceEpoch((sys['sunset'] ?? 0) * 1000),
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000),
    );
  }

  /// Open-Meteo API JSON parser (ÜCRETSİZ API)
  factory WeatherData.fromOpenMeteo(
    Map<String, dynamic> json,
    String cityName,
    String country,
  ) {
    final current = json['current'] ?? {};
    final daily = json['daily'] ?? {};

    // Weather code'dan durum belirle
    final weatherCode = current['weather_code'] ?? 0;
    final conditionData = _getConditionFromCode(weatherCode);

    // Sunrise/sunset parse
    final sunriseStr = (daily['sunrise'] as List?)?.first ?? '';
    final sunsetStr = (daily['sunset'] as List?)?.first ?? '';

    return WeatherData(
      cityName: cityName,
      country: country,
      temperature: (current['temperature_2m'] ?? 0).toDouble(),
      feelsLike: (current['apparent_temperature'] ?? 0).toDouble(),
      tempMin: (current['temperature_2m'] ?? 0).toDouble() - 2,
      tempMax: (current['temperature_2m'] ?? 0).toDouble() + 2,
      humidity: (current['relative_humidity_2m'] ?? 0).toInt(),
      windSpeed: (current['wind_speed_10m'] ?? 0).toDouble(),
      windDeg: (current['wind_direction_10m'] ?? 0).toInt(),
      description: conditionData['description'] as String,
      icon: conditionData['icon'] as String,
      condition: conditionData['condition'] as String,
      pressure: (current['surface_pressure'] ?? 1013).toInt(),
      visibility: 10000, // Open-Meteo bunu vermiyor
      clouds: 0,
      sunrise:
          DateTime.tryParse(sunriseStr) ?? DateTime.now().copyWith(hour: 6),
      sunset: DateTime.tryParse(sunsetStr) ?? DateTime.now().copyWith(hour: 18),
      timestamp: DateTime.now(),
    );
  }

  /// WMO Weather Code'dan durum bilgisi al
  static Map<String, String> _getConditionFromCode(int code) {
    // WMO Weather interpretation codes
    // https://open-meteo.com/en/docs
    if (code == 0) {
      return {'condition': 'Clear', 'description': 'Açık', 'icon': '01d'};
    } else if (code == 1) {
      return {
        'condition': 'Clear',
        'description': 'Çoğunlukla Açık',
        'icon': '01d',
      };
    } else if (code == 2) {
      return {
        'condition': 'Clouds',
        'description': 'Parçalı Bulutlu',
        'icon': '02d',
      };
    } else if (code == 3) {
      return {'condition': 'Clouds', 'description': 'Bulutlu', 'icon': '03d'};
    } else if (code >= 45 && code <= 48) {
      return {'condition': 'Fog', 'description': 'Sisli', 'icon': '50d'};
    } else if (code >= 51 && code <= 55) {
      return {'condition': 'Drizzle', 'description': 'Çisenti', 'icon': '09d'};
    } else if (code >= 56 && code <= 57) {
      return {
        'condition': 'Drizzle',
        'description': 'Dondurucu Çisenti',
        'icon': '09d',
      };
    } else if (code >= 61 && code <= 65) {
      return {'condition': 'Rain', 'description': 'Yağmurlu', 'icon': '10d'};
    } else if (code >= 66 && code <= 67) {
      return {
        'condition': 'Rain',
        'description': 'Dondurucu Yağmur',
        'icon': '13d',
      };
    } else if (code >= 71 && code <= 77) {
      return {'condition': 'Snow', 'description': 'Karlı', 'icon': '13d'};
    } else if (code >= 80 && code <= 82) {
      return {
        'condition': 'Rain',
        'description': 'Sağanak Yağmur',
        'icon': '09d',
      };
    } else if (code >= 85 && code <= 86) {
      return {'condition': 'Snow', 'description': 'Kar Yağışı', 'icon': '13d'};
    } else if (code >= 95 && code <= 99) {
      return {
        'condition': 'Thunderstorm',
        'description': 'Fırtına',
        'icon': '11d',
      };
    }
    return {'condition': 'Clear', 'description': 'Bilinmiyor', 'icon': '01d'};
  }

  /// Sıcaklığı Celsius olarak formatla
  String get temperatureString => '${temperature.round()}°C';

  /// Hissedilen sıcaklık
  String get feelsLikeString => '${feelsLike.round()}°C';

  /// Türkçe açıklama (zaten Türkçe geliyorsa direkt döndür)
  String get descriptionTr {
    // Open-Meteo zaten Türkçe açıklama veriyoruz
    if (description.isNotEmpty) return description;

    final Map<String, String> translations = {
      'clear sky': 'Açık',
      'few clouds': 'Az Bulutlu',
      'scattered clouds': 'Parçalı Bulutlu',
      'broken clouds': 'Çok Bulutlu',
      'overcast clouds': 'Kapalı',
      'shower rain': 'Sağanak Yağmur',
      'rain': 'Yağmurlu',
      'light rain': 'Hafif Yağmur',
      'moderate rain': 'Orta Şiddetli Yağmur',
      'heavy rain': 'Şiddetli Yağmur',
      'thunderstorm': 'Gök Gürültülü Fırtına',
      'snow': 'Karlı',
      'light snow': 'Hafif Kar',
      'mist': 'Sisli',
      'fog': 'Yoğun Sis',
      'haze': 'Puslu',
    };
    return translations[description.toLowerCase()] ?? description;
  }

  /// Rüzgar yönü
  String get windDirection {
    const directions = ['K', 'KD', 'D', 'GD', 'G', 'GB', 'B', 'KB'];
    return directions[((windDeg + 22.5) % 360 / 45).floor()];
  }

  /// Gece mi gündüz mü?
  bool get isNight {
    final now = DateTime.now();
    return now.isAfter(sunset) || now.isBefore(sunrise);
  }

  /// Hava durumuna göre emoji
  String get weatherEmoji {
    switch (condition.toLowerCase()) {
      case 'clear':
        return isNight ? '🌙' : '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}

/// 5 Günlük Tahmin Modeli
class ForecastData {
  final DateTime dateTime;
  final double temperature;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final String condition;
  final int humidity;
  final double windSpeed;

  ForecastData({
    required this.dateTime,
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
  });

  /// OpenWeatherMap parser
  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?.first ?? {};
    final wind = json['wind'] ?? {};

    return ForecastData(
      dateTime: DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000),
      temperature: (main['temp'] ?? 0).toDouble(),
      tempMin: (main['temp_min'] ?? 0).toDouble(),
      tempMax: (main['temp_max'] ?? 0).toDouble(),
      description: weather['description'] ?? '',
      icon: weather['icon'] ?? '01d',
      condition: weather['main'] ?? 'Clear',
      humidity: main['humidity'] ?? 0,
      windSpeed: (wind['speed'] ?? 0).toDouble(),
    );
  }

  /// Open-Meteo daily forecast parser
  static List<ForecastData> fromOpenMeteoDaily(Map<String, dynamic> json) {
    final daily = json['daily'] ?? {};
    final List<String> dates = List<String>.from(daily['time'] ?? []);
    final List<dynamic> weatherCodes = daily['weather_code'] ?? [];
    final List<dynamic> tempMax = daily['temperature_2m_max'] ?? [];
    final List<dynamic> tempMin = daily['temperature_2m_min'] ?? [];
    final List<dynamic> windSpeed = daily['wind_speed_10m_max'] ?? [];
    final List<dynamic> humidity = daily['relative_humidity_2m_mean'] ?? [];

    List<ForecastData> forecasts = [];

    for (int i = 0; i < dates.length && i < 7; i++) {
      final code = weatherCodes.length > i ? (weatherCodes[i] ?? 0) : 0;
      final conditionData = WeatherData._getConditionFromCode(
        code is int ? code : 0,
      );

      forecasts.add(
        ForecastData(
          dateTime: DateTime.tryParse(dates[i]) ?? DateTime.now(),
          temperature: tempMax.length > i
              ? ((tempMax[i] ?? 0) +
                        (tempMin.length > i ? (tempMin[i] ?? 0) : 0)) /
                    2
              : 0,
          tempMin: tempMin.length > i ? (tempMin[i] ?? 0).toDouble() : 0,
          tempMax: tempMax.length > i ? (tempMax[i] ?? 0).toDouble() : 0,
          description: conditionData['description'] as String,
          icon: conditionData['icon'] as String,
          condition: conditionData['condition'] as String,
          humidity: humidity.length > i ? (humidity[i] ?? 0).toInt() : 0,
          windSpeed: windSpeed.length > i ? (windSpeed[i] ?? 0).toDouble() : 0,
        ),
      );
    }

    return forecasts;
  }

  /// Gün adı
  String get dayName {
    const days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
    return days[dateTime.weekday % 7];
  }

  /// Saat
  String get timeString {
    return '${dateTime.hour.toString().padLeft(2, '0')}:00';
  }
}
