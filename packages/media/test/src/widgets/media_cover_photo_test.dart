import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';

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

void main() {
  group('MediaCoverPhoto', () {
    testWidgets('shows the edit button and no overlay in the idle state', (
      tester,
    ) async {
      await _pump(tester, MediaCoverPhoto(onEditTap: () {}));

      expect(find.byType(MediaEditButton), findsOneWidget);
      expect(find.byType(MediaBusyOverlay), findsNothing);
      expect(find.byType(MediaFailureOverlay), findsNothing);
    });

    testWidgets(
      'hides the edit button and shows the cancel affordance while busy',
      (tester) async {
        var cancelled = false;
        await _pump(
          tester,
          MediaCoverPhoto(
            onEditTap: () {},
            isBusy: true,
            progress: 0.6,
            onCancel: () => cancelled = true,
          ),
        );

        expect(find.byType(MediaEditButton), findsNothing);
        expect(find.byType(MediaBusyOverlay), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(cancelled, isTrue);
      },
    );

    testWidgets(
      'shows the failure overlay with the error message and edit button '
      'after a failed upload',
      (tester) async {
        var retried = false;
        await _pump(
          tester,
          MediaCoverPhoto(
            onEditTap: () {},
            hasFailed: true,
            errorMessage: 'Upload failed. Please try again.',
            onRetry: () => retried = true,
          ),
        );

        expect(find.byType(MediaFailureOverlay), findsOneWidget);
        expect(find.text('Upload failed. Please try again.'), findsOneWidget);
        expect(find.byType(MediaEditButton), findsOneWidget);

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(retried, isTrue);
      },
    );

    testWidgets('omits the retry affordance when onRetry is null', (
      tester,
    ) async {
      await _pump(
        tester,
        MediaCoverPhoto(onEditTap: () {}, hasFailed: true),
      );

      expect(find.byType(MediaFailureOverlay), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });
}
