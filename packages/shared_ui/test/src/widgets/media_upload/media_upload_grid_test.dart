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
  group('MediaUploadGrid', () {
    testWidgets(
      'uses emptyStateBuilder instead of the built-in empty state when set',
      (tester) async {
        var added = false;
        await _pump(
          tester,
          MediaUploadGrid(
            items: const [],
            emptyStateBuilder: (context) => GestureDetector(
              onTap: () => added = true,
              child: const Text('Custom drop zone'),
            ),
          ),
        );

        expect(find.text('Custom drop zone'), findsOneWidget);
        expect(find.text('No files added yet'), findsNothing);

        await tester.tap(find.text('Custom drop zone'));
        expect(added, isTrue);
      },
    );

    testWidgets(
      'shows the empty state and triggers onAdd when there are no items',
      (
        tester,
      ) async {
        var added = false;
        await _pump(
          tester,
          MediaUploadGrid(
            items: const [],
            onAdd: () => added = true,
          ),
        );

        expect(find.text('No files added yet'), findsOneWidget);
        expect(find.byType(MediaUploadTile), findsNothing);

        await tester.tap(find.byType(AppButton));
        expect(added, isTrue);
      },
    );

    testWidgets('renders a summary header derived from item statuses', (
      tester,
    ) async {
      await _pump(
        tester,
        const MediaUploadGrid(
          items: [
            MediaUploadTileData(id: '1', status: MediaUploadTileStatus.success),
            MediaUploadTileData(
              id: '2',
              status: MediaUploadTileStatus.uploading,
              progress: 0.5,
            ),
            MediaUploadTileData(id: '3', status: MediaUploadTileStatus.failure),
          ],
        ),
      );

      expect(find.textContaining('1 of 3 uploaded'), findsOneWidget);
      expect(find.textContaining('1 uploading'), findsOneWidget);
      expect(find.textContaining('1 failed'), findsOneWidget);
      expect(find.byType(MediaUploadTile), findsNWidgets(3));
    });

    testWidgets('shows "Retry all" only when at least one item failed', (
      tester,
    ) async {
      var retriedAll = false;
      await _pump(
        tester,
        MediaUploadGrid(
          items: const [
            MediaUploadTileData(id: '1', status: MediaUploadTileStatus.failure),
          ],
          onRetryAll: () => retriedAll = true,
        ),
      );

      expect(find.text('Retry all'), findsOneWidget);
      await tester.tap(find.text('Retry all'));
      expect(retriedAll, isTrue);
    });

    testWidgets('hides the Add tile once maxFiles is reached', (tester) async {
      await _pump(
        tester,
        const MediaUploadGrid(
          items: [
            MediaUploadTileData(id: '1', status: MediaUploadTileStatus.success),
          ],
          maxFiles: 1,
        ),
      );

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('shows the Add tile while below maxFiles', (tester) async {
      await _pump(
        tester,
        const MediaUploadGrid(
          items: [
            MediaUploadTileData(id: '1', status: MediaUploadTileStatus.success),
          ],
          maxFiles: 2,
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('forwards per-item callbacks with the tapped item id', (
      tester,
    ) async {
      String? removedId;
      await _pump(
        tester,
        MediaUploadGrid(
          items: const [
            MediaUploadTileData(
              id: 'item-1',
              status: MediaUploadTileStatus.success,
            ),
          ],
          onRemove: (id) => removedId = id,
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(removedId, 'item-1');
    });
  });
}
