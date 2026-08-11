// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_media_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/organization_media_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/organization_media_repository_impl.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';

class _MockDataSource extends Mock
    implements OrganizationMediaRemoteDataSource {}

/// Real pass-through: mocktail can't reliably stub the generic `execute<T>`
/// across differing type arguments, so a Fake mirrors NetworkGuard's
/// connected → run-the-action behaviour.
class _FakeNetworkGuard extends Fake implements NetworkGuard {
  @override
  TaskEither<Failure, T> execute<T>({required TaskEither<Failure, T> action}) =>
      action;
}

void main() {
  late _MockDataSource dataSource;
  late OrganizationMediaRepositoryImpl repository;

  final media = EditedMedia(
    bytes: Uint8List.fromList([1, 2, 3]),
    width: 10,
    height: 10,
    mimeType: 'image/jpeg',
    fileName: 'c.jpg',
    fileSize: 3,
    source: MediaSource.gallery,
  );

  setUpAll(() {
    registerFallbackValue(media);
    registerFallbackValue(OrganizationMediaSlot.cover);
  });

  setUp(() {
    dataSource = _MockDataSource();
    repository = OrganizationMediaRepositoryImpl(
      dataSource,
      _FakeNetworkGuard(),
    );
  });

  test('uploadMedia maps the response DTO to a domain entity', () async {
    when(
      () => dataSource.uploadMedia(
        slot: any(named: 'slot'),
        media: any(named: 'media'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer(
      (_) => TaskEither.right(
        const OrganizationMediaResponse(id: 'i', url: 'https://cdn/c.jpg'),
      ),
    );

    final result = await repository
        .uploadMedia(slot: OrganizationMediaSlot.cover, media: media)
        .run();

    expect(result.isRight(), isTrue);
    result.match((_) => fail('expected right'), (e) {
      expect(e.id, 'i');
      expect(e.url, 'https://cdn/c.jpg');
    });
  });

  test('removeMedia delegates through the guard', () async {
    when(
      () => dataSource.removeMedia(slot: any(named: 'slot')),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await repository
        .removeMedia(slot: OrganizationMediaSlot.logo)
        .run();

    expect(result.isRight(), isTrue);
    verify(
      () => dataSource.removeMedia(slot: OrganizationMediaSlot.logo),
    ).called(1);
  });

  test('cancelUpload delegates to the datasource', () {
    repository.cancelUpload(OrganizationMediaSlot.cover);
    verify(
      () => dataSource.cancelUpload(OrganizationMediaSlot.cover),
    ).called(1);
  });
}
