import 'package:flutter_test/flutter_test.dart';
import 'package:weather_sync_ca/services/notification_engine.dart';

void main() {
  group('NotificationEngine', () {
    test('initializeAndRequestPermissions swallows initialization failures',
        () async {
      await expectLater(
        NotificationEngine.initializeAndRequestPermissions(
          initFunc: () async {
            throw Exception('boom');
          },
          requestPermissionsFunc: () async {},
        ),
        completes,
      );
    });
  });
}
