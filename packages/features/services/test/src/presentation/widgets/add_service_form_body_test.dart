import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/presentation/widgets/add_service_form_body.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

PickedAsset _asset({String name = 'photo.jpg'}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: 'image/jpeg',
  size: 1024,
  assetType: AssetType.image,
);

void _noop() {}

Future<void> _pump(
  WidgetTester tester,
  MediaUploadBloc bloc, {
  required ValueChanged<bool> onCompletenessChanged,
  VoidCallback onRequestNewService = _noop,
}) async {
  // The Category/Service Name modal sheets can exceed the default (small)
  // test surface — use a realistic device-sized surface instead.
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
              child: AddServiceFormBody(
                onCompletenessChanged: onCompletenessChanged,
                onRequestNewService: onRequestNewService,
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

  testWidgets('renders Category, Service Name, Description and Images fields', (
    tester,
  ) async {
    await _pump(tester, bloc, onCompletenessChanged: (_) {});

    expect(find.byType(AppSelectField), findsNWidgets(2));
    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.text('services.add_service.category_hint'), findsOneWidget);
    expect(
      find.text('services.add_service.service_name_hint'),
      findsOneWidget,
    );
    // No category selected yet, so the inline "didn't find your service?"
    // hint is not shown.
    expect(
      find.text('services.add_service.inline_not_found_prefix'),
      findsNothing,
    );
  });

  testWidgets(
    'selecting a category updates the field and shows the inline hint',
    (
      tester,
    ) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      expect(find.text('Car'), findsOneWidget);
      expect(
        find.textContaining(
          'services.add_service.inline_not_found_prefix',
          findRichText: true,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping the inline "Request New service" link invokes onRequestNewService',
    (tester) async {
      var requestedNewService = false;
      await _pump(
        tester,
        bloc,
        onCompletenessChanged: (_) {},
        onRequestNewService: () => requestedNewService = true,
      );

      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      final linkWidget = tester.widget<AppInlineLinkText>(
        find.byType(AppInlineLinkText),
      );
      linkWidget.onLinkTap();

      expect(requestedNewService, isTrue);
    },
  );

  testWidgets('service search with no match shows the not-found state', (
    tester,
  ) async {
    await _pump(tester, bloc, onCompletenessChanged: (_) {});

    await tester.tap(find.byType(AppSelectField).at(1));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AppSearchField),
        matching: find.byType(TextField),
      ),
      'nonexistent service xyz',
    );
    await tester.pumpAndSettle();

    expect(find.text('services.add_service.not_found_title'), findsOneWidget);
    expect(
      find.text('services.add_service.request_new_service'),
      findsOneWidget,
    );
  });

  testWidgets('reports complete once category, service, description and an '
      'uploaded image are all present', (tester) async {
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
    await _pump(
      tester,
      bloc,
      onCompletenessChanged: completenessEvents.add,
    );

    await tester.tap(find.byType(AppSelectField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Car'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppSelectField).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wash Car'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Full exterior and interior car wash.',
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
