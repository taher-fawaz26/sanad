import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/service_category_summary_entity.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/presentation/widgets/edit_service_form_body.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

PickedAsset _asset({String name = 'photo.jpg'}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: 'image/jpeg',
  size: 1024,
  assetType: AssetType.image,
);

final _service = ServiceRecordEntity(
  id: 'svc-1',
  name: 'Wash Car',
  description: 'Exterior wash',
  price: 50,
  isActive: true,
  category: const ServiceCategorySummaryEntity(
    id: 'cat-car',
    name: 'Car',
    slug: 'car',
    icon: null,
  ),
  media: const [
    ServiceMediaEntity(id: 'media-1', url: 'https://x/1.jpg', type: 'image'),
  ],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<void> _pump(
  WidgetTester tester,
  MediaUploadBloc bloc, {
  required ValueChanged<bool> onCompletenessChanged,
  Key? key,
}) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BlocProvider<MediaUploadBloc>.value(
            value: bloc,
            child: SingleChildScrollView(
              child: EditServiceFormBody(
                key: key,
                service: _service,
                onCompletenessChanged: onCompletenessChanged,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _MockMediaUploadRepository repository;
  late MediaUploadBloc bloc;

  setUpAll(() {
    registerFallbackValue(_asset());
  });

  setUp(() {
    repository = _MockMediaUploadRepository();
    bloc = MediaUploadBloc(repository: repository);
  });

  tearDown(() => bloc.close());

  testWidgets('prefills Name, Category, Price and Description from the '
      'service being edited', (tester) async {
    await _pump(tester, bloc, onCompletenessChanged: (_) {});

    expect(find.text('Wash Car'), findsOneWidget);
    expect(find.text('Car'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('Exterior wash'), findsOneWidget);
  });

  testWidgets(
    'seeds existing service media into the image grid without re-uploading',
    (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});
      await tester.pumpAndSettle();

      expect(bloc.state.items, hasLength(1));
      expect(bloc.state.items.single.mediaId, 'media-1');
      expect(bloc.state.items.single.status, MediaUploadStatus.success);
      verifyNever(
        () => repository.upload(
          uploadKey: any(named: 'uploadKey'),
          asset: any(named: 'asset'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    },
  );

  testWidgets('hasUnsavedInput is false until a field actually changes', (
    tester,
  ) async {
    final key = GlobalKey<EditServiceFormBodyState>();
    await _pump(tester, bloc, onCompletenessChanged: (_) {}, key: key);

    expect(key.currentState!.hasUnsavedInput, isFalse);

    await tester.enterText(find.byType(TextField).first, 'Wash Car Deluxe');
    await tester.pumpAndSettle();

    expect(key.currentState!.hasUnsavedInput, isTrue);
    expect(key.currentState!.name, 'Wash Car Deluxe');
  });
}
