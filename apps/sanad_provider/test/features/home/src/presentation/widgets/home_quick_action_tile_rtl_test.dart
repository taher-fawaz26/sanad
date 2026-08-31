import 'package:app_assets/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_quick_action_tile.dart';
import 'package:testing/testing.dart';

/// Counts the net horizontal mirror applied to the trailing chevron.
///
/// `Icons.chevron_right` has `matchTextDirection: true`, so the framework's
/// `Icon` widget wraps the glyph in a `Transform` with an x-scale of `-1`
/// under RTL (and none under LTR). Any additional manual flip would add a
/// second `Transform`, cancelling it — the SAN-768 double-mirror bug. This
/// asserts the *actual* rendered direction: an odd number of x-flips means the
/// chevron points left, an even number means it points right.
int _horizontalFlipCount(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.descendant(
      of: find.byIcon(Icons.chevron_right),
      matching: find.byType(Transform),
    ),
  );
  return transforms.where((t) => t.transform.entry(0, 0) < 0).length;
}

Future<void> _pumpTile(WidgetTester tester, TextDirection direction) {
  return pumpDsWidget(
    tester,
    Directionality(
      textDirection: direction,
      child: Scaffold(
        body: HomeQuickActionTile(
          iconAsset: AppSvgs.homeActionAddService,
          label: 'home.action_add_service',
          onTap: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('LTR renders the trailing chevron pointing right (no flip)', (
    tester,
  ) async {
    await _pumpTile(tester, TextDirection.ltr);

    // Even (zero) horizontal flips → chevron_right renders as ">" (right).
    expect(_horizontalFlipCount(tester), 0);
  });

  testWidgets('RTL renders the trailing chevron pointing left (single flip)', (
    tester,
  ) async {
    await _pumpTile(tester, TextDirection.rtl);

    // Exactly one horizontal flip (the framework's, from matchTextDirection)
    // → chevron_right renders mirrored as "<" (left). A second manual flip
    // would make this 0 and the chevron would wrongly point right again.
    expect(_horizontalFlipCount(tester), 1);
  });
}
