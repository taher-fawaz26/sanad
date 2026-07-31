import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpBottomNav(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = const Size(375, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: textScaler,
      ),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (_, child) => MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
          home: Directionality(
            textDirection: textDirection,
            child: Scaffold(bottomNavigationBar: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _tabs = [
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.home,
    label: 'Home',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.service,
    label: 'Service',
  ),
  // Index 2 reserved for center action
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.messages,
    label: 'Messages',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.settings,
    label: 'Settings',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.home,
    label: 'More',
  ),
];

void main() {
  group('AppBottomNavBar', () {
    testWidgets('renders 5 items and center action', (tester) async {
      final controller = NotchBottomBarController(index: 2);

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            semanticLabel: 'Create',
            onTap: () {},
          ),
          items: _tabs,
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('invokes center action callback', (tester) async {
      final controller = NotchBottomBarController(index: 2);
      var centerTapped = false;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            semanticLabel: 'Create',
            onTap: () => centerTapped = true,
          ),
          items: _tabs,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Create'));
      await tester.pumpAndSettle();

      expect(centerTapped, isTrue);
    });

    testWidgets('invokes item tap callback', (tester) async {
      final controller = NotchBottomBarController(index: 2);
      var tappedIndex = -1;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (index) => tappedIndex = index,
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            onTap: () {},
          ),
          items: _tabs,
        ),
      );

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 2);
    });

    testWidgets('renders disabled side tab label', (tester) async {
      final controller = NotchBottomBarController(index: 2);

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            onTap: () {},
          ),
          items: const [
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.home,
              label: 'Home',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.service,
              label: 'Service',
              enabled: false,
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.messages,
              label: 'Messages',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.settings,
              label: 'Settings',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.home,
              label: 'More',
            ),
          ],
        ),
      );

      expect(find.text('Service'), findsOneWidget);
    });

    testWidgets('keeps controller locked to center slot', (tester) async {
      final controller = NotchBottomBarController(index: 2);

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 1,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            onTap: () {},
          ),
          items: _tabs,
        ),
      );

      expect(controller.index, 2);
    });

    testWidgets('center FAB meets minimum touch target', (tester) async {
      final controller = NotchBottomBarController(index: 2);

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            onTap: () {},
          ),
          items: _tabs,
        ),
      );

      expect(
        BottomNavTokens.centerFabSize,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('renders in dark theme', (tester) async {
      final controller = NotchBottomBarController(index: 2);

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            onTap: () {},
          ),
          items: _tabs,
        ),
        brightness: Brightness.dark,
      );

      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('does not allow center FAB tap when disabled', (tester) async {
      final controller = NotchBottomBarController(index: 2);
      var centerTapped = false;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            semanticLabel: 'Create',
            enabled: false,
            onTap: () => centerTapped = true,
          ),
          items: _tabs,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Create'));
      await tester.pumpAndSettle();

      expect(centerTapped, isFalse);
    });

    testWidgets('does not allow disabled item tap', (tester) async {
      final controller = NotchBottomBarController(index: 2);
      var tappedIndex = -1;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          controller: controller,
          currentIndex: 0,
          onTap: (index) => tappedIndex = index,
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            onTap: () {},
          ),
          items: const [
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.home,
              label: 'Home',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.service,
              label: 'Service',
              enabled: false,
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.messages,
              label: 'Messages',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.settings,
              label: 'Settings',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.home,
              label: 'More',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Service'));
      await tester.pumpAndSettle();

      expect(tappedIndex, -1);
    });

    for (final scale in [1.0, 1.25, 1.5, 2.0]) {
      testWidgets(
        'has no layout overflow at ${scale}x text scale',
        (tester) async {
          final controller = NotchBottomBarController(index: 2);

          await _pumpBottomNav(
            tester,
            AppBottomNavBar(
              controller: controller,
              currentIndex: 0,
              onTap: (_) {},
              centerAction: AppBottomNavCenterAction(
                iconAsset: AppNavigationIcons.centerAction,
                onTap: () {},
              ),
              items: _tabs,
            ),
            textScaler: TextScaler.linear(scale),
          );

          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('BottomNavTokens', () {
    test('uses shared motion token', () {
      expect(
        BottomNavTokens.durationInMilliSeconds,
        AppDurations.notchBar.inMilliseconds,
      );
      expect(BottomNavTokens.centerFabShadow, isNotEmpty);
    });

    test('has proper default values', () {
      expect(BottomNavTokens.bottomBarHeight, 72.0);
      expect(BottomNavTokens.kBottomRadius, 28.0);
      expect(BottomNavTokens.kIconSize, 24.0);
      expect(BottomNavTokens.centerFabSize, 52.0);
      expect(BottomNavTokens.showLabel, isTrue);
      expect(BottomNavTokens.removeMargins, isTrue);
      expect(BottomNavTokens.showTopRadius, isTrue);
      expect(BottomNavTokens.showBottomRadius, isTrue);
    });
  });
}
