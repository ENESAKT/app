import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_keys.dart';

/// Mapbox - Harita Servisi
///
/// API: https://www.mapbox.com/
/// Ücretsiz plan mevcut
class MapsService {
  static const String _baseUrl = 'https://api.mapbox.com';

  /// Geocoding: Adresten koordinat almak
  Future<LocationCoordinates> forwardGeocode(String address) async {
    try {
      final encodedAddress = Uri.encodeQueryComponent(address);
      final uri =
          Uri.parse(
            '$_baseUrl/geocoding/v5/mapbox.places/$encodedAddress.json',
          ).replace(
            queryParameters: {
              'access_token': ApiKeys.mapbox,
              'types': 'place,address,poi',
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final firstFeature = data['features'][0];
          final coordinates = firstFeature['center'] as List<dynamic>;
          return LocationCoordinates(
            latitude: coordinates[1].toDouble(),
            longitude: coordinates[0].toDouble(),
            placeName: firstFeature['place_name'] ?? address,
          );
        } else {
          throw MapsException('Konum bulunamadı: $address', 404);
        }
      } else {
        throw MapsException('Geocoding başarısız oldu', response.statusCode);
      }
    } catch (e) {
      if (e is MapsException) rethrow;
      throw MapsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Reverse Geocoding: Koordinattan adres almak
  Future<LocationAddress> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/geocoding/v5/mapbox.places/$longitude,$latitude.json',
      ).replace(queryParameters: {'access_token': ApiKeys.mapbox});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final firstFeature = data['features'][0];
          return LocationAddress.fromJson(firstFeature);
        } else {
          throw MapsException('Adres bulunamadı: $latitude, $longitude', 404);
        }
      } else {
        throw MapsException(
          'Reverse geocoding başarısız oldu',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is MapsException) rethrow;
      throw MapsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Yol tarifi almak (directions)
  Future<RouteDirections> getDirections({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String profile = 'mapbox/driving', // driving, walking, cycling
  }) async {
    try {
      final coordinates = '${startLon},${startLat};${endLon},${endLat}';
      final uri = Uri.parse('$_baseUrl/directions/v5/$profile/$coordinates')
          .replace(
            queryParameters: {
              'access_token': ApiKeys.mapbox,
              'steps': 'true',
              'geometries': 'polyline',
              'overview': 'full',
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return RouteDirections.fromJson(data);
      } else {
        throw MapsException('Yol tarifi alınamadı', response.statusCode);
      }
    } catch (e) {
      if (e is MapsException) rethrow;
      throw MapsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Yakındaki yerleri aramak
  Future<List<LocationSearchResult>> searchNearby({
    required double latitude,
    required double longitude,
    required String query,
    int radius = 5000, // meters
    int limit = 10,
  }) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final uri =
          Uri.parse(
            '$_baseUrl/geocoding/v5/mapbox.places/$encodedQuery.json',
          ).replace(
            queryParameters: {
              'access_token': ApiKeys.mapbox,
              'proximity': '$longitude,$latitude',
              'types': 'poi,place,address',
              'limit': limit.toString(),
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['features'] != null) {
          return (data['features'] as List<dynamic>)
              .map((feature) => LocationSearchResult.fromJson(feature))
              .toList();
        } else {
          return [];
        }
      } else {
        throw MapsException('Yakındaki yerler aranamadı', response.statusCode);
      }
    } catch (e) {
      if (e is MapsException) rethrow;
      throw MapsException('Bağlantı hatası: $e', 0);
    }
  }

  /// Harita görseli almak (static images)
  Future<String> getStaticMap({
    required double latitude,
    required double longitude,
    int zoom = 13,
    int width = 600,
    int height = 400,
    String style = 'mapbox/streets-v11',
  }) async {
    try {
      final uri =
          Uri.parse(
            '$_baseUrl/styles/v1/$style/static/pin-s($longitude,$latitude)/$longitude,$latitude,$zoom/$width×$height',
          ).replace(
            queryParameters: {
              'access_token': ApiKeys.mapbox,
              'attribution': 'false',
              'logo': 'false',
            },
          );

      // Return the URL for the static map image
      return uri.toString();
    } catch (e) {
      throw MapsException('Statik harita alınamadı: $e', 0);
    }
  }
}

/// Koordinat Modeli
class LocationCoordinates {
  final double latitude;
  final double longitude;
  final String placeName;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
    required this.placeName,
  });
}

