import 'package:device/src/config/device_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceConfig', () {
    test('has sensible defaults', () {
      const config = DeviceConfig();
      expect(config.defaultBiometricReason, isNotEmpty);
      expect(config.biometricOnlyByDefault, isFalse);
    });

    test('equality is value-based', () {
      const a = DeviceConfig(defaultBiometricReason: 'x');
      const b = DeviceConfig(defaultBiometricReason: 'x');
      expect(a, equals(b));
    });

    test('different values are not equal', () {
      const a = DeviceConfig(defaultBiometricReason: 'x');
      const b = DeviceConfig(defaultBiometricReason: 'y');
      expect(a, isNot(equals(b)));
    });
  });
}
