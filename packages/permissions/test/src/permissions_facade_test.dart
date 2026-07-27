import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/entities/permission_result.dart';
import 'package:permissions/src/domain/enums/permission_status.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/domain/services/permission_service.dart';
import 'package:permissions/src/permissions_facade.dart';

class _MockPermissionService extends Mock implements PermissionService {}

void main() {
  final sl = GetIt.instance;
  late _MockPermissionService mockService;

  setUpAll(() {
    registerFallbackValue(const PermissionPolicy());
    registerFallbackValue(PermissionType.camera);
  });

  setUp(() {
    mockService = _MockPermissionService();
    sl
      ..registerSingleton<PermissionService>(mockService)
      ..registerSingleton<PermissionConfig>(const PermissionConfig());
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Permissions.check', () {
    test('delegates to the service', () async {
      final expected = _grantedResult(PermissionType.camera);
      when(
        () => mockService.check(PermissionType.camera),
      ).thenAnswer((_) async => expected);

      final result = await Permissions.check(PermissionType.camera);

      expect(result, equals(expected));
      verify(() => mockService.check(PermissionType.camera)).called(1);
    });
  });

  group('Permissions.request', () {
    test('requestMicrophone delegates to the service', () async {
      final expected = _grantedResult(PermissionType.microphone);
      when(
        () => mockService.request(
          PermissionType.microphone,
          policy: any(named: 'policy'),
        ),
      ).thenAnswer((_) async => expected);

      final result = await Permissions.requestMicrophone();

      expect(result.isGranted, isTrue);
    });
  });

  group('Permissions.requestMany', () {
    test('returns a map of results for all requested types', () async {
      final expected = {
        PermissionType.camera: _grantedResult(PermissionType.camera),
        PermissionType.microphone: _deniedResult(PermissionType.microphone),
      };
      when(
        () => mockService.requestMany(
          [PermissionType.camera, PermissionType.microphone],
          policy: any(named: 'policy'),
        ),
      ).thenAnswer((_) async => expected);

      final results = await Permissions.requestMany([
        PermissionType.camera,
        PermissionType.microphone,
      ]);

      expect(results[PermissionType.camera]?.isGranted, isTrue);
      expect(results[PermissionType.microphone]?.isDenied, isTrue);
    });
  });

  group('Permissions.ensure (no context — no dialogs)', () {
    test('returns immediately when already granted', () async {
      when(
        () => mockService.check(PermissionType.camera),
      ).thenAnswer((_) async => _grantedResult(PermissionType.camera));

      final result = await Permissions.ensureCamera();

      expect(result.isGranted, isTrue);
      verifyNever(
        () => mockService.request(
          any(),
          policy: any(named: 'policy'),
        ),
      );
    });

    test('requests permission when denied and no context supplied', () async {
      when(
        () => mockService.check(PermissionType.camera),
      ).thenAnswer((_) async => _deniedResult(PermissionType.camera));
      when(
        () => mockService.request(
          PermissionType.camera,
          policy: any(named: 'policy'),
        ),
      ).thenAnswer((_) async => _grantedResult(PermissionType.camera));

      final result = await Permissions.ensureCamera();

      expect(result.isGranted, isTrue);
      verify(
        () => mockService.request(
          PermissionType.camera,
          policy: any(named: 'policy'),
        ),
      ).called(1);
    });

    test('calls openSettings when autoOpenSettings is true', () async {
      when(() => mockService.check(PermissionType.camera)).thenAnswer(
        (_) async => _permanentlyDeniedResult(PermissionType.camera),
      );
      when(() => mockService.openSettings()).thenAnswer((_) async => true);

      const policy = PermissionPolicy(autoOpenSettings: true);
      await Permissions.ensureCamera(policy: policy);

      verify(() => mockService.openSettings()).called(1);
    });

    test(
      'does not call openSettings when autoOpenSettings is false '
      'and no context supplied',
      () async {
        when(() => mockService.check(PermissionType.camera)).thenAnswer(
          (_) async => _permanentlyDeniedResult(PermissionType.camera),
        );

        // autoOpenSettings defaults to false; showSettingsDialog to true.
        await Permissions.ensureCamera();

        verifyNever(() => mockService.openSettings());
      },
    );
  });

  group('Permissions.openSettings', () {
    test('delegates to the service', () async {
      when(() => mockService.openSettings()).thenAnswer((_) async => true);

      final result = await Permissions.openSettings();

      expect(result, isTrue);
      verify(() => mockService.openSettings()).called(1);
    });
  });
}

PermissionResult _grantedResult(PermissionType type) =>
    PermissionResult(permission: type, status: PermissionStatus.granted);

PermissionResult _deniedResult(PermissionType type) =>
    PermissionResult(permission: type, status: PermissionStatus.denied);

PermissionResult _permanentlyDeniedResult(PermissionType type) =>
    PermissionResult(
      permission: type,
      status: PermissionStatus.permanentlyDenied,
    );
