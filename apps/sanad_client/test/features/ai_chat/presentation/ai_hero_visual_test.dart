import 'dart:io';

import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_hero_visual.dart';
import 'package:testing/testing.dart';

/// The AI hero — Figma `Frame 427319459` (`7118:29598`).
///
/// The motion itself — keyframes, easing, seam, reduced motion — is
/// `AppBreathe`'s own test in `app_animations`. What is asserted here is the
/// **composition**:
/// that the breathe is applied to the bloom and to nothing else, that the mark
/// is untouched, and that the box the page lays out has not changed size.
const Duration _period = AppBreathe.defaultPeriod;

Future<void> _pump(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpDsWidget(
    tester,
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const Center(child: AiHeroVisual()),
    ),
  );
  await tester.pump();
}

Finder get _bloom => find.descendant(
  of: find.byType(AppBreathe),
  matching: find.byType(Image),
);

void main() {
  group('AiHeroVisual', () {
    testWidgets('draws the Figma bloom asset under the breathing loop', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byType(AppBreathe), findsOneWidget);
      expect(_bloom, findsOneWidget);

      final image = tester.widget<Image>(_bloom).image as AssetImage;
      expect(image.assetName, AppImages.aiChatHeroBloom);
      expect(image.package, AppAssets.package);
    });

    testWidgets('keeps the mark outside the breathe', (tester) async {
      await _pump(tester);

      expect(find.byType(SvgPicture), findsOneWidget);
      // The spec animates the background. Fading the logo to 85% would be a
      // change to the logo, which this pass explicitly does not make.
      expect(
        find.descendant(
          of: find.byType(AppBreathe),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
      );
    });

    testWidgets('leaves the mark at its Figma geometry', (tester) async {
      await _pump(tester);

      // Read off the widget, not its painted rect: Figma rotates the mark
      // 179.66° inside the node, so its *bounding box* is a shade larger than
      // the asset it draws.
      final mark = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(mark.width, closeTo(93.77, 0.01));
      expect(mark.height, closeTo(91.82, 0.01));

      // Centred and nudged 6.95dp above the box's centre (`7118:29600`).
      final bounds = tester.getRect(find.byType(SvgPicture));
      final hero = tester.getRect(find.byType(AiHeroVisual));
      expect(bounds.center.dx, closeTo(hero.center.dx, 0.01));
      expect(bounds.center.dy, closeTo(hero.center.dy - 6.95, 0.01));
    });

    testWidgets('occupies the same 280dp box the Lottie composition did', (
      tester,
    ) async {
      await _pump(tester);

      final hero = tester.getRect(find.byType(AiHeroVisual));
      expect(hero.width, 280);
      expect(hero.height, 280);

      // The export is drawn at its own 267 — the 200dp node plus its blur
      // bleed — which fits inside the box with margin to spare.
      final bloom = tester.getRect(_bloom);
      expect(bloom.width, closeTo(267, 0.01));
      expect(bloom.height, closeTo(267, 0.01));
      expect(bloom.width, lessThan(hero.width));
    });

    testWidgets('breathes: the bloom scales and fades over the cycle', (
      tester,
    ) async {
      await _pump(tester);

      double scaleOfBloom() => tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(AppBreathe),
              matching: find.byType(Transform),
            ),
          )
          .transform
          .storage[0];
      double opacityOfBloom() => tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(AppBreathe),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;

      expect(scaleOfBloom(), closeTo(1, 0.0001));
      expect(opacityOfBloom(), closeTo(0.85, 0.0001));

      await tester.pump(_period ~/ 2);
      expect(scaleOfBloom(), closeTo(1.02, 0.0001));
      expect(opacityOfBloom(), closeTo(1, 0.0001));

      await tester.pump(_period ~/ 2);
      expect(scaleOfBloom(), closeTo(1, 0.0001));
      expect(opacityOfBloom(), closeTo(0.85, 0.0001));
    });

    testWidgets('holds still under reduced motion', (tester) async {
      await _pump(tester, reduceMotion: true);

      expect(_bloom, findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      // The geometry is unchanged either way — reduced motion removes the
      // animation, not the hero.
      expect(tester.getRect(find.byType(AiHeroVisual)).width, 280);
    });

    testWidgets('exposes no semantics of its own', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      // Decorative pixels: the greeting beside it carries the meaning.
      expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
      handle.dispose();
    });

    test('the hero no longer drives itself from a Lottie', () {
      final source = File(
        'lib/src/features/ai_chat/src/presentation/widgets/home/'
        'ai_hero_visual.dart',
      ).readAsStringSync();

      // The supplied specification is a keyframe list, not a Lottie
      // composition — reproducing it means one animated widget, not a second
      // animation layered over a self-animating file.
      expect(source, isNot(contains('AppLottie.aiAssistant')));
      expect(source, contains('AppBreathe'));
      // And no duration of its own: the period is `AppBreathe`'s default.
      expect(source, isNot(contains('Duration(')));
    });
  });
}
