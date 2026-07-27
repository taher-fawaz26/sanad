import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/theme/permission_theme.dart';

void main() {
  group('PermissionIcons', () {
    const icons = PermissionIcons();

    test('forType returns camera icon for camera', () {
      expect(
        icons.forType(PermissionType.camera),
        equals(Icons.camera_alt_outlined),
      );
    });

    test('forType returns photos icon for gallery', () {
      expect(
        icons.forType(PermissionType.gallery),
        equals(Icons.photo_library_outlined),
      );
    });

    test('forType returns bluetooth icon for nearbyDevices', () {
      expect(
        icons.forType(PermissionType.nearbyDevices),
        equals(Icons.bluetooth_outlined),
      );
    });

    test('forType returns location icon for locationAlways', () {
      expect(
        icons.forType(PermissionType.locationAlways),
        equals(Icons.location_on_outlined),
      );
    });

    test('forType covers all PermissionType values without throwing', () {
      for (final type in PermissionType.values) {
        expect(() => icons.forType(type), returnsNormally);
      }
    });
  });

  group('PermissionTexts', () {
    test('has sensible defaults', () {
      const texts = PermissionTexts();
      expect(texts.allowButtonLabel, isNotEmpty);
      expect(texts.denyButtonLabel, isNotEmpty);
      expect(texts.openSettingsButtonLabel, isNotEmpty);
      expect(texts.cancelButtonLabel, isNotEmpty);
    });

    test('rationaleFor returns default when type not in map', () {
      const texts = PermissionTexts();
      final rationale = texts.rationaleFor(PermissionType.camera);
      expect(rationale.title, equals(texts.rationaleDefaultTitle));
      expect(rationale.message, equals(texts.rationaleDefaultMessage));
    });

    test('rationaleFor returns override when type is present', () {
      const override = PermissionRationaleText(
        title: 'Camera Access',
        message: 'We need your camera to scan QR codes.',
      );
      const texts = PermissionTexts(
        rationaleMessages: {PermissionType.camera: override},
      );

      final rationale = texts.rationaleFor(PermissionType.camera);
      expect(rationale.title, equals('Camera Access'));
      expect(
        rationale.message,
        equals('We need your camera to scan QR codes.'),
      );
    });
  });

  group('PermissionTheme', () {
    test('has default icons and texts', () {
      const theme = PermissionTheme();
      expect(theme.icons, isA<PermissionIcons>());
      expect(theme.texts, isA<PermissionTexts>());
    });

    test('accepts custom iconSize', () {
      const theme = PermissionTheme(iconSize: 64);
      expect(theme.iconSize, equals(64.0));
    });
  });
}
