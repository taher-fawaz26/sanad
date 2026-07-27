import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/theme/permission_explanation.dart';
import 'package:permissions/src/theme/permission_theme.dart';

void main() {
  group('PermissionExplanation', () {
    test('holds title, description and icon', () {
      const explanation = PermissionExplanation(
        title: 'Camera',
        description: 'We need the camera to scan.',
        icon: Icons.camera_alt_outlined,
      );

      expect(explanation.title, equals('Camera'));
      expect(explanation.description, equals('We need the camera to scan.'));
      expect(explanation.icon, equals(Icons.camera_alt_outlined));
    });

    test('equality is value-based', () {
      const a = PermissionExplanation(
        title: 'A',
        description: 'B',
        icon: Icons.abc,
      );
      const b = PermissionExplanation(
        title: 'A',
        description: 'B',
        icon: Icons.abc,
      );
      expect(a, equals(b));
    });

    test('copyWith overrides only provided fields', () {
      const original = PermissionExplanation(
        title: 'A',
        description: 'B',
        icon: Icons.abc,
      );
      final updated = original.copyWith(title: 'Z');
      expect(updated.title, equals('Z'));
      expect(updated.description, equals('B'));
      expect(updated.icon, equals(Icons.abc));
    });
  });

  group('PermissionTheme.explanationFor', () {
    test('returns explicit explanation when registered', () {
      const custom = PermissionExplanation(
        title: 'Custom Camera',
        description: 'Custom description',
        icon: Icons.videocam,
      );
      const theme = PermissionTheme(
        explanations: {PermissionType.camera: custom},
      );

      expect(theme.explanationFor(PermissionType.camera), equals(custom));
    });

    test('falls back to icons + texts when not registered', () {
      const theme = PermissionTheme();

      final explanation = theme.explanationFor(PermissionType.camera);

      expect(
        explanation.icon,
        equals(theme.icons.forType(PermissionType.camera)),
      );
      expect(
        explanation.title,
        equals(theme.texts.rationaleFor(PermissionType.camera).title),
      );
      expect(
        explanation.description,
        equals(theme.texts.rationaleFor(PermissionType.camera).message),
      );
    });

    test('fallback covers all permission types without throwing', () {
      const theme = PermissionTheme();
      for (final type in PermissionType.values) {
        expect(() => theme.explanationFor(type), returnsNormally);
      }
    });
  });
}
