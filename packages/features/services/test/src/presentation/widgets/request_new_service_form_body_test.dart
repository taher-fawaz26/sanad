import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/presentation/widgets/request_new_service_form_body.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

PickedAsset _asset({String name = 'photo.jpg'}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: 'image/jpeg',
  size: 1024,
  assetType: AssetType.image,
);

Future<void> _pump(
  WidgetTester tester,
  MediaUploadBloc bloc, {
  required ValueChanged<bool> onCompletenessChanged,
}) async {
  // The Category modal sheet can exceed the default (small) test surface —
  // use a realistic device-sized surface instead.
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
              child: RequestNewServiceFormBody(
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

  testWidgets(
    'renders Category, Requested Service Name, Description and Images fields',
    (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

      expect(find.byType(AppSelectField), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.text('services.add_service.category_hint'), findsOneWidget);
      expect(
        find.text('services.request_new_service.service_name_hint'),
        findsOneWidget,
      );
    },
  );

  testWidgets('selecting a category updates the field', (tester) async {
    await _pump(tester, bloc, onCompletenessChanged: (_) {});

    await tester.tap(find.byType(AppSelectField));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Car'));
    await tester.pumpAndSettle();

    expect(find.text('Car'), findsOneWidget);
  });

  testWidgets('entering a requested service name updates the field', (
    tester,
  ) async {
    await _pump(tester, bloc, onCompletenessChanged: (_) {});

    await tester.enterText(
      find.byType(TextField).first,
      'Ceramic Coating',
    );
    await tester.pumpAndSettle();

    expect(find.text('Ceramic Coating'), findsOneWidget);
  });

  testWidgets('reports complete once category, service name, description and '
      'an uploaded image are all present', (tester) async {
    when(
      () => repository.upload(
        uploadKey: any(named: 'uploadKey'),
        asset: any(named: 'asset'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer(
      (_) => TaskEither(
        () async => Either.right(
          const UploadedMedia(
            mediaId: 'media-1',
            // Empty on purpose: a real preview URL would make
            // MediaUploadTile fetch a real (unreachable) network image
            // during the test.
            url: '',
            originalName: 'photo.jpg',
            fileName: 'photo-1.jpg',
            mimeType: 'image/jpeg',
            size: 1024,
          ),
        ),
      ),
    );

    final completenessEvents = <bool>[];
    await _pump(tester, bloc, onCompletenessChanged: completenessEvents.add);

    await tester.tap(find.byType(AppSelectField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Car'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ceramic Coating');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'A full ceramic coating protection package.',
    );
    await tester.pumpAndSettle();

    expect(completenessEvents, isNot(contains(true)));

    await tester.runAsync(() async {
      bloc.add(MediaUploadAssetAdded(_asset()));
      await bloc.stream.firstWhere((state) => state.uploadedCount > 0);
    });
    await tester.pumpAndSettle();

    expect(completenessEvents.last, isTrue);
  });
}
