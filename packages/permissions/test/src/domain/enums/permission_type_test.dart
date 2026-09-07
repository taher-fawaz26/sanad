import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';

void main() {
  group('PermissionType', () {
    test('contains all expected values', () {
      const expected = {
        PermissionType.camera,
        PermissionType.photos,
        PermissionType.gallery,
        PermissionType.storage,
        PermissionType.documents,
        PermissionType.microphone,
        PermissionType.speechRecognition,
        PermissionType.locationWhenInUse,
        PermissionType.locationAlways,
        PermissionType.notifications,
        PermissionType.contacts,
        PermissionType.calendar,
        PermissionType.bluetooth,
        PermissionType.nearbyDevices,
        PermissionType.phone,
        PermissionType.mediaLibrary,
        PermissionType.manageExternalStorage,
      };

      expect(PermissionType.values.toSet(), equals(expected));
    });

    test('has 17 values', () {
      expect(PermissionType.values.length, equals(17));
    });
  });
}
