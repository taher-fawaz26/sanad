import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/domain/enums/permission_status.dart';

void main() {
  group('PermissionStatus', () {
    test('contains all expected values', () {
      const expected = {
        PermissionStatus.granted,
        PermissionStatus.denied,
        PermissionStatus.permanentlyDenied,
        PermissionStatus.restricted,
        PermissionStatus.limited,
        PermissionStatus.provisional,
        PermissionStatus.unknown,
      };

      expect(PermissionStatus.values.toSet(), equals(expected));
    });

    test('has 7 values', () {
      expect(PermissionStatus.values.length, equals(7));
    });
  });
}
