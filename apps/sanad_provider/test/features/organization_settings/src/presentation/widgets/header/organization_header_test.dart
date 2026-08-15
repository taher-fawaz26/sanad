import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/header/organization_header.dart';

class _MockUploadUseCase extends Mock
    implements UploadOrganizationMediaUseCase {}

class _MockRemoveUseCase extends Mock
    implements RemoveOrganizationMediaUseCase {}

class _MockRepository extends Mock implements OrganizationMediaRepository {}

final _media = EditedMedia(
  bytes: Uint8List.fromList([1, 2, 3]),
  width: 100,
  height: 100,
  mimeType: 'image/jpeg',
  fileName: 'logo.jpg',
  fileSize: 3,
  source: MediaSource.gallery,
);

const _coverUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    '916d86ee-4c74-476d-b89a-31c7222ba752.jpg';
const _profileUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    'e53d2bf5-3b96-48ce-ba3b-da6aa7da9d28.jpg';

const _surfaceSize = Size(360, 800);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OrganizationMediaSlot.cover);
    registerFallbackValue(
      UploadOrganizationMediaParams(
        slot: OrganizationMediaSlot.cover,
        media: _media,
      ),
    );
  });

  setUp(() {
    if (sl.isRegistered<IdentityHeaderBloc>()) {
      sl.unregister<IdentityHeaderBloc>();
    }
    sl.registerFactory<IdentityHeaderBloc>(
      () => IdentityHeaderBloc(
        uploadUseCase: _MockUploadUseCase(),
        removeUseCase: _MockRemoveUseCase(),
        repository: _MockRepository(),
      ),
    );
  });

  tearDown(() {
    if (sl.isRegistered<IdentityHeaderBloc>()) {
      sl.unregister<IdentityHeaderBloc>();
    }
  });

  testWidgets(
    'shows the cover/logo URLs that arrive on a LATER rebuild, not just '
    "the ones present on the widget's first build — regression for the "
    'reported bug where fresh network/cache images never appeared because '
    'BlocProvider(create:) only seeds IdentityHeaderBloc once',
    (tester) async {
      // First frame: no data yet (matches the real page's skeleton-profile
      // first build, before the cache/network read resolves).
      await _pump(
        tester,
        const OrganizationHeader(),
      );
      await tester.pump();

      var header = tester.widget<EditableImageHeader>(
        find.byType(EditableImageHeader),
      );
      expect(header.coverUrl, isNull);
      expect(header.avatarUrl, isNull);

      // Same tree position, no key — this is exactly how
      // GeneralSettingsPage's BlocBuilder rebuilds OrganizationHeader once
      // OrganizationSettingsBloc emits the real (or cached) profile.
      await _pump(
        tester,
        const OrganizationHeader(
          coverUrl: _coverUrl,
          logoUrl: _profileUrl,
        ),
      );
      await tester.pump();

      header = tester.widget<EditableImageHeader>(
        find.byType(EditableImageHeader),
      );
      expect(header.coverUrl, _coverUrl);
      expect(header.avatarUrl, _profileUrl);
    },
  );

  testWidgets(
    'shows images immediately when they are already present on the very '
    'first build (e.g. instant cache-hit render)',
    (tester) async {
      await _pump(
        tester,
        const OrganizationHeader(
          coverUrl: _coverUrl,
          logoUrl: _profileUrl,
        ),
      );
      await tester.pump();

      final header = tester.widget<EditableImageHeader>(
        find.byType(EditableImageHeader),
      );
      expect(header.coverUrl, _coverUrl);
      expect(header.avatarUrl, _profileUrl);
    },
  );

  group('upload failure / retry / cancel UX', () {
    late _MockUploadUseCase uploadUseCase;
    late _MockRemoveUseCase removeUseCase;
    late _MockRepository repository;

    setUp(() {
      uploadUseCase = _MockUploadUseCase();
      removeUseCase = _MockRemoveUseCase();
      repository = _MockRepository();
      when(() => repository.cancelUpload(any())).thenAnswer((_) {});

      if (sl.isRegistered<IdentityHeaderBloc>()) {
        sl.unregister<IdentityHeaderBloc>();
      }
      sl.registerFactory<IdentityHeaderBloc>(
        () => IdentityHeaderBloc(
          uploadUseCase: uploadUseCase,
          removeUseCase: removeUseCase,
          repository: repository,
        ),
      );
    });

    tearDown(() {
      if (sl.isRegistered<IdentityHeaderBloc>()) {
        sl.unregister<IdentityHeaderBloc>();
      }
    });

    testWidgets(
      'a failed logo upload shows the failure overlay with a visible error '
      'message',
      (tester) async {
        when(() => uploadUseCase(any())).thenAnswer(
          (_) => TaskEither.left(const ServerFailure(message: 'boom')),
        );

        await _pump(tester, const OrganizationHeader());
        await tester.pump();

        final bloc = tester
            .element(find.byType(EditableImageHeader))
            .read<IdentityHeaderBloc>();
        bloc.add(
          IdentityHeaderMediaSelected(
            slot: OrganizationMediaSlot.logo,
            media: _media,
          ),
        );
        await tester.pump();
        await tester.pump();

        final header = tester.widget<EditableImageHeader>(
          find.byType(EditableImageHeader),
        );
        expect(header.avatarFailed, isTrue);
        expect(header.avatarErrorMessage, isNotNull);
        expect(find.byType(MediaFailureOverlay), findsOneWidget);
      },
    );

    testWidgets(
      'tapping retry on a failed logo dispatches IdentityHeaderUploadRetried '
      'and re-attempts the upload',
      (tester) async {
        when(() => uploadUseCase(any())).thenAnswer(
          (_) => TaskEither.left(const ServerFailure(message: 'boom')),
        );

        await _pump(tester, const OrganizationHeader());
        await tester.pump();

        final bloc = tester
            .element(find.byType(EditableImageHeader))
            .read<IdentityHeaderBloc>();
        bloc.add(
          IdentityHeaderMediaSelected(
            slot: OrganizationMediaSlot.logo,
            media: _media,
          ),
        );
        await tester.pump();
        await tester.pump();

        when(() => uploadUseCase(any())).thenAnswer(
          (_) => TaskEither.right(
            const OrganizationMediaEntity(url: 'https://cdn/ok.jpg'),
          ),
        );

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();
        await tester.pump();

        verify(() => uploadUseCase(any())).called(2);
        final header = tester.widget<EditableImageHeader>(
          find.byType(EditableImageHeader),
        );
        expect(header.avatarUrl, 'https://cdn/ok.jpg');
        expect(header.avatarFailed, isFalse);
      },
    );

    testWidgets(
      'tapping cancel on a busy cover upload dispatches '
      'IdentityHeaderUploadCancelled and asks the repository to cancel',
      (tester) async {
        final completer =
            Completer<Either<Failure, OrganizationMediaEntity>>();
        when(
          () => uploadUseCase(any()),
        ).thenAnswer((_) => TaskEither(() => completer.future));

        await _pump(tester, const OrganizationHeader());
        await tester.pump();

        final bloc = tester
            .element(find.byType(EditableImageHeader))
            .read<IdentityHeaderBloc>();
        bloc.add(
          IdentityHeaderMediaSelected(
            slot: OrganizationMediaSlot.cover,
            media: _media,
          ),
        );
        await tester.pump();
        await tester.pump();

        var header = tester.widget<EditableImageHeader>(
          find.byType(EditableImageHeader),
        );
        expect(header.coverBusy, isTrue);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        verify(
          () => repository.cancelUpload(OrganizationMediaSlot.cover),
        ).called(1);

        completer.complete(Left(const ServerFailure(message: 'boom')));
        await tester.pump();
        await tester.pump();

        header = tester.widget<EditableImageHeader>(
          find.byType(EditableImageHeader),
        );
        // Cancelled upload must not surface as a failure.
        expect(header.coverBusy, isFalse);
        expect(header.coverFailed, isFalse);
      },
    );

    testWidgets(
      'a successful cover upload clears busy/failed state and shows the new '
      'url',
      (tester) async {
        when(() => uploadUseCase(any())).thenAnswer(
          (_) => TaskEither.right(
            const OrganizationMediaEntity(url: 'https://cdn/new-cover.jpg'),
          ),
        );

        await _pump(tester, const OrganizationHeader());
        await tester.pump();

        final bloc = tester
            .element(find.byType(EditableImageHeader))
            .read<IdentityHeaderBloc>();
        bloc.add(
          IdentityHeaderMediaSelected(
            slot: OrganizationMediaSlot.cover,
            media: _media,
          ),
        );
        await tester.pump();
        await tester.pump();

        final header = tester.widget<EditableImageHeader>(
          find.byType(EditableImageHeader),
        );
        expect(header.coverUrl, 'https://cdn/new-cover.jpg');
        expect(header.coverBusy, isFalse);
        expect(header.coverFailed, isFalse);
      },
    );
  });
}
