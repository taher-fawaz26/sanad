import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('MediaUploadDropZone', () {
    testWidgets('idle state shows the upload prompt and size/format hints', (
      tester,
    ) async {
      var added = false;
      await _pump(
        tester,
        MediaUploadDropZone(
          maxFileSizeLabel: 'Max 5 MB',
          acceptedFormatsLabel: 'JPG, PNG',
          onAdd: () => added = true,
        ),
      );

      expect(find.text('Tap to upload'), findsOneWidget);
      expect(find.textContaining('Max 5 MB'), findsOneWidget);

      await tester.tap(find.byType(MediaUploadDropZone));
      expect(added, isTrue);
    });

    testWidgets('loading state shows a progress bar and percentage', (
      tester,
    ) async {
      await _pump(
        tester,
        const MediaUploadDropZone(
          state: MediaUploadDropZoneState.loading,
          progress: 0.75,
        ),
      );

      expect(find.byType(AppProgressBar), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('success state shows the uploaded confirmation', (
      tester,
    ) async {
      await _pump(
        tester,
        const MediaUploadDropZone(state: MediaUploadDropZoneState.success),
      );

      expect(find.text('Uploaded'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('error state shows the message and retries on tap', (
      tester,
    ) async {
      var retried = false;
      await _pump(
        tester,
        MediaUploadDropZone(
          state: MediaUploadDropZoneState.error,
          errorMessage: 'Something went wrong',
          onRetry: () => retried = true,
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.byType(MediaUploadDropZone));
      expect(retried, isTrue);
    });
  });
}
