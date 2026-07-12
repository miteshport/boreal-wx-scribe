/// open_weather_map_datasource.dart
import 'package:dio/dio.dart';

abstract class OpenWeatherMapDataSource {
  Future<Map<String, dynamic>> getOneCallWeather(double lat, double lon);
}

class OpenWeatherMapDataSourceImpl implements OpenWeatherMapDataSource {
  final Dio dio;
  final String apiKey;

  OpenWeatherMapDataSourceImpl({required this.dio, required this.apiKey});

  @override
  Future<Map<String, dynamic>> getOneCallWeather(double lat, double lon) async {
    try {
      final response = await dio.get(
        'https://api.openweathermap.org/data/3.0/onecall',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': apiKey,
          'units': 'metric',
          'exclude': 'minutely',
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch OWM weather: $e');
    }
  }
}
