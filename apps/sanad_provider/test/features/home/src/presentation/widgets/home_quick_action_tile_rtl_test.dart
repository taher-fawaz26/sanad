import 'package:app_assets/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_quick_action_tile.dart';
import 'package:testing/testing.dart';

void main() {
  testWidgets('mirrors the trailing chevron under RTL directionality', (
    tester,
  ) async {
    await pumpDsWidget(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: HomeQuickActionTile(
            iconAsset: AppSvgs.homeActionAddService,
            label: 'home.action_add_service',
            onTap: () {},
          ),
        ),
      ),
    );

    final flip = tester.widget<Transform>(
      find.byKey(const ValueKey('home_quick_action_tile_chevron_flip')),
    );
    expect(flip.transform, Matrix4.diagonal3Values(-1, 1, 1));
  });

  testWidgets('does not flip the trailing chevron under LTR directionality', (
    tester,
  ) async {
    await pumpDsWidget(
      tester,
      Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: HomeQuickActionTile(
            iconAsset: AppSvgs.homeActionAddService,
            label: 'home.action_add_service',
            onTap: () {},
          ),
        ),
      ),
    );

    final flip = tester.widget<Transform>(
      find.byKey(const ValueKey('home_quick_action_tile_chevron_flip')),
    );
    expect(flip.transform, Matrix4.identity());
  });
}
