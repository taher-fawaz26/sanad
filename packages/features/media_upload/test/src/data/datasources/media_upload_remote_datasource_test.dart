import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_upload/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

class _MockSecureDioClient extends Mock implements SecureDioClient {}

void main() {
  late _MockSecureDioClient client;
  late MediaUploadRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  final successBody = <String, dynamic>{
    'id': 'media-1',
    'originalName': 'photo.jpg',
    'fileName': 'photo-1.jpg',
    'mimeType': 'image/jpeg',
    'size': 3,
    'type': 'image',
    'url': 'https://example.com/photo-1.jpg',
    'createdAt': '2026-01-01T00:00:00.000Z',
  };

  setUp(() {
    client = _MockSecureDioClient();
    dataSource = MediaUploadRemoteDataSourceImpl(client);
  });

  test(
    'uploadSingle posts multipart form data and maps a successful response',
    () async {
      when(
        () => client.postMultipart<dynamic>(
          'media/upload-single',
          formData: any(named: 'formData'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: successBody,
          requestOptions: RequestOptions(path: 'media/upload-single'),
        ),
      );

      final result = await dataSource
          .uploadSingleBytes(
            uploadKey: 'item-1',
            bytes: const [1, 2, 3],
            fileName: 'photo.jpg',
            mimeType: 'image/jpeg',
          )
          .run();

      expect(result.isRight(), isTrue);
      result.match(
        (_) => fail('expected success'),
        (response) {
          expect(response.id, 'media-1');
          expect(response.url, 'https://example.com/photo-1.jpg');
          expect(response.fileName, 'photo-1.jpg');
        },
      );
    },
  );

  test('uploadSingle forwards send progress as a 0.0-1.0 fraction', () async {
    ProgressCallback? onSendProgress;
    when(
      () => client.postMultipart<dynamic>(
        'media/upload-single',
        formData: any(named: 'formData'),
        cancelToken: any(named: 'cancelToken'),
        onSendProgress: any(named: 'onSendProgress'),
      ),
    ).thenAnswer((invocation) async {
      onSendProgress =
          invocation.namedArguments[#onSendProgress] as ProgressCallback?;
      return Response<dynamic>(
        data: successBody,
        requestOptions: RequestOptions(path: 'media/upload-single'),
      );
    });

    final values = <double>[];
    await dataSource
        .uploadSingleBytes(
          uploadKey: 'item-1',
          bytes: const [1, 2, 3],
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          onProgress: values.add,
        )
        .run();

    onSendProgress?.call(50, 100);
    onSendProgress?.call(100, 100);

    expect(values, [0.5, 1.0]);
  });

  test('maps a thrown DioException to a Failure instead of throwing', () async {
    when(
      () => client.postMultipart<dynamic>(
        'media/upload-single',
        formData: any(named: 'formData'),
        cancelToken: any(named: 'cancelToken'),
        onSendProgress: any(named: 'onSendProgress'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: 'media/upload-single'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await dataSource
        .uploadSingleBytes(
          uploadKey: 'item-1',
          bytes: const [1, 2, 3],
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
        )
        .run();

    expect(result.isLeft(), isTrue);
  });

  test('cancelUpload cancels the in-flight CancelToken for that key', () async {
    CancelToken? capturedToken;
    when(
      () => client.postMultipart<dynamic>(
        'media/upload-single',
        formData: any(named: 'formData'),
        cancelToken: any(named: 'cancelToken'),
        onSendProgress: any(named: 'onSendProgress'),
      ),
    ).thenAnswer((invocation) async {
      capturedToken = invocation.namedArguments[#cancelToken] as CancelToken?;
      // Never resolves within this test — cancellation is asserted directly.
      return Completer<Response<dynamic>>().future;
    });

    unawaited(
      dataSource
          .uploadSingleBytes(
            uploadKey: 'item-1',
            bytes: const [1, 2, 3],
            fileName: 'photo.jpg',
            mimeType: 'image/jpeg',
          )
          .run(),
    );
    await Future<void>.delayed(Duration.zero);

    dataSource.cancelUpload('item-1');

    expect(capturedToken?.isCancelled, isTrue);
  });
}
