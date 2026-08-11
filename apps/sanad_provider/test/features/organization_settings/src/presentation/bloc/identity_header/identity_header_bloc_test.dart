// ignore_for_file: prefer_const_constructors

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
}