/// Adres Modeli
class LocationAddress {
  final String placeName;
  final String? street;
  final String? neighborhood;
  final String? postcode;
  final String? place;
  final String? region;
  final String? country;
  final double? latitude;
  final double? longitude;

  LocationAddress({
    required this.placeName,
    this.street,
    this.neighborhood,
    this.postcode,
    this.place,
    this.region,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory LocationAddress.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as List<dynamic>?;

    return LocationAddress(
      placeName: json['place_name'] ?? '',
      street: _extractProperty(json['context'], 'street'),
      neighborhood: _extractProperty(json['context'], 'neighborhood'),
      postcode: _extractProperty(json['context'], 'postcode'),
      place: _extractProperty(json['context'], 'place'),
      region: _extractProperty(json['context'], 'region'),
      country: _extractProperty(json['context'], 'country'),
      latitude: center != null && center.length > 1
          ? center[1].toDouble()
          : null,
      longitude: center != null && center.length > 0
          ? center[0].toDouble()
          : null,
    );
  }

  static String? _extractProperty(List<dynamic>? context, String type) {
    if (context == null) return null;

    for (final item in context) {
      if (item is Map<String, dynamic> &&
          item['id'].toString().startsWith('$type.')) {
        return item['text'];
      }
    }
    return null;
  }
}

/// Yol Tarifi Modeli
class RouteDirections {
  final double distance; // in meters
  final double duration; // in seconds
  final String geometry; // polyline encoded
  final List<RouteStep> steps;

  RouteDirections({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.steps,
  });

  factory RouteDirections.fromJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List<dynamic>?;
    final route = routes != null && routes.isNotEmpty ? routes[0] : null;

    final legs = route?['legs'] as List<dynamic>?;
    final leg = legs != null && legs.isNotEmpty ? legs[0] : null;

    final stepsData = leg?['steps'] as List<dynamic>?;

    return RouteDirections(
      distance: (route?['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (route?['duration'] as num?)?.toDouble() ?? 0.0,
      geometry: route?['geometry'] ?? '',
      steps: stepsData != null
          ? stepsData.map((step) => RouteStep.fromJson(step)).toList()
          : [],
    );
  }
}

/// Yol Adımı Modeli
class RouteStep {
  final String instruction;
  final double distance; // in meters
  final double duration; // in seconds
  final String maneuverType;
  final String maneuverModifier;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuverType,
    required this.maneuverModifier,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>?;

    return RouteStep(
      instruction: json['instruction'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      maneuverType: maneuver?['type'] ?? '',
      maneuverModifier: maneuver?['modifier'] ?? '',
    );
  }
}

/// Arama Sonuçları Modeli
class LocationSearchResult {
  final String name;
  final double? latitude;
  final double? longitude;
  final String? placeType;
  final String? address;

  LocationSearchResult({
    required this.name,
    this.latitude,
    this.longitude,
    this.placeType,
    this.address,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as List<dynamic>?;

    return LocationSearchResult(
      name: json['text'] ?? json['place_name'] ?? '',
      latitude: center != null && center.length > 1
          ? center[1].toDouble()
          : null,
      longitude: center != null && center.length > 0
          ? center[0].toDouble()
          : null,
      placeType: json['place_type']?.length > 0 ? json['place_type'][0] : null,
      address: json['address'],
    );
  }
}

/// Maps API Hatası
class MapsException implements Exception {
  final String message;
  final int statusCode;

  MapsException(this.message, this.statusCode);

  @override
  String toString() => 'MapsException: $message (Code: $statusCode)';
}
