// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';

class _MockUploadUseCase extends Mock
    implements UploadOrganizationMediaUseCase {}

class _MockRemoveUseCase extends Mock
    implements RemoveOrganizationMediaUseCase {}

class _MockRepository extends Mock implements OrganizationMediaRepository {}

void main() {
  late _MockUploadUseCase uploadUseCase;
  late _MockRemoveUseCase removeUseCase;
  late _MockRepository repository;

  final media = EditedMedia(
    bytes: Uint8List.fromList([1, 2, 3]),
    width: 100,
    height: 100,
    mimeType: 'image/jpeg',
    fileName: 'logo.jpg',
    fileSize: 3,
    source: MediaSource.gallery,
  );

  setUpAll(() {
    registerFallbackValue(
      UploadOrganizationMediaParams(
        slot: OrganizationMediaSlot.cover,
        media: media,
      ),
    );
    registerFallbackValue(
      const RemoveOrganizationMediaParams(slot: OrganizationMediaSlot.cover),
    );
    registerFallbackValue(OrganizationMediaSlot.cover);
  });

  setUp(() {
    uploadUseCase = _MockUploadUseCase();
    removeUseCase = _MockRemoveUseCase();
    repository = _MockRepository();
  });

  IdentityHeaderBloc build() => IdentityHeaderBloc(
    uploadUseCase: uploadUseCase,
    removeUseCase: removeUseCase,
    repository: repository,
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'seeds slot URLs on initialize',
    build: build,
    act: (bloc) => bloc.add(
      IdentityHeaderInitialized(coverUrl: 'c.png', logoUrl: 'l.png'),
    ),
    verify: (bloc) {
      expect(bloc.state.cover.imageUrl, 'c.png');
      expect(bloc.state.logo.imageUrl, 'l.png');
    },
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'uploads a cover: loading → success with optimistic url',
    build: build,
    setUp: () {
      when(() => uploadUseCase(any())).thenAnswer(
        (_) => TaskEither.right(
          const OrganizationMediaEntity(id: 'i', url: 'https://cdn/c.jpg'),
        ),
      );
    },
    act: (bloc) => bloc.add(
      IdentityHeaderMediaSelected(
        slot: OrganizationMediaSlot.cover,
        media: media,
      ),
    ),
    expect: () => [
      isA<IdentityHeaderState>().having(
        (s) => s.cover.status,
        'cover.status',
        RequestStatus.loading,
      ),
      isA<IdentityHeaderState>()
          .having((s) => s.cover.status, 'cover.status', RequestStatus.success)
          .having(
            (s) => s.cover.imageUrl,
            'cover.imageUrl',
            'https://cdn/c.jpg',
          ),
    ],
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'upload failure keeps lastMedia for retry',
    build: build,
    setUp: () {
      when(() => uploadUseCase(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
    },
    act: (bloc) => bloc.add(
      IdentityHeaderMediaSelected(
        slot: OrganizationMediaSlot.logo,
        media: media,
      ),
    ),
    verify: (bloc) {
      expect(bloc.state.logo.status, RequestStatus.failure);
      expect(bloc.state.logo.canRetry, isTrue);
      expect(bloc.state.logo.lastMedia, media);
    },
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'retry re-uploads the last media',
    build: build,
    seed: () => IdentityHeaderState(
      logo: IdentityMediaSlotState(
        status: RequestStatus.failure,
        failure: const ServerFailure(message: 'boom'),
        lastMedia: media,
      ),
    ),
    setUp: () {
      when(() => uploadUseCase(any())).thenAnswer(
        (_) => TaskEither.right(const OrganizationMediaEntity(url: 'ok.jpg')),
      );
    },
    act: (bloc) =>
        bloc.add(IdentityHeaderUploadRetried(slot: OrganizationMediaSlot.logo)),
    verify: (bloc) {
      expect(bloc.state.logo.status, RequestStatus.success);
      expect(bloc.state.logo.imageUrl, 'ok.jpg');
      verify(() => uploadUseCase(any())).called(1);
    },
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'cancelling an in-flight upload returns to initial, not failure, and '
    "asks the repository to cancel the slot's in-flight request",
    build: build,
    setUp: () {
      when(() => repository.cancelUpload(any())).thenAnswer((_) {});
    },
    seed: () => IdentityHeaderState(
      logo: IdentityMediaSlotState(
        status: RequestStatus.loading,
        lastMedia: media,
      ),
    ),
    act: (bloc) => bloc.add(
      IdentityHeaderUploadCancelled(slot: OrganizationMediaSlot.logo),
    ),
    verify: (bloc) {
      verify(
        () => repository.cancelUpload(OrganizationMediaSlot.logo),
      ).called(1);
      // Cancelling alone doesn't resolve the in-flight upload future — the
      // slot stays `loading` (still busy) until that future completes and
      // the bloc swallows the resulting failure. See the next test.
      expect(bloc.state.logo.status, RequestStatus.loading);
    },
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    "a cancelled upload's eventual failure is swallowed — the slot resets "
    'to initial instead of surfacing an error',
    build: build,
    setUp: () {
      when(() => repository.cancelUpload(any())).thenAnswer((_) {});
    },
    act: (bloc) async {
      final completer = Completer<Either<Failure, OrganizationMediaEntity>>();
      when(
        () => uploadUseCase(any()),
      ).thenAnswer((_) => TaskEither(() => completer.future));

      bloc.add(
        IdentityHeaderMediaSelected(
          slot: OrganizationMediaSlot.logo,
          media: media,
        ),
      );
      // Let `_upload` run up to its `await uploadUseCase(...)` point before
      // cancelling, so the cancel is genuinely racing an in-flight upload.
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        IdentityHeaderUploadCancelled(slot: OrganizationMediaSlot.logo),
      );
      await Future<void>.delayed(Duration.zero);
      completer.complete(Left(const ServerFailure(message: 'boom')));
    },
    verify: (bloc) {
      expect(bloc.state.logo.status, RequestStatus.initial);
      expect(bloc.state.logo.hasError, isFalse);
      expect(bloc.state.logo.progress, 0);
    },
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'remove clears the image on success',
    build: build,
    seed: () => IdentityHeaderState(
      cover: IdentityMediaSlotState(imageUrl: 'c.png'),
    ),
    setUp: () {
      when(
        () => removeUseCase(any()),
      ).thenAnswer((_) => TaskEither.right(unit));
    },
    act: (bloc) =>
        bloc.add(IdentityHeaderMediaRemoved(slot: OrganizationMediaSlot.cover)),
    verify: (bloc) {
      expect(bloc.state.cover.status, RequestStatus.success);
      expect(bloc.state.cover.hasImage, isFalse);
    },
  );

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'a failed remove surfaces as a non-retryable failure and leaves the '
    'existing image untouched — never optimistically cleared',
    build: build,
    seed: () => IdentityHeaderState(
      cover: IdentityMediaSlotState(imageUrl: 'c.png'),
    ),
    setUp: () {
      when(() => removeUseCase(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
    },
    act: (bloc) =>
        bloc.add(IdentityHeaderMediaRemoved(slot: OrganizationMediaSlot.cover)),
    verify: (bloc) {
      expect(bloc.state.cover.status, RequestStatus.failure);
      expect(bloc.state.cover.hasError, isTrue);
      // No `lastMedia` for a remove attempt — nothing to retry against, so
      // `canRetry` must be false (this is what the header widget uses to
      // decide the persistent on-image overlay must NOT render for this
      // failure; see `_isNonRetryableFailure`).
      expect(bloc.state.cover.canRetry, isFalse);
      expect(bloc.state.cover.lastMedia, isNull);
      // The image itself must be untouched by the failed removal.
      expect(bloc.state.cover.imageUrl, 'c.png');
    },
  );

  // Profile and cover are independent: each slot has its own endpoint and its
  // own state, so removing one must not disturb the other.
  for (final removed in OrganizationMediaSlot.values) {
    final other = removed == OrganizationMediaSlot.cover
        ? OrganizationMediaSlot.logo
        : OrganizationMediaSlot.cover;

    blocTest<IdentityHeaderBloc, IdentityHeaderState>(
      'removing the ${removed.name} leaves the ${other.name} untouched',
      build: build,
      seed: () => IdentityHeaderState(
        cover: IdentityMediaSlotState(imageUrl: 'c.png'),
        logo: IdentityMediaSlotState(imageUrl: 'l.png'),
      ),
      setUp: () {
        when(
          () => removeUseCase(any()),
        ).thenAnswer((_) => TaskEither.right(unit));
      },
      act: (bloc) => bloc.add(IdentityHeaderMediaRemoved(slot: removed)),
      verify: (bloc) {
        expect(bloc.state.slot(removed).hasImage, isFalse);
        expect(
          bloc.state.slot(other).imageUrl,
          other == OrganizationMediaSlot.cover ? 'c.png' : 'l.png',
        );
        verify(
          () => removeUseCase(RemoveOrganizationMediaParams(slot: removed)),
        ).called(1);
      },
    );
  }

  blocTest<IdentityHeaderBloc, IdentityHeaderState>(
    'IdentityHeaderFailureAcknowledged clears status/failure back to '
    'initial without touching imageUrl — used once a non-retryable failure '
    '(e.g. a failed remove) has been shown to the user, so nothing about it '
    'lingers in state and a navigate-away/back is never required to recover',
    build: build,
    seed: () => IdentityHeaderState(
      cover: IdentityMediaSlotState(
        status: RequestStatus.failure,
        imageUrl: 'c.png',
        failure: const ServerFailure(message: 'boom'),
      ),
    ),
    act: (bloc) => bloc.add(
      IdentityHeaderFailureAcknowledged(slot: OrganizationMediaSlot.cover),
    ),
    verify: (bloc) {
      expect(bloc.state.cover.status, RequestStatus.initial);
      expect(bloc.state.cover.hasError, isFalse);
      expect(bloc.state.cover.failure, isNull);
      expect(bloc.state.cover.imageUrl, 'c.png');
    },
  );
}
