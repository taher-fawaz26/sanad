import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/enums/permission_status.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/infrastructure/implementations/permission_service_impl.dart';
import 'package:permissions/src/infrastructure/providers/permission_handler_provider.dart';

class _MockProvider extends Mock implements PermissionHandlerProvider {}

void main() {
  late _MockProvider provider;
  late PermissionServiceImpl service;

  setUp(() {
    provider = _MockProvider();
    service = PermissionServiceImpl(provider);
  });

  group('check', () {
    test('returns PermissionResult with correct type and status', () async {
      when(
        () => provider.check(PermissionType.camera),
      ).thenAnswer((_) async => PermissionStatus.granted);

      final result = await service.check(PermissionType.camera);

      expect(result.permission, equals(PermissionType.camera));
      expect(result.status, equals(PermissionStatus.granted));
      expect(result.isGranted, isTrue);
    });

    test('maps denied status correctly', () async {
      when(
        () => provider.check(PermissionType.microphone),
      ).thenAnswer((_) async => PermissionStatus.denied);

      final result = await service.check(PermissionType.microphone);

      expect(result.isDenied, isTrue);
      expect(result.isGranted, isFalse);
    });

    test('maps permanentlyDenied status correctly', () async {
      when(
        () => provider.check(PermissionType.notifications),
      ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);

      final result = await service.check(PermissionType.notifications);

      expect(result.isPermanentlyDenied, isTrue);
      expect(result.canOpenSettings, isTrue);
    });
  });

  group('checkMany', () {
    test('returns results for all requested types', () async {
      when(
        () => provider.check(PermissionType.camera),
      ).thenAnswer((_) async => PermissionStatus.granted);
      when(
        () => provider.check(PermissionType.microphone),
      ).thenAnswer((_) async => PermissionStatus.denied);

      final results = await service.checkMany([
        PermissionType.camera,
        PermissionType.microphone,
      ]);

      expect(results.length, equals(2));
      expect(results[PermissionType.camera]?.isGranted, isTrue);
      expect(results[PermissionType.microphone]?.isDenied, isTrue);
    });
  });

  group('request', () {
    test('returns granted result when OS grants the permission', () async {
      when(
        () => provider.request(PermissionType.camera),
      ).thenAnswer((_) async => PermissionStatus.granted);

      final result = await service.request(PermissionType.camera);

      expect(result.isGranted, isTrue);
    });

    test('policy parameter is accepted without error', () async {
      when(
        () => provider.request(PermissionType.camera),
      ).thenAnswer((_) async => PermissionStatus.denied);

      const policy = PermissionPolicy(showRationale: false);
      final result = await service.request(
        PermissionType.camera,
        policy: policy,
      );

      expect(result.isDenied, isTrue);
    });
  });

  group('requestMany', () {
    test('delegates to provider and maps results', () async {
      when(
        () => provider.requestMany([
          PermissionType.camera,
          PermissionType.microphone,
        ]),
      ).thenAnswer(
        (_) async => {
          PermissionType.camera: PermissionStatus.granted,
          PermissionType.microphone: PermissionStatus.denied,
        },
      );

      final results = await service.requestMany([
        PermissionType.camera,
        PermissionType.microphone,
      ]);

      expect(results[PermissionType.camera]?.isGranted, isTrue);
      expect(results[PermissionType.microphone]?.isDenied, isTrue);
    });
  });

  group(
    'isGranted / isDenied / isLimited / isRestricted / isPermanentlyDenied',
    () {
      test('isGranted returns true when status is granted', () async {
        when(
          () => provider.check(PermissionType.camera),
        ).thenAnswer((_) async => PermissionStatus.granted);
        expect(await service.isGranted(PermissionType.camera), isTrue);
      });

      test('isDenied returns true when status is denied', () async {
        when(
          () => provider.check(PermissionType.camera),
        ).thenAnswer((_) async => PermissionStatus.denied);
        expect(await service.isDenied(PermissionType.camera), isTrue);
      });

      test('isLimited returns true when status is limited', () async {
        when(
          () => provider.check(PermissionType.photos),
        ).thenAnswer((_) async => PermissionStatus.limited);
        expect(await service.isLimited(PermissionType.photos), isTrue);
      });

      test('isRestricted returns true when status is restricted', () async {
        when(
          () => provider.check(PermissionType.camera),
        ).thenAnswer((_) async => PermissionStatus.restricted);
        expect(await service.isRestricted(PermissionType.camera), isTrue);
      });

      test(
        'isPermanentlyDenied is true when status is permanentlyDenied',
        () async {
          when(
            () => provider.check(PermissionType.camera),
          ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
          expect(
            await service.isPermanentlyDenied(PermissionType.camera),
            isTrue,
          );
        },
      );
    },
  );

  group('openSettings', () {
    test('delegates to provider', () async {
      when(() => provider.openSettings()).thenAnswer((_) async => true);
      final result = await service.openSettings();
      expect(result, isTrue);
      verify(() => provider.openSettings()).called(1);
    });
  });
}
