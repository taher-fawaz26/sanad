// Reproduces the EXACT wrapping AccountSettingsPage uses around
// AccountCredentialsSection — AppSkeletonizer.sliver(enabled: isInitialLoad)
// inside a CustomScrollView — toggling `enabled` from true (cold seed) to
// false (post-refresh), the same transition AccountSettingsBloc drives. The
// plain AccountCredentialsSection reseed test (account_credentials_section_
// test.dart) passes without this wrapper; this test isolates whether the
// skeletonizer engine itself is what's swallowing the update.
import 'package:account_settings/src/presentation/widgets/sections/account_credentials_section.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

const _surfaceSize = Size(900, 1200);

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
                child: SliverToBoxAdapter(
                  child: AccountCredentialsSection(
                    name: name,
                    phone: phone,
                    email: email,
                  ),
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
  // return — pump a few fixed frames instead, same as this repo's other
  // skeleton-aware widget tests would need to.
  if (enabled) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'AppSkeletonizer.sliver: enabled=true (cold seed, null data) then '
    'enabled=false (post-refresh, real data) — same transition as '
    'AccountSettingsBloc — the real values must become visible',
    (tester) async {
      await _pump(tester, enabled: true); // isInitialLoad: settings == null
      expect(find.text('Layla Al Mansoori'), findsNothing);

      await _pump(
        tester,
        enabled: false, // isInitialLoad flips false once settings != null
        name: 'Layla Al Mansoori',
        phone: '+971501234567',
        email: 'seed-company-provider-1@sanad.test',
      );

      expect(find.text('Layla Al Mansoori'), findsOneWidget);
      expect(find.text('501234567'), findsOneWidget);
      expect(
        find.text('seed-company-provider-1@sanad.test'),
        findsOneWidget,
      );
    },
  );
}
