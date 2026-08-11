import 'dart:async';

import 'package:asset_picker/asset_picker.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

PickedAsset _asset({
  String name = 'photo.jpg',
  String mimeType = 'image/jpeg',
  int size = 1024,
}) => PickedAsset(
  name: name,
  path: '/tmp/$name',
  mimeType: mimeType,
  size: size,
  assetType: AssetType.image,
);

UploadedMedia _media({
  String mediaId = 'media-1',
  String url = 'https://x/1.jpg',
}) => UploadedMedia(
  mediaId: mediaId,
  url: url,
  originalName: 'photo.jpg',
  fileName: 'photo-1.jpg',
  mimeType: 'image/jpeg',
  size: 1024,
);

void main() {
  late _MockMediaUploadRepository repository;

  setUpAll(() {
    registerFallbackValue(_asset());
  });

  setUp(() {
    repository = _MockMediaUploadRepository();
  });

  void Function(double)? stubUpload({
    required Either<Failure, UploadedMedia> Function() result,
  }) {
    void Function(double)? captured;
    when(
      () => repository.upload(
        uploadKey: any(named: 'uploadKey'),
        asset: any(named: 'asset'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((invocation) {
      captured =
          invocation.namedArguments[#onProgress] as void Function(double)?;
      return TaskEither(() async => result());
    });
    return captured;
  }

  group('single item lifecycle', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'pending -> uploading -> success, preserving mediaId and url',
      setUp: () {
        stubUpload(result: () => Either.right(_media()));
      },
      build: () => MediaUploadBloc(repository: repository),
      act: (bloc) => bloc.add(MediaUploadAssetAdded(_asset())),
      expect: () => [
        isA<MediaUploadState>().having(
          (s) => s.items.single.status,
          'status',
          MediaUploadStatus.pending,
        ),
        isA<MediaUploadState>().having(
          (s) => s.items.single.status,
          'status',
          MediaUploadStatus.uploading,
        ),
        isA<MediaUploadState>()
            .having(
              (s) => s.items.single.status,
              'status',
              MediaUploadStatus.success,
            )
            .having((s) => s.items.single.mediaId, 'mediaId', 'media-1')
            .having((s) => s.items.single.url, 'url', 'https://x/1.jpg'),
      ],
    );

    blocTest<MediaUploadBloc, MediaUploadState>(
      'pending -> uploading -> failure -> retry -> success',
      setUp: () {
        var attempt = 0;
        when(
          () => repository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) {
          attempt++;
          if (attempt == 1) {
            return TaskEither(
              () async => Either.left(const ServerFailure(message: 'boom')),
            );
          }
          return TaskEither(() async => Either.right(_media()));
        });
      },
      build: () => MediaUploadBloc(repository: repository),
      act: (bloc) async {
        bloc.add(MediaUploadAssetAdded(_asset()));
        await Future<void>.delayed(Duration.zero);
        final localId = bloc.state.items.single.localId;
        bloc.add(MediaUploadRetryRequested(localId));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.items.single.status, MediaUploadStatus.success);
        expect(bloc.state.items.single.mediaId, 'media-1');
      },
    );
  });

  group('independent per-item state in a batch', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'one failed upload does not affect the other items (success/uploading/failure mix)',
      setUp: () {
        when(
          () => repository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((invocation) {
          final asset = invocation.namedArguments[#asset] as PickedAsset;
          if (asset.name == 'fails.jpg') {
            return TaskEither(
              () async => Either.left(const ServerFailure(message: 'boom')),
            );
          }
          return TaskEither(() async => Either.right(_media()));
        });
      },
      build: () => MediaUploadBloc(repository: repository),
      act: (bloc) => bloc.add(
        MediaUploadAssetsAdded([
          _asset(name: 'ok1.jpg'),
          _asset(name: 'fails.jpg'),
          _asset(name: 'ok2.jpg'),
        ]),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final byName = {
          for (final item in bloc.state.items) item.asset.name: item,
        };
        expect(byName['ok1.jpg']!.status, MediaUploadStatus.success);
        expect(byName['fails.jpg']!.status, MediaUploadStatus.failure);
        expect(byName['ok2.jpg']!.status, MediaUploadStatus.success);
      },
    );
  });

  group('concurrency', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'never uploads more than maxConcurrentUploads items at once',
      setUp: () {
        final completers = <String, Completer<void>>{};
        when(
          () => repository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((invocation) {
          final key = invocation.namedArguments[#uploadKey] as String;
          final completer = completers.putIfAbsent(key, Completer<void>.new);
          return TaskEither(() async {
            await completer.future;
            return Either.right(_media());
          });
        });
      },
      build: () => MediaUploadBloc(
        repository: repository,
        config: const MediaUploadConfig(maxConcurrentUploads: 2),
      ),
      act: (bloc) => bloc.add(
        MediaUploadAssetsAdded([
          _asset(name: 'a.jpg'),
          _asset(name: 'b.jpg'),
          _asset(name: 'c.jpg'),
        ]),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.uploadingCount, 2);
        expect(bloc.state.pendingCount, 1);
      },
    );
  });

  group('validation', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'rejects a file exceeding maxFiles without consuming a concurrency slot',
      build: () => MediaUploadBloc(
        repository: repository,
        config: const MediaUploadConfig(maxFiles: 0),
      ),
      act: (bloc) => bloc.add(MediaUploadAssetAdded(_asset())),
      expect: () => [
        isA<MediaUploadState>().having(
          (s) => s.items.single.failure,
          'failure',
          isA<MaxFilesExceededFailure>(),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        );
      },
    );

    blocTest<MediaUploadBloc, MediaUploadState>(
      'rejects a file exceeding maxFileSize',
      build: () => MediaUploadBloc(
        repository: repository,
        config: const MediaUploadConfig(maxFileSize: 100),
      ),
      act: (bloc) => bloc.add(MediaUploadAssetAdded(_asset(size: 5000))),
      expect: () => [
        isA<MediaUploadState>().having(
          (s) => s.items.single.failure,
          'failure',
          isA<FileTooLargeFailure>(),
        ),
      ],
    );

    blocTest<MediaUploadBloc, MediaUploadState>(
      'rejects a disallowed MIME type',
      build: () => MediaUploadBloc(
        repository: repository,
        config: const MediaUploadConfig(allowedMimeTypes: ['image/png']),
      ),
      act: (bloc) => bloc.add(MediaUploadAssetAdded(_asset())),
      expect: () => [
        isA<MediaUploadState>().having(
          (s) => s.items.single.failure,
          'failure',
          isA<UnsupportedTypeFailure>(),
        ),
      ],
    );
  });

  group('retry all', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'retries every failed item and leaves already-successful items untouched',
      setUp: () {
        when(
          () => repository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) => TaskEither(() async => Either.right(_media())));
      },
      build: () => MediaUploadBloc(repository: repository),
      seed: () => MediaUploadState(
        items: [
          MediaUploadItem(
            localId: '1',
            asset: _asset(name: 'ok.jpg'),
            status: MediaUploadStatus.success,
            mediaId: 'already',
          ),
          MediaUploadItem(
            localId: '2',
            asset: _asset(name: 'retry-me.jpg'),
            status: MediaUploadStatus.failure,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const MediaUploadRetryAllRequested()),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final ok = bloc.state.itemById('1')!;
        final retried = bloc.state.itemById('2')!;
        expect(ok.status, MediaUploadStatus.success);
        expect(ok.mediaId, 'already');
        expect(retried.status, MediaUploadStatus.success);
        expect(retried.mediaId, 'media-1');
      },
    );
  });

  group('remove', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'removes a not-yet-uploaded item and cancels its upload, without '
      'calling deleteMedia (no mediaId yet)',
      build: () => MediaUploadBloc(repository: repository),
      seed: () => MediaUploadState(
        items: [MediaUploadItem(localId: '1', asset: _asset())],
      ),
      act: (bloc) => bloc.add(const MediaUploadRemoveRequested('1')),
      expect: () => [
        isA<MediaUploadState>().having((s) => s.items, 'items', isEmpty),
      ],
      verify: (_) {
        verify(() => repository.cancelUpload('1')).called(1);
        verifyNever(() => repository.deleteMedia(any()));
      },
    );

    blocTest<MediaUploadBloc, MediaUploadState>(
      'removing an already-uploaded item best-effort deletes its backend '
      'media (DELETE /media/{id})',
      setUp: () {
        when(
          () => repository.deleteMedia(any()),
        ).thenAnswer((_) => TaskEither(() async => Either.right(unit)));
      },
      build: () => MediaUploadBloc(repository: repository),
      seed: () => MediaUploadState(
        items: [
          MediaUploadItem(
            localId: '1',
            asset: _asset(),
            status: MediaUploadStatus.success,
            mediaId: 'media-to-delete',
          ),
        ],
      ),
      act: (bloc) => bloc.add(const MediaUploadRemoveRequested('1')),
      expect: () => [
        isA<MediaUploadState>().having((s) => s.items, 'items', isEmpty),
      ],
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        verify(() => repository.cancelUpload('1')).called(1);
        verify(() => repository.deleteMedia('media-to-delete')).called(1);
      },
    );

    blocTest<MediaUploadBloc, MediaUploadState>(
      'removing a remote-seeded item (edit-form pre-fill) never calls '
      'deleteMedia — it is already attached to the service being edited',
      build: () => MediaUploadBloc(repository: repository),
      seed: () => MediaUploadState(
        items: [
          MediaUploadItem.remote(
            mediaId: 'already-attached',
            url: 'https://x/attached.jpg',
          ),
        ],
      ),
      act: (bloc) =>
          bloc.add(const MediaUploadRemoveRequested('already-attached')),
      expect: () => [
        isA<MediaUploadState>().having((s) => s.items, 'items', isEmpty),
      ],
      verify: (_) {
        verifyNever(() => repository.deleteMedia(any()));
      },
    );
  });

  group('replace', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'replaces the asset behind an item, re-uploads under the same '
      'localId, and best-effort deletes the media it replaced',
      setUp: () {
        when(
          () => repository.upload(
            uploadKey: any(named: 'uploadKey'),
            asset: any(named: 'asset'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer(
          (_) => TaskEither(
            () async => Either.right(_media(mediaId: 'new-media')),
          ),
        );
        when(
          () => repository.deleteMedia(any()),
        ).thenAnswer((_) => TaskEither(() async => Either.right(unit)));
      },
      build: () => MediaUploadBloc(repository: repository),
      seed: () => MediaUploadState(
        items: [
          MediaUploadItem(
            localId: '1',
            asset: _asset(name: 'old.jpg'),
            status: MediaUploadStatus.success,
            mediaId: 'old-media',
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        MediaUploadReplaceRequested(
          localId: '1',
          newAsset: _asset(name: 'new.jpg'),
        ),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final item = bloc.state.itemById('1')!;
        expect(item.asset.name, 'new.jpg');
        expect(item.mediaId, 'new-media');
        expect(item.status, MediaUploadStatus.success);
        verify(() => repository.cancelUpload('1')).called(1);
        verify(() => repository.deleteMedia('old-media')).called(1);
      },
    );
  });

  group('clear', () {
    blocTest<MediaUploadBloc, MediaUploadState>(
      'cancels every in-flight upload and clears all items',
      build: () => MediaUploadBloc(repository: repository),
      seed: () => MediaUploadState(
        items: [
          MediaUploadItem(localId: '1', asset: _asset()),
          MediaUploadItem(localId: '2', asset: _asset()),
        ],
      ),
      act: (bloc) => bloc.add(const MediaUploadClearRequested()),
      expect: () => [
        isA<MediaUploadState>().having((s) => s.items, 'items', isEmpty),
      ],
      verify: (_) {
        verify(() => repository.cancelUpload('1')).called(1);
        verify(() => repository.cancelUpload('2')).called(1);
      },
    );
  });
}
