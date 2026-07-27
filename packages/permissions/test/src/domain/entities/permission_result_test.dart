import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/domain/entities/permission_result.dart';
import 'package:permissions/src/domain/enums/permission_status.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';

void main() {
  group('PermissionResult', () {
    group('isGranted', () {
      test('is true for granted status', () {
        final result = _result(PermissionStatus.granted);
        expect(result.isGranted, isTrue);
      });

      test('is true for limited status (iOS limited photo access)', () {
        final result = _result(PermissionStatus.limited);
        expect(result.isGranted, isTrue);
      });

      test('is true for provisional status (iOS silent notifications)', () {
        final result = _result(PermissionStatus.provisional);
        expect(result.isGranted, isTrue);
      });

      test('is false for denied status', () {
        final result = _result(PermissionStatus.denied);
        expect(result.isGranted, isFalse);
      });

      test('is false for permanentlyDenied status', () {
        final result = _result(PermissionStatus.permanentlyDenied);
        expect(result.isGranted, isFalse);
      });

      test('is false for restricted status', () {
        final result = _result(PermissionStatus.restricted);
        expect(result.isGranted, isFalse);
      });
    });

    group('isDenied', () {
      test('is true only for denied status', () {
        expect(_result(PermissionStatus.denied).isDenied, isTrue);
        expect(_result(PermissionStatus.granted).isDenied, isFalse);
        expect(_result(PermissionStatus.permanentlyDenied).isDenied, isFalse);
      });
    });

    group('isLimited', () {
      test('is true only for limited status', () {
        expect(_result(PermissionStatus.limited).isLimited, isTrue);
        expect(_result(PermissionStatus.granted).isLimited, isFalse);
      });
    });

    group('isPermanentlyDenied', () {
      test('is true only for permanentlyDenied status', () {
        expect(
          _result(PermissionStatus.permanentlyDenied).isPermanentlyDenied,
          isTrue,
        );
        expect(_result(PermissionStatus.denied).isPermanentlyDenied, isFalse);
      });
    });

    group('isRestricted', () {
      test('is true only for restricted status', () {
        expect(_result(PermissionStatus.restricted).isRestricted, isTrue);
        expect(_result(PermissionStatus.denied).isRestricted, isFalse);
      });
    });

    group('canOpenSettings', () {
      test('is true for permanentlyDenied', () {
        expect(
          _result(PermissionStatus.permanentlyDenied).canOpenSettings,
          isTrue,
        );
      });

      test('is true for restricted', () {
        expect(_result(PermissionStatus.restricted).canOpenSettings, isTrue);
      });

      test('is false for denied', () {
        expect(_result(PermissionStatus.denied).canOpenSettings, isFalse);
      });

      test('is false for granted', () {
        expect(_result(PermissionStatus.granted).canOpenSettings, isFalse);
      });
    });

    group('copyWith', () {
      test('returns a new instance with updated fields', () {
        const original = PermissionResult(
          permission: PermissionType.camera,
          status: PermissionStatus.denied,
        );

        final updated = original.copyWith(status: PermissionStatus.granted);

        expect(updated.permission, equals(PermissionType.camera));
        expect(updated.status, equals(PermissionStatus.granted));
        expect(original.status, equals(PermissionStatus.denied));
      });

      test('preserves message when not overridden', () {
        const original = PermissionResult(
          permission: PermissionType.camera,
          status: PermissionStatus.denied,
          message: 'original message',
        );

        final updated = original.copyWith(status: PermissionStatus.granted);
        expect(updated.message, equals('original message'));
      });
    });

    group('equality', () {
      test('two results with same values are equal', () {
        const a = PermissionResult(
          permission: PermissionType.camera,
          status: PermissionStatus.granted,
        );
        const b = PermissionResult(
          permission: PermissionType.camera,
          status: PermissionStatus.granted,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('results with different permission type are not equal', () {
        const a = PermissionResult(
          permission: PermissionType.camera,
          status: PermissionStatus.granted,
        );
        const b = PermissionResult(
          permission: PermissionType.microphone,
          status: PermissionStatus.granted,
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}

PermissionResult _result(PermissionStatus status) => PermissionResult(
  permission: PermissionType.camera,
  status: status,
);
