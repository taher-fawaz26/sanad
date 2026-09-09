import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/media_upload_ai_attachment_uploader.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_uploader.dart';

import '../support/attachment_fixtures.dart';

class _MockRepository extends Mock implements MediaUploadRepository {}

class _FakePickedAsset extends Fake implements PickedAsset {}

UploadedMedia _media({String id = 'upl_1', String url = 'https://cdn/1'}) =>
    UploadedMedia(
      mediaId: id,
      url: url,
      originalName: 'photo.jpg',
      fileName: 'photo.jpg',
      mimeType: 'image/jpeg',
      size: 1024,
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakePickedAsset()));

  late _MockRepository repository;
  late MediaUploadAiAttachmentUploader uploader;

  setUp(() {
    repository = _MockRepository();
    uploader = MediaUploadAiAttachmentUploader(repository: repository);
  });

  void stubSuccess(UploadedMedia media) => when(
    () => repository.upload(
      uploadKey: any(named: 'uploadKey'),
      asset: any(named: 'asset'),
    ),
  ).thenReturn(TaskEither.right(media));

  group('mapping an attachment to the upload pipeline', () {
    test('classifies by MIME type using the picker vocabulary', () {
      // Reused rather than re-tabled: a second copy of this mapping would
      // drift from `asset_picker`, which owns it.
      expect(
        MediaUploadAiAttachmentUploader.assetFor(imageFixture()).assetType,
        AssetType.image,
      );
      expect(
        MediaUploadAiAttachmentUploader.assetFor(documentFixture()).assetType,
        AssetType.pdf,
      );
      expect(
        MediaUploadAiAttachmentUploader.assetFor(audioFixture()).assetType,
        AssetType.audio,
      );
      expect(
        MediaUploadAiAttachmentUploader.assetFor(
          documentFixture(
            fileName: 'notes.docx',
            mimeType:
                'application/vnd.openxmlformats-officedocument'
                '.wordprocessingml.document',
            extension: 'docx',
          ),
        ).assetType,
        AssetType.document,
      );
    });

    test('carries the path and never any bytes', () {
      // The attachment hierarchy holds no bytes on purpose; the pipeline must
      // upload from disk so a conversation with photos costs no extra heap.
      final asset = MediaUploadAiAttachmentUploader.assetFor(
        imageFixture(localPath: '/tmp/a.jpg', fileName: 'a.jpg'),
      );

      expect(asset.path, '/tmp/a.jpg');
      expect(asset.name, 'a.jpg');
      expect(asset.bytes, isNull);
    });
  });

  group('uploading', () {
    test('an empty batch performs no I/O', () async {
      final result = await uploader.upload([]);

      expect(result, const AiAttachmentsUploaded([]));
      verifyNever(
        () => repository.upload(
          uploadKey: any(named: 'uploadKey'),
          asset: any(named: 'asset'),
        ),
      );
    });

    test('maps the response onto id, url and the source attachment', () async {
      stubSuccess(_media(id: 'upl_123', url: 'https://cdn/upl_123.jpg'));
      final attachment = imageFixture();

      final result = await uploader.upload([attachment]);

      final uploaded = (result as AiAttachmentsUploaded).attachments.single;
      expect(uploaded.mediaId, 'upl_123');
      expect(uploaded.url, 'https://cdn/upl_123.jpg');
      expect(uploaded.source, attachment);
    });

    test('keys the upload by the attachment id', () async {
      stubSuccess(_media());

      await uploader.upload([imageFixture(id: 'att_abc')]);

      verify(
        () => repository.upload(
          uploadKey: 'att_abc',
          asset: any(named: 'asset'),
        ),
      ).called(1);
    });

    test('a recording uploads despite its stub size', () async {
      // The composer sets `sizeBytes: 1` because it does not stat files. The
      // repository uploads from the path and never reads size, so this must
      // not be treated as a gate.
      stubSuccess(_media(id: 'upl_audio'));

      final result = await uploader.upload([audioFixture(sizeBytes: 1)]);

      expect(result, isA<AiAttachmentsUploaded>());
    });

    test('preserves order across a batch', () async {
      final ids = ['upl_a', 'upl_b', 'upl_c'];
      var call = 0;
      when(
        () => repository.upload(
          uploadKey: any(named: 'uploadKey'),
          asset: any(named: 'asset'),
        ),
      ).thenAnswer((_) => TaskEither.right(_media(id: ids[call++])));

      final result = await uploader.upload([
        imageFixture(id: 'a'),
        documentFixture(id: 'b'),
        audioFixture(id: 'c'),
      ]);

      final uploaded = (result as AiAttachmentsUploaded).attachments;
      expect([for (final u in uploaded) u.mediaId], ids);
    });
  });

  group('a batch is all or nothing', () {
    test('stops at the first failure and does not attempt the rest', () async {
      // A turn that shipped some of its attachments is a message the user did
      // not write, and the client cannot withdraw what already landed.
      when(
        () => repository.upload(
          uploadKey: 'a',
          asset: any(named: 'asset'),
        ),
      ).thenReturn(
        TaskEither.left(const NetworkFailure(message: 'errors.timeout')),
      );

      final result = await uploader.upload([
        imageFixture(id: 'a'),
        imageFixture(id: 'b'),
        imageFixture(id: 'c'),
      ]);

      expect(
        result,
        isA<AiAttachmentUploadFailed>().having(
          (f) => f.failureKey,
          'failureKey',
          AiAttachmentUploadFailureKeys.failed,
        ),
      );
      verifyNever(
        () => repository.upload(
          uploadKey: 'b',
          asset: any(named: 'asset'),
        ),
      );
      verifyNever(
        () => repository.upload(
          uploadKey: 'c',
          asset: any(named: 'asset'),
        ),
      );
    });

    test('reports what landed, and deletes nothing', () async {
      // `DELETE /media/{id}` is provider-only, so compensation is impossible;
      // the orphans are the backend's to collect.
      var call = 0;
      when(
        () => repository.upload(
          uploadKey: any(named: 'uploadKey'),
          asset: any(named: 'asset'),
        ),
      ).thenAnswer(
        (_) => call++ == 0
            ? TaskEither.right(_media(id: 'upl_first'))
            : TaskEither.left(const ServerFailure(message: 'errors.server')),
      );

      final result = await uploader.upload([
        imageFixture(id: 'a'),
        imageFixture(id: 'b'),
      ]);

      expect(
        (result as AiAttachmentUploadFailed).uploaded.single.mediaId,
        'upl_first',
      );
      verifyNever(() => repository.deleteMedia(any()));
    });

    test('backend prose never reaches the failure key', () async {
      // A `Failure.message` can be raw server text; a bubble must never show
      // it. The seam collapses every failure to one localization key.
      when(
        () => repository.upload(
          uploadKey: any(named: 'uploadKey'),
          asset: any(named: 'asset'),
        ),
      ).thenReturn(
        TaskEither.left(
          const ServerFailure(message: 'property cityId should not exist'),
        ),
      );

      final result = await uploader.upload([imageFixture()]);

      expect(
        (result as AiAttachmentUploadFailed).failureKey,
        AiAttachmentUploadFailureKeys.failed,
      );
    });

    test('a throwing pipeline is a failure, never an exception', () async {
      when(
        () => repository.upload(
          uploadKey: any(named: 'uploadKey'),
          asset: any(named: 'asset'),
        ),
      ).thenThrow(StateError('boom'));

      await expectLater(
        uploader.upload([imageFixture()]),
        completion(isA<AiAttachmentUploadFailed>()),
      );
    });
  });

  group('the no-op uploader', () {
    test('succeeds for a turn with nothing attached', () async {
      const uploader = AiUnavailableAttachmentUploader();

      expect(await uploader.upload([]), const AiAttachmentsUploaded([]));
    });

    test('refuses attachments rather than dropping them', () async {
      const uploader = AiUnavailableAttachmentUploader();

      expect(
        await uploader.upload([imageFixture()]),
        isA<AiAttachmentUploadFailed>(),
      );
    });
  });
}
