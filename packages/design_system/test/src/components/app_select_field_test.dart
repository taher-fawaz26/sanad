import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

bool _isChevronAsset(Widget widget) {
  if (widget is! SvgPicture) return false;
  final loader = widget.bytesLoader;
  return loader is SvgAssetLoader && loader.assetName == AppSvgs.chevronDown;
}

void main() {
  group('AppSelectField', () {
    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppSelectField(
          label: 'Language',
          value: 'English',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('English'));
      expect(tapped, isTrue);
    });

    testWidgets('shows the hint when value is empty', (tester) async {
      await _pump(
        tester,
        const AppSelectField(label: 'Language', hint: 'Select a language'),
      );

      expect(find.text('Select a language'), findsOneWidget);
    });
  });

  group('AppSelectField skeleton', () {
    testWidgets(
      'hides the real chevron while an enabled Skeletonizer is active',
      (tester) async {
        await _pump(
          tester,
          const Skeletonizer(
            child: AppSelectField(label: 'Language', value: 'English'),
          ),
        );
        // The shimmer animation repeats indefinitely — pump bounded frames
        // instead of pumpAndSettle(), which would never return.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byWidgetPredicate(_isChevronAsset), findsNothing);
      },
    );

    testWidgets('shows the real chevron when not skeletonized', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppSelectField(label: 'Language', value: 'English'),
      );

      expect(find.byWidgetPredicate(_isChevronAsset), findsOneWidget);
    });

    testWidgets(
      'shows the real chevron again once Skeletonizer is disabled',
      (tester) async {
        await _pump(
          tester,
          const Skeletonizer(
            child: AppSelectField(label: 'Language', value: 'English'),
          ),
        );
        await tester.pump();
        expect(find.byWidgetPredicate(_isChevronAsset), findsNothing);

        await _pump(
          tester,
          const Skeletonizer(
            enabled: false,
            child: AppSelectField(label: 'Language', value: 'English'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byWidgetPredicate(_isChevronAsset), findsOneWidget);
      },
    );
  });
}
