import 'package:device/src/domain/entities/app_info_data.dart';
import 'package:device/src/domain/entities/biometric_auth_result.dart';
import 'package:device/src/domain/entities/device_info_data.dart';
import 'package:device/src/domain/entities/share_result.dart';
import 'package:device/src/domain/enums/biometric_type.dart';
import 'package:device/src/domain/enums/connectivity_status.dart';
import 'package:device/src/domain/enums/share_status.dart';
import 'package:device/src/infrastructure/implementations/app_info_service_impl.dart';
import 'package:device/src/infrastructure/implementations/biometric_service_impl.dart';
import 'package:device/src/infrastructure/implementations/clipboard_service_impl.dart';
import 'package:device/src/infrastructure/implementations/connectivity_service_impl.dart';
import 'package:device/src/infrastructure/implementations/device_info_service_impl.dart';
import 'package:device/src/infrastructure/implementations/share_service_impl.dart';
import 'package:device/src/infrastructure/implementations/url_launcher_service_impl.dart';
import 'package:device/src/infrastructure/providers/app_info_provider.dart';
import 'package:device/src/infrastructure/providers/biometric_provider.dart';
import 'package:device/src/infrastructure/providers/clipboard_provider.dart';
import 'package:device/src/infrastructure/providers/connectivity_provider.dart';
import 'package:device/src/infrastructure/providers/device_info_provider.dart';
import 'package:device/src/infrastructure/providers/share_provider.dart';
import 'package:device/src/infrastructure/providers/url_launcher_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeviceInfoProvider extends Mock implements DeviceInfoProvider {}

class _MockAppInfoProvider extends Mock implements AppInfoProvider {}

class _MockConnectivityProvider extends Mock implements ConnectivityProvider {}

class _MockBiometricProvider extends Mock implements BiometricProvider {}

class _MockClipboardProvider extends Mock implements ClipboardProvider {}

class _MockShareProvider extends Mock implements ShareProvider {}

class _MockUrlLauncherProvider extends Mock implements UrlLauncherProvider {}

void main() {
  group('DeviceInfoServiceImpl', () {
    test('delegates to provider', () async {
      final provider = _MockDeviceInfoProvider();
      const data = DeviceInfoData(
        model: 'Pixel',
        manufacturer: 'Google',
        brand: 'google',
        osVersion: '14',
        sdkVersion: '34',
        isTablet: false,
        isPhysicalDevice: true,
      );
      when(provider.getDeviceInfo).thenAnswer((_) async => data);

      final service = DeviceInfoServiceImpl(provider);
      expect(await service.getDeviceInfo(), equals(data));
    });
  });

  group('AppInfoServiceImpl', () {
    test('delegates to provider', () async {
      final provider = _MockAppInfoProvider();
      const data = AppInfoData(
        appName: 'Sanad',
        packageName: 'com.sanad.client',
        version: '1.0.0',
        buildNumber: '1',
      );
      when(provider.getAppInfo).thenAnswer((_) async => data);

      final service = AppInfoServiceImpl(provider);
      expect(await service.getAppInfo(), equals(data));
    });
  });

  group('ConnectivityServiceImpl', () {
    test('isConnected derives from currentStatus', () async {
      final provider = _MockConnectivityProvider();
      when(
        provider.currentStatus,
      ).thenAnswer((_) async => ConnectivityStatus.wifi);

      final service = ConnectivityServiceImpl(provider);
      expect(await service.isConnected(), isTrue);
    });

    test('isConnected is false when none', () async {
      final provider = _MockConnectivityProvider();
      when(
        provider.currentStatus,
      ).thenAnswer((_) async => ConnectivityStatus.none);

      final service = ConnectivityServiceImpl(provider);
      expect(await service.isConnected(), isFalse);
    });
  });

  group('BiometricServiceImpl', () {
    test('authenticate forwards reason + biometricOnly', () async {
      final provider = _MockBiometricProvider();
      when(
        () => provider.authenticate(
          reason: any(named: 'reason'),
          biometricOnly: any(named: 'biometricOnly'),
        ),
      ).thenAnswer((_) async => const BiometricAuthResult.success());

      final service = BiometricServiceImpl(provider);
      final result = await service.authenticate(
        reason: 'why',
        biometricOnly: true,
      );

      expect(result.isSuccess, isTrue);
      verify(
        () => provider.authenticate(reason: 'why', biometricOnly: true),
      ).called(1);
    });

    test('availableBiometrics delegates', () async {
      final provider = _MockBiometricProvider();
      when(
        provider.availableBiometrics,
      ).thenAnswer((_) async => [BiometricType.face]);

      final service = BiometricServiceImpl(provider);
      expect(await service.availableBiometrics(), [BiometricType.face]);
    });
  });

  group('ClipboardServiceImpl', () {
    test('copy + paste delegate', () async {
      final provider = _MockClipboardProvider();
      when(() => provider.copy(any())).thenAnswer((_) async {});
      when(provider.paste).thenAnswer((_) async => 'hello');

      final service = ClipboardServiceImpl(provider);
      await service.copy('hello');
      expect(await service.paste(), 'hello');
      verify(() => provider.copy('hello')).called(1);
    });
  });

  group('ShareServiceImpl', () {
    test('shareText delegates and returns result', () async {
      final provider = _MockShareProvider();
      when(
        () => provider.shareText(any(), subject: any(named: 'subject')),
      ).thenAnswer(
        (_) async => const ShareResult(status: ShareStatus.success),
      );

      final service = ShareServiceImpl(provider);
      final result = await service.shareText('hi', subject: 's');

      expect(result.isSuccess, isTrue);
      verify(() => provider.shareText('hi', subject: 's')).called(1);
    });
  });

  group('UrlLauncherServiceImpl', () {
    test('openUrl delegates', () async {
      final provider = _MockUrlLauncherProvider();
      when(() => provider.openUrl(any())).thenAnswer((_) async => true);

      final service = UrlLauncherServiceImpl(provider);
      expect(await service.openUrl('https://x.com'), isTrue);
      verify(() => provider.openUrl('https://x.com')).called(1);
    });
  });
}
