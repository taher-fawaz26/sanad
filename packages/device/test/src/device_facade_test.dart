import 'package:device/src/config/device_config.dart';
import 'package:device/src/device_facade.dart';
import 'package:device/src/domain/entities/biometric_auth_result.dart';
import 'package:device/src/domain/entities/device_info_data.dart';
import 'package:device/src/domain/enums/connectivity_status.dart';
import 'package:device/src/domain/services/biometric_service.dart';
import 'package:device/src/domain/services/clipboard_service.dart';
import 'package:device/src/domain/services/connectivity_service.dart';
import 'package:device/src/domain/services/device_info_service.dart';
import 'package:device/src/domain/services/url_launcher_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeviceInfoService extends Mock implements DeviceInfoService {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _MockBiometricService extends Mock implements BiometricService {}

class _MockClipboardService extends Mock implements ClipboardService {}

class _MockUrlLauncherService extends Mock implements UrlLauncherService {}

void main() {
  final sl = GetIt.instance;

  late _MockDeviceInfoService deviceInfo;
  late _MockConnectivityService connectivity;
  late _MockBiometricService biometrics;
  late _MockClipboardService clipboard;
  late _MockUrlLauncherService url;

  setUp(() {
    deviceInfo = _MockDeviceInfoService();
    connectivity = _MockConnectivityService();
    biometrics = _MockBiometricService();
    clipboard = _MockClipboardService();
    url = _MockUrlLauncherService();

    sl
      ..registerSingleton<DeviceInfoService>(deviceInfo)
      ..registerSingleton<ConnectivityService>(connectivity)
      ..registerSingleton<BiometricService>(biometrics)
      ..registerSingleton<ClipboardService>(clipboard)
      ..registerSingleton<UrlLauncherService>(url)
      ..registerSingleton<DeviceConfig>(const DeviceConfig());
  });

  tearDown(sl.reset);

  test('info() delegates to DeviceInfoService', () async {
    const data = DeviceInfoData(
      model: 'x',
      manufacturer: 'y',
      brand: 'z',
      osVersion: '1',
      sdkVersion: '1',
      isTablet: false,
      isPhysicalDevice: true,
    );
    when(deviceInfo.getDeviceInfo).thenAnswer((_) async => data);

    expect(await Device.info(), equals(data));
  });

  test('isConnected() delegates to ConnectivityService', () async {
    when(connectivity.isConnected).thenAnswer((_) async => true);
    expect(await Device.isConnected(), isTrue);
  });

  test('connectivityStatus() delegates', () async {
    when(
      connectivity.currentStatus,
    ).thenAnswer((_) async => ConnectivityStatus.mobile);
    expect(await Device.connectivityStatus(), ConnectivityStatus.mobile);
  });

  test('authenticate() uses config default reason when omitted', () async {
    when(
      () => biometrics.authenticate(
        reason: any(named: 'reason'),
        biometricOnly: any(named: 'biometricOnly'),
      ),
    ).thenAnswer((_) async => const BiometricAuthResult.success());

    await Device.authenticate();

    verify(
      () => biometrics.authenticate(
        reason: const DeviceConfig().defaultBiometricReason,
      ),
    ).called(1);
  });

  test('copy() delegates to ClipboardService', () async {
    when(() => clipboard.copy(any())).thenAnswer((_) async {});
    await Device.copy('hi');
    verify(() => clipboard.copy('hi')).called(1);
  });

  test('openUrl() delegates to UrlLauncherService', () async {
    when(() => url.openUrl(any())).thenAnswer((_) async => true);
    expect(await Device.openUrl('https://x.com'), isTrue);
  });

  test('config falls back to default when not registered', () async {
    await sl.reset();
    expect(Device.config, equals(const DeviceConfig()));
  });
}
