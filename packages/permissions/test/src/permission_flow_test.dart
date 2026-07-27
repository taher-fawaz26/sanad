import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/entities/permission_result.dart';
import 'package:permissions/src/domain/enums/permission_status.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/domain/services/permission_service.dart';
import 'package:permissions/src/permission_flow.dart';
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

  PermissionResult resultWith(PermissionStatus status) =>
      PermissionResult(permission: PermissionType.camera, status: status);

  group('Permissions.execute', () {
    test('invokes onGranted when granted (no other callback fires)', () async {
      when(
        () => mockService.check(PermissionType.camera),
      ).thenAnswer((_) async => resultWith(PermissionStatus.granted));

      var grantedCalled = false;
      var deniedCalled = false;

      final result = await Permissions.execute(
        PermissionFlow(
          permission: PermissionType.camera,
          onGranted: () => grantedCalled = true,
          onDenied: () => deniedCalled = true,
        ),
      );

      expect(grantedCalled, isTrue);
      expect(deniedCalled, isFalse);
      expect(result.isGranted, isTrue);
    });

    test('invokes onDenied when denied and rationale suppressed', () async {
      when(
        () => mockService.check(PermissionType.camera),
      ).thenAnswer((_) async => resultWith(PermissionStatus.denied));
      when(
        () => mockService.request(
          PermissionType.camera,
          policy: any(named: 'policy'),
        ),
      ).thenAnswer((_) async => resultWith(PermissionStatus.denied));

      var deniedCalled = false;

      await Permissions.execute(
        PermissionFlow(
          permission: PermissionType.camera,
          // No context → rationale dialog is skipped, request runs directly.
          onDenied: () => deniedCalled = true,
        ),
      );

      expect(deniedCalled, isTrue);
    });

    test('invokes onPermanentDenied when permanently denied', () async {
      when(() => mockService.check(PermissionType.camera)).thenAnswer(
        (_) async => resultWith(PermissionStatus.permanentlyDenied),
      );

      var permanentCalled = false;

      await Permissions.execute(
        PermissionFlow(
          permission: PermissionType.camera,
          policy: const PermissionPolicy(showSettingsDialog: false),
          onPermanentDenied: () => permanentCalled = true,
        ),
      );

      expect(permanentCalled, isTrue);
    });

    test('invokes onRestricted when restricted', () async {
      when(
        () => mockService.check(PermissionType.camera),
      ).thenAnswer((_) async => resultWith(PermissionStatus.restricted));

      var restrictedCalled = false;

      await Permissions.execute(
        PermissionFlow(
          permission: PermissionType.camera,
          policy: const PermissionPolicy(showSettingsDialog: false),
          onRestricted: () => restrictedCalled = true,
        ),
      );

      expect(restrictedCalled, isTrue);
    });

    test('invokes onLimited when limited', () async {
      when(
        () => mockService.check(PermissionType.photos),
      ).thenAnswer((_) async => resultWith(PermissionStatus.limited));

      var limitedCalled = false;
      var grantedCalled = false;

      await Permissions.execute(
        PermissionFlow(
          permission: PermissionType.photos,
          onLimited: () => limitedCalled = true,
          onGranted: () => grantedCalled = true,
        ),
      );

      expect(limitedCalled, isTrue);
      expect(grantedCalled, isFalse);
    });

    test(
      'falls back to onGranted when limited and onLimited is null',
      () async {
        when(
          () => mockService.check(PermissionType.photos),
        ).thenAnswer((_) async => resultWith(PermissionStatus.limited));

        var grantedCalled = false;

        await Permissions.execute(
          PermissionFlow(
            permission: PermissionType.photos,
            onGranted: () => grantedCalled = true,
          ),
        );

        expect(grantedCalled, isTrue);
      },
    );

    test('awaits async onGranted callbacks', () async {
      when(
        () => mockService.check(PermissionType.camera),
      ).thenAnswer((_) async => resultWith(PermissionStatus.granted));

      var completed = false;
      await Permissions.execute(
        PermissionFlow(
          permission: PermissionType.camera,
          onGranted: () async {
            await Future<void>.delayed(const Duration(milliseconds: 1));
            completed = true;
          },
        ),
      );

      expect(completed, isTrue);
    });
  });
}
