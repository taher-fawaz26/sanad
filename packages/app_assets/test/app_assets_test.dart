import 'package:app_assets/app_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAssets', () {
    test('package name matches the pubspec package', () {
      expect(AppAssets.package, 'app_assets');
    });
  });

  group('AppSvgs', () {
    test('paths are rooted under assets/svgs', () {
      expect(AppSvgs.close, startsWith('assets/svgs/'));
      expect(AppSvgs.navHome, startsWith('assets/icons/navigation/'));
    });
  });

  group('AppNavigationIcons', () {
    test('paths are rooted under assets/icons/navigation', () {
      expect(AppNavigationIcons.home, startsWith('assets/icons/navigation/'));
      expect(AppNavigationIcons.centerAction, startsWith('assets/icons/navigation/'));
    });
  });

  group('AppImages', () {
    test('paths are rooted under assets/images', () {
      expect(AppImages.networkFailure, startsWith('assets/images/'));
      expect(AppImages.emptyState, startsWith('assets/images/'));
    });
  });
}
