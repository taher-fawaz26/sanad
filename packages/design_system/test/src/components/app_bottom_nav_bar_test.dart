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
    iconAsset: AppNavigationIcons.messages,
    label: 'Messages',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.centerAction,
    label: 'Requests',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.service,
    label: 'Services',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.settings,
    label: 'Settings',
  ),
];

void main() {
  group('AppBottomNavBar', () {
    testWidgets('renders 5 items and center action', (tester) async {
      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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
      expect(find.text('Requests'), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('invokes center action callback', (tester) async {
      var centerTapped = false;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(centerTapped, isTrue);
    });

    testWidgets('invokes item tap callback', (tester) async {
      var tappedIndex = -1;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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

      expect(tappedIndex, 1);
    });

    testWidgets('renders disabled side tab label', (tester) async {
      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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
              iconAsset: AppNavigationIcons.centerAction,
              label: 'Requests',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.messages,
              label: 'Messages',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.settings,
              label: 'Settings',
            ),
          ],
        ),
      );

      expect(find.text('Service'), findsOneWidget);
    });

    testWidgets('center FAB meets minimum touch target', (tester) async {
      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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
      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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
      var centerTapped = false;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(centerTapped, isFalse);
    });

    testWidgets('does not allow disabled item tap', (tester) async {
      var tappedIndex = -1;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
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
              iconAsset: AppNavigationIcons.centerAction,
              label: 'Requests',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.messages,
              label: 'Messages',
            ),
            AppBottomNavItem(
              iconAsset: AppNavigationIcons.settings,
              label: 'Settings',
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
          await _pumpBottomNav(
            tester,
            AppBottomNavBar(
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

    testWidgets('RTL forwards visual tap indices', (tester) async {
      var tappedIndex = -1;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          currentIndex: 0,
          onTap: (index) => tappedIndex = index,
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            onTap: () {},
          ),
          items: _tabs,
        ),
        textDirection: TextDirection.rtl,
      );

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
    });

    testWidgets('RTL forwards center FAB tap as visual index 2', (
      tester,
    ) async {
      var centerTapped = false;

      await _pumpBottomNav(
        tester,
        AppBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
          centerAction: AppBottomNavCenterAction(
            iconAsset: AppNavigationIcons.centerAction,
            semanticLabel: 'Create',
            onTap: () => centerTapped = true,
          ),
          items: _tabs,
        ),
        textDirection: TextDirection.rtl,
      );

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(centerTapped, isTrue);
    });
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
      expect(BottomNavTokens.contentPadding, 12.0);
    });
  });
}
