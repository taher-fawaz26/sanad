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
  group('MediaUploadTile', () {
    testWidgets('pending state shows a generic file glyph', (tester) async {
      await _pump(
        tester,
        const MediaUploadTile(
          data: MediaUploadTileData(id: '1'),
        ),
      );

      expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    });

    testWidgets('uploading state shows progress percentage', (tester) async {
      await _pump(
        tester,
        const MediaUploadTile(
          data: MediaUploadTileData(
            id: '1',
            status: MediaUploadTileStatus.uploading,
            progress: 0.42,
          ),
        ),
      );

      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('success state shows the success badge and enables preview', (
      tester,
    ) async {
      var previewed = false;
      await _pump(
        tester,
        MediaUploadTile(
          data: const MediaUploadTileData(
            id: '1',
            status: MediaUploadTileStatus.success,
          ),
          onPreview: () => previewed = true,
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      expect(previewed, isTrue);
    });

    testWidgets('failure state shows the error message and a retry action', (
      tester,
    ) async {
      var retried = false;
      await _pump(
        tester,
        MediaUploadTile(
          data: const MediaUploadTileData(
            id: '1',
            status: MediaUploadTileStatus.failure,
            errorMessage: 'Upload failed',
          ),
          onRetry: () => retried = true,
        ),
      );

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      expect(retried, isTrue);
    });

    testWidgets('remove action is only shown when onRemove is provided', (
      tester,
    ) async {
      var removed = false;
      await _pump(
        tester,
        MediaUploadTile(
          data: const MediaUploadTileData(id: '1'),
          onRemove: () => removed = true,
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(removed, isTrue);
    });
  });
}
