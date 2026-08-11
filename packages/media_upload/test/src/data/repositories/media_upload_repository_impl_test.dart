import 'dart:typed_data';

import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:media_upload/src/data/models/upload_media_response.dart';
import 'package:media_upload/src/data/repositories/media_upload_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockMediaUploadRemoteDataSource extends Mock
    implements MediaUploadRemoteDataSource {}

void main() {
  late _MockMediaUploadRemoteDataSource dataSource;
  late MediaUploadRepositoryImpl repository;

  const response = UploadMediaResponse(
    id: 'media-1',
    originalName: 'photo.jpg',
    fileName: 'photo-1.jpg',
    mimeType: 'image/jpeg',
    size: 3,
    url: 'https://example.com/photo-1.jpg',
    type: 'image',
  );

  setUp(() {
    dataSource = _MockMediaUploadRemoteDataSource();
    repository = MediaUploadRepositoryImpl(dataSource);
  });

  test(
    'uploads bytes-backed assets via uploadSingleBytes and preserves mediaId/url',
    () async {
      when(
        () => dataSource.uploadSingleBytes(
          uploadKey: any(named: 'uploadKey'),
          bytes: any(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeType: any(named: 'mimeType'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => TaskEither.right(response));

      final asset = PickedAsset(
        name: 'photo.jpg',
        path: '',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
        size: 3,
        assetType: AssetType.image,
      );

      final result = await repository
          .upload(uploadKey: 'item-1', asset: asset)
          .run();

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (media) {
          expect(media.mediaId, 'media-1');
          expect(media.url, 'https://example.com/photo-1.jpg');
          expect(media.originalName, 'photo.jpg');
        },
      );
      verifyNever(
        () => dataSource.uploadSingle(
          uploadKey: any(named: 'uploadKey'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          mimeType: any(named: 'mimeType'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    },
  );

  test(
    'uploads path-backed assets via uploadSingle when no bytes are present',
    () async {
      when(
        () => dataSource.uploadSingle(
          uploadKey: any(named: 'uploadKey'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          mimeType: any(named: 'mimeType'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => TaskEither.right(response));

      const asset = PickedAsset(
        name: 'photo.jpg',
        path: '/tmp/photo.jpg',
        mimeType: 'image/jpeg',
        size: 3,
        assetType: AssetType.image,
      );

      final result = await repository
          .upload(uploadKey: 'item-1', asset: asset)
          .run();

      expect(result.isRight(), isTrue);
    },
  );

  test('propagates a Failure from the data source', () async {
    when(
      () => dataSource.uploadSingle(
        uploadKey: any(named: 'uploadKey'),
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
        mimeType: any(named: 'mimeType'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer(
      (_) => TaskEither.left(const ServerFailure(message: 'boom')),
    );

    const asset = PickedAsset(
      name: 'photo.jpg',
      path: '/tmp/photo.jpg',
      mimeType: 'image/jpeg',
      size: 3,
      assetType: AssetType.image,
    );

    final result = await repository
        .upload(uploadKey: 'item-1', asset: asset)
        .run();

    expect(result.isLeft(), isTrue);
  });

  test('cancelUpload delegates to the data source', () {
    repository.cancelUpload('item-1');
    verify(() => dataSource.cancelUpload('item-1')).called(1);
  });

  test('deleteMedia delegates to the data source', () async {
    when(
      () => dataSource.deleteMedia('media-1'),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await repository.deleteMedia('media-1').run();

    expect(result.isRight(), isTrue);
    verify(() => dataSource.deleteMedia('media-1')).called(1);
  });
}
