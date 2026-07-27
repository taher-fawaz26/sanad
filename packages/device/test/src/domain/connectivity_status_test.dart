import 'package:device/src/domain/enums/connectivity_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityStatus.isConnected', () {
    test('is false only for none', () {
      for (final status in ConnectivityStatus.values) {
        expect(
          status.isConnected,
          status != ConnectivityStatus.none,
          reason: '$status',
        );
      }
    });
  });
}
