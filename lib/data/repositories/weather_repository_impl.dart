/// weather_repository_impl.dart
import 'package:weather_sync_ca/data/datasources/remote/environment_canada_datasource.dart';
import 'package:weather_sync_ca/data/datasources/remote/open_weather_map_datasource.dart';

abstract class WeatherRepository {
  Future<Map<String, dynamic>> getAggregatedWeather(double lat, double lon, String ecCityId);
}

class WeatherRepositoryImpl implements WeatherRepository {
  final OpenWeatherMapDataSource owmDataSource;
  final EnvironmentCanadaDataSource ecDataSource;

  WeatherRepositoryImpl({
    required this.owmDataSource,
    required this.ecDataSource,
  });

  @override
  Future<Map<String, dynamic>> getAggregatedWeather(double lat, double lon, String ecCityId) async {
    try {
      final results = await Future.wait([
        owmDataSource.getOneCallWeather(lat, lon),
        ecDataSource.getWeatherWarnings(ecCityId),
      ]);

      final owmData = results[0] as Map<String, dynamic>;
      final ecWarnings = results[1] as List<String>;

      return {
        'owm': owmData,
        'warnings': ecWarnings,
      };
    } catch (e) {
      throw Exception('Failed to aggregate weather data: $e');
    }
  }
}
