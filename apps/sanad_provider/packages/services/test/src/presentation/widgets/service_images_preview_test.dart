import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/presentation/widgets/service_images_preview.dart';

// No EasyLocalization bootstrap — see service_list_item_test.dart's note.
// `.tr()` falls back to the raw key, so assertions below match on the key
// itself, exactly like the sibling ServiceListItem tests.

final _images = [
  const ProviderServiceImageEntity(
    id: 'img-1',
    mediaId: 'media-1',
    url: 'https://example.com/1.png',
    isPrimary: true,
  ),
  const ProviderServiceImageEntity(
    id: 'img-2',
    mediaId: 'media-2',
    url: 'https://example.com/2.png',
    isPrimary: false,
  ),
  const ProviderServiceImageEntity(
    id: 'img-3',
    mediaId: 'media-3',
    url: 'https://example.com/3.png',
    isPrimary: false,
  ),
  const ProviderServiceImageEntity(
    id: 'img-4',
    mediaId: 'media-4',
    url: 'https://example.com/4.png',
    isPrimary: false,
  ),
];

const _surfaceSize = Size(390, 844);

Future<void> _pump(
  WidgetTester tester,
  List<ProviderServiceImageEntity> images,
) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ServiceImagesPreview(images: images),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: AppNetworkImage's CachedNetworkImage keeps trying a
  // real network fetch for these fake URLs and never settles in this
  // sandboxed test environment (mirrors service_list_item_test.dart, which
  // sidesteps the same issue by using an empty images list instead). A
  // single pump is enough — the assertions only need the widget tree, not
  // a loaded image.
  await tester.pump();
}

void main() {
  testWidgets('renders the "Images" label and one thumbnail per image', (
    tester,
  ) async {
    await _pump(tester, _images);

    expect(find.text('services.details.images'), findsOneWidget);
    expect(find.byType(AppNetworkImage), findsNWidgets(_images.length));
  });

  testWidgets('renders no add tile, regardless of image count', (
    tester,
  ) async {
    await _pump(tester, _images);

    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('services.add_service.images_add_label'), findsNothing);
  });

  testWidgets('is purely a display grid — no filename/status chrome leaks '
      'through', (tester) async {
    await _pump(tester, _images);

    // The old Add/Request-New-Service upload-card look (filename caption,
    // "Uploaded" status pill) must never appear here.
    expect(find.text('media-1'), findsNothing);
    expect(find.text('services.images_uploaded_success'), findsNothing);
  });

  testWidgets('shows every image even when there are more than 3', (
    tester,
  ) async {
    await _pump(tester, _images);

    expect(_images.length, greaterThan(3));
    expect(find.byType(AppNetworkImage), findsNWidgets(4));
  });
}
