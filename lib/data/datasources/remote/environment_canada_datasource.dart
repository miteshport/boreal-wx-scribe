/// environment_canada_datasource.dart
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

abstract class EnvironmentCanadaDataSource {
  Future<List<String>> getWeatherWarnings(String cityId);
}

class EnvironmentCanadaDataSourceImpl implements EnvironmentCanadaDataSource {
  final Dio dio;

  EnvironmentCanadaDataSourceImpl({required this.dio});

  @override
  Future<List<String>> getWeatherWarnings(String cityId) async {
    try {
      final response = await dio.get('https://weather.gc.ca/rss/city/${cityId}_e.xml');
      final document = XmlDocument.parse(response.data.toString());
      final warnings = <String>[];
      
      for (var element in document.findAllElements('entry')) {
        final title = element.findElements('title').first.innerText;
        if (title.toUpperCase().contains('WARNING') || title.toUpperCase().contains('WATCH')) {
          warnings.add(title);
        }
      }
      return warnings;
    } catch (e) {
      throw Exception('Failed to fetch EC warnings: $e');
    }
  }
}
