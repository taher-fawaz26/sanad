// ignore_for_file: prefer_const_constructors
// Uses runtime-constructed EditedMedia fixtures below.

import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:organization_settings/src/data/datasources/organization_media_remote_datasource.dart';
import 'package:organization_settings/src/data/models/organization_media_response.dart';
import 'package:organization_settings/src/data/models/uploaded_media_response.dart';
import 'package:organization_settings/src/domain/entities/organization_media_slot.dart';

class _MockMediaUploadRemoteDataSource extends Mock
    implements MediaUploadRemoteDataSource {}

class _MockBaseApiClient extends Mock implements BaseApiClient {}

void main() {
  late _MockMediaUploadRemoteDataSource mediaUpload;
  late _MockBaseApiClient apiClient;
  late OrganizationMediaRemoteDataSourceImpl dataSource;

  final media = EditedMedia(
    bytes: Uint8List.fromList([1, 2, 3]),
    width: 10,
    height: 10,
    mimeType: 'image/jpeg',
    fileName: 'cover.jpg',
    fileSize: 3,
    source: MediaSource.gallery,
  );

  const uploaded = UploadedMediaResponse(
    id: 'media-1',
    url: 'https://example.com/media-1.jpg',
    originalName: 'cover.jpg',
    mimeType: 'image/jpeg',
    size: 3,
  );

  setUpAll(() {
    registerFallbackValue(RequestMethod.get);
  });

  setUp(() {
    mediaUpload = _MockMediaUploadRemoteDataSource();
    apiClient = _MockBaseApiClient();
    dataSource = OrganizationMediaRemoteDataSourceImpl(mediaUpload, apiClient);
  });

  test(
    'uploadMedia uploads via media/upload-single then PATCHes the slot '
    'endpoint with the returned mediaId',
    () async {
      when(
        () => mediaUpload.uploadSingleBytes(
          uploadKey: any(named: 'uploadKey'),
          bytes: any(named: 'bytes'),
          fileName: any(named: 'fileName'),
          mimeType: any(named: 'mimeType'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => TaskEither.right(uploaded));

      when(
        () => apiClient.request<OrganizationMediaResponse>(
          path: any(named: 'path'),
          method: any(named: 'method'),
          body: any(named: 'body'),
          parser: any(named: 'parser'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((invocation) {
        final parser =
            invocation.namedArguments[#parser]
                as OrganizationMediaResponse Function(dynamic);
        return TaskEither.right(parser(<String, dynamic>{'mediaId': 'm1'}));
      });

      final result = await dataSource
          .uploadMedia(slot: OrganizationMediaSlot.cover, media: media)
          .run();

      expect(result.isRight(), isTrue);

      verify(
        () => apiClient.request<OrganizationMediaResponse>(
          path: OrganizationMediaSlot.cover.endpoint,
          method: RequestMethod.patch,
          body: {'mediaId': 'media-1'},
          parser: any(named: 'parser'),
          query: any(named: 'query'),
        ),
      ).called(1);
    },
  );

  test('uploadMedia forwards clamped progress from the upload step', () async {
    void Function(double)? cb;
    when(
      () => mediaUpload.uploadSingleBytes(
        uploadKey: any(named: 'uploadKey'),
        bytes: any(named: 'bytes'),
        fileName: any(named: 'fileName'),
        mimeType: any(named: 'mimeType'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((invocation) {
      cb = invocation.namedArguments[#onProgress] as void Function(double)?;
      return TaskEither.right(uploaded);
    });
    when(
      () => apiClient.request<OrganizationMediaResponse>(
        path: any(named: 'path'),
        method: any(named: 'method'),
        body: any(named: 'body'),
        parser: any(named: 'parser'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((invocation) {
      final parser =
          invocation.namedArguments[#parser]
              as OrganizationMediaResponse Function(dynamic);
      return TaskEither.right(parser(<String, dynamic>{'mediaId': 'm1'}));
    });

    final values = <double>[];
    await dataSource
        .uploadMedia(
          slot: OrganizationMediaSlot.logo,
          media: media,
          onProgress: values.add,
        )
        .run();

    cb?.call(0.25);
    cb?.call(1.0);
    expect(values, [0.25, 1.0]);
  });

  test('removeMedia is not supported by the backend', () async {
    final result = await dataSource
        .removeMedia(slot: OrganizationMediaSlot.logo)
        .run();

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<BusinessRuleFailure>()),
      (_) => fail('expected a failure'),
    );
    verifyZeroInteractions(mediaUpload);
  });
}
