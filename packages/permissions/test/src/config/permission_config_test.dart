import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/config/permission_config.dart';

void main() {
  group('PermissionPolicy', () {
    test('has correct defaults', () {
      const policy = PermissionPolicy();
      expect(policy.showRationale, isTrue);
      expect(policy.showSettingsDialog, isTrue);
      expect(policy.autoOpenSettings, isFalse);
    });

    test('equality works', () {
      const a = PermissionPolicy(autoOpenSettings: true);
      const b = PermissionPolicy(autoOpenSettings: true);
      expect(a, equals(b));
    });

    test('policies with different values are not equal', () {
      const a = PermissionPolicy();
      const b = PermissionPolicy(showRationale: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('PermissionConfig', () {
    test('has a default policy', () {
      const config = PermissionConfig();
      expect(config.defaultPolicy, equals(const PermissionPolicy()));
    });

    test('accepts a custom policy', () {
      const policy = PermissionPolicy(showRationale: false);
      const config = PermissionConfig(defaultPolicy: policy);
      expect(config.defaultPolicy.showRationale, isFalse);
    });

    test('equality works', () {
      const a = PermissionConfig();
      const b = PermissionConfig();
      expect(a, equals(b));
    });
  });
}
