// Reproduces the exact wrapping AccountSettingsPage uses around
// AccountCredentialsSection and LanguagePreferencesSection —
// AppSkeletonizer.sliver(enabled: isInitialLoad) inside a CustomScrollView —
// to verify the loading state renders as a true skeleton: no real
// data-dependent visuals (the country flag, the dropdown chevron) should
// paint through, only bones and (once loaded) the real content.
//
// See workers/test/src/presentation/widgets/worker_list_item_test.dart for
// why EasyLocalization is not bootstrapped here — `.tr()` falls back to the
// raw key, which is fine since this test doesn't assert on label text.
import 'package:account_settings/src/presentation/widgets/sections/account_credentials_section.dart';
import 'package:account_settings/src/presentation/widgets/sections/language_preferences_section.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

const _surfaceSize = Size(900, 1200);

bool _isSvgAsset(Widget widget, String assetName) {
  if (widget is! SvgPicture) return false;
  final loader = widget.bytesLoader;
  return loader is SvgAssetLoader && loader.assetName == assetName;
}

Future<void> _pump(
  WidgetTester tester, {
  required bool enabled,
  String? name,
  String? phone,
  String? email,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              AppSkeletonizer.sliver(
                enabled: enabled,
                child: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: AccountCredentialsSection(
                        name: name,
                        phone: phone,
                        email: email,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: LanguagePreferencesSection(
                        selectedLanguageLabel: 'English',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  // `enabled: true` drives a perpetually-repeating shimmer animation
  // (AppSkeletonizer's ShimmerEffect), so `pumpAndSettle()` would never
  // return — pump a few fixed frames instead.
  if (enabled) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Account Settings initial-loading skeleton', () {
    testWidgets(
      'hides the real country flag, the real dropdown chevron, and real '
      'account data while isInitialLoad is true',
      (tester) async {
        await _pump(tester, enabled: true);

        expect(
          find.byWidgetPredicate((w) => _isSvgAsset(w, AppSvgs.flagAe)),
          findsNothing,
          reason: 'the UAE flag must not leak through the loading skeleton',
        );
        expect(
          find.byWidgetPredicate((w) => _isSvgAsset(w, AppSvgs.chevronDown)),
          findsNothing,
          reason:
              'the dropdown chevron must not leak through the loading '
              'skeleton',
        );
        expect(find.text('Layla Al Mansoori'), findsNothing);
        expect(find.text('501234567'), findsNothing);

        // Skeleton bones are genuinely present — this isn't just an absence
        // of content, it's a real loading placeholder. Bone's public
        // constructors return private subclasses, so match by `is Bone`
        // rather than the exact-type `find.byType`.
        expect(find.byWidgetPredicate((w) => w is Bone), findsWidgets);
      },
    );

    testWidgets(
      'shows the real flag, chevron, and account data once loaded — same '
      'transition AccountSettingsBloc drives (isInitialLoad true → false)',
      (tester) async {
        await _pump(tester, enabled: true);
        await _pump(
          tester,
          enabled: false,
          name: 'Layla Al Mansoori',
          phone: '+971501234567',
          email: 'seed-company-provider-1@sanad.test',
        );

        expect(
          find.byWidgetPredicate((w) => _isSvgAsset(w, AppSvgs.flagAe)),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate((w) => _isSvgAsset(w, AppSvgs.chevronDown)),
          findsOneWidget,
        );
        expect(find.text('Layla Al Mansoori'), findsOneWidget);
        expect(find.text('501234567'), findsOneWidget);
      },
    );
  });
}
