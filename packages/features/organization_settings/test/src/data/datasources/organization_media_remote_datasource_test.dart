// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/organization_media_remote_datasource.dart';
import 'package:organization_settings/src/domain/entities/organization_media_slot.dart';

class _MockSecureDioClient extends Mock implements SecureDioClient {}

void main() {
  late _MockSecureDioClient client;
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

  setUpAll(() => registerFallbackValue(FormData()));

  setUp(() {
    client = _MockSecureDioClient();
    dataSource = OrganizationMediaRemoteDataSourceImpl(client);
  });

  test(
    'uploadMedia posts multipart to the slot endpoint with no manual '
    'Authorization header',
    () async {
      when(
        () => client.postMultipart<dynamic>(
          any(),
          formData: any(named: 'formData'),
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
          onSendProgress: any(named: 'onSendProgress'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: <String, dynamic>{'id': 'i', 'url': 'u'},
          requestOptions: RequestOptions(path: OrganizationMediaSlot.cover.endpoint),
        ),
      );

      final result = await dataSource
          .uploadMedia(slot: OrganizationMediaSlot.cover, media: media)
          .run();

      expect(result.isRight(), isTrue);

      final captured = verify(
        () => client.postMultipart<dynamic>(
          captureAny(),
          formData: captureAny(named: 'formData'),
          cancelToken: any(named: 'cancelToken'),
          options: captureAny(named: 'options'),
          onSendProgress: any(named: 'onSendProgress'),
        ),
      ).captured;

      expect(captured[0], OrganizationMediaSlot.cover.endpoint);
      expect((captured[1] as FormData).files.single.key, 'file');
      expect(captured[2], isNull); // no Options / Authorization header
    },
  );

  test('uploadMedia forwards clamped progress', () async {
    void Function(int, int)? cb;
    when(
      () => client.postMultipart<dynamic>(
        any(),
        formData: any(named: 'formData'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
        onSendProgress: any(named: 'onSendProgress'),
      ),
    ).thenAnswer((invocation) async {
      cb = invocation.namedArguments[#onSendProgress] as void Function(int, int)?;
      return Response<dynamic>(
        data: <String, dynamic>{},
        requestOptions: RequestOptions(path: 'x'),
      );
    });

    final values = <double>[];
    await dataSource
        .uploadMedia(
          slot: OrganizationMediaSlot.logo,
          media: media,
          onProgress: values.add,
        )
        .run();

    cb?.call(25, 100);
    cb?.call(500, 100);
    expect(values, [0.25, 1.0]);
  });

  test('removeMedia deletes the slot endpoint', () async {
    when(() => client.delete<dynamic>(any())).thenAnswer(
      (_) async => Response<dynamic>(
        data: null,
        requestOptions: RequestOptions(path: OrganizationMediaSlot.logo.endpoint),
      ),
    );

    final result =
        await dataSource.removeMedia(slot: OrganizationMediaSlot.logo).run();

    expect(result.isRight(), isTrue);
    verify(() => client.delete<dynamic>(OrganizationMediaSlot.logo.endpoint))
        .called(1);
  });
}
