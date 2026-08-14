import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/presentation/widgets/edit_service_form_body.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

final _service = ProviderServiceEntity(
  id: 'ps-1',
  serviceId: 'svc-1',
  serviceName: 'Wash Car',
  category: const CategoryRefEntity(
    id: 'cat-car',
    name: 'Car',
    description: null,
  ),
  description: 'Exterior wash',
  status: ProviderServiceStatus.active,
  images: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<void> _pump(
  WidgetTester tester,
  MediaUploadBloc bloc, {
  required ValueChanged<bool> onCompletenessChanged,
  Key? key,
}) async {
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

  setUp(() {
    repository = _MockMediaUploadRepository();
    bloc = MediaUploadBloc(repository: repository);
  });

  tearDown(() => bloc.close());

  testWidgets(
    'shows read-only service name and category, and a prefilled description',
    (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

      expect(find.text('Wash Car'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Exterior wash'), findsOneWidget);
      expect(find.byType(AppSelectField), findsNWidgets(2));
      expect(find.byType(AppTextField), findsOneWidget);
    },
  );

  testWidgets('hasUnsavedInput is false until the description changes', (
    tester,
  ) async {
    final key = GlobalKey<EditServiceFormBodyState>();
    await _pump(tester, bloc, onCompletenessChanged: (_) {}, key: key);

    expect(key.currentState!.hasUnsavedInput, isFalse);

    await tester.enterText(find.byType(TextField).first, 'Full valet wash');
    await tester.pumpAndSettle();

    expect(key.currentState!.hasUnsavedInput, isTrue);
    expect(key.currentState!.description, 'Full valet wash');
  });

  group('description validation', () {
    testWidgets('valid input shows no length error', (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).first, 'A valid update');
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('exactly 500 characters passes', (tester) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).first, 'a' * 500);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('501 characters shows the corrected length error', (
      tester,
    ) async {
      await _pump(tester, bloc, onCompletenessChanged: (_) {});

      await tester.enterText(find.byType(TextField).first, 'a' * 501);
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsOneWidget,
      );
    });
  });
}
