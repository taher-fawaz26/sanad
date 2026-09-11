import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';

import '../support/attachment_fixtures.dart';

void main() {
  group('withStatus', () {
    test('preserves the subtype', () {
      final moved = imageFixture().withStatus(AiAttachmentStatus.ready);

      expect(moved, isA<AiImageAttachment>());
      expect(moved.status, AiAttachmentStatus.ready);
      expect(moved.localPath, '/tmp/photo.jpg');
    });

    test('preserves a document extension', () {
      final moved = documentFixture(
        extension: 'xlsx',
      ).withStatus(AiAttachmentStatus.ready);

      expect(moved.extension, 'xlsx');
    });

    test('carries a failure key onto a failed attachment', () {
      final failed = imageFixture().withStatus(
        AiAttachmentStatus.failed,
        failureKey: 'ai_chat.attachment_too_large',
      );

      expect(failed.status, AiAttachmentStatus.failed);
      expect(failed.failureKey, 'ai_chat.attachment_too_large');
    });

    test('never mutates the receiver', () {
      final original = imageFixture()..withStatus(AiAttachmentStatus.ready);

      expect(original.status, AiAttachmentStatus.picked);
    });
  });

  group('equality', () {
    test('two attachments differing only in status are not equal', () {
      // If this ever collapses, a status change would not rebuild the tile.
      expect(
        imageFixture(),
        isNot(imageFixture(status: AiAttachmentStatus.ready)),
      );
    });

    test('two attachments differing only in id are not equal', () {
      expect(imageFixture(id: 'a'), isNot(imageFixture(id: 'b')));
    });

    test('two identical attachments are equal', () {
      expect(imageFixture(), imageFixture());
    });

    test('subtype-only metadata participates in equality', () {
      expect(imageFixture(), isNot(imageFixture(id: 'other')));
      expect(documentFixture(), isNot(documentFixture(extension: 'txt')));
    });
  });

  group('status helpers', () {
    test('only ready is ready', () {
      for (final status in AiAttachmentStatus.values) {
        expect(
          status.isReady,
          status == AiAttachmentStatus.ready,
          reason: status.name,
        );
      }
    });

    test('busy covers exactly the in-flight states', () {
      expect(AiAttachmentStatus.picked.isBusy, isTrue);
      expect(AiAttachmentStatus.validating.isBusy, isTrue);
      expect(AiAttachmentStatus.processing.isBusy, isTrue);
      expect(AiAttachmentStatus.ready.isBusy, isFalse);
      expect(AiAttachmentStatus.failed.isBusy, isFalse);
      expect(AiAttachmentStatus.sent.isBusy, isFalse);
    });

    test('isReady on the entity follows the status', () {
      expect(imageFixture(status: AiAttachmentStatus.ready).isReady, isTrue);
      expect(imageFixture(status: AiAttachmentStatus.failed).isReady, isFalse);
    });
  });

  group('AiOutgoingMessage', () {
    test('text only is not empty', () {
      expect(const AiOutgoingMessage(text: 'hi').isEmpty, isFalse);
    });

    test('attachments with no text is not empty', () {
      // An image-only turn is legitimate: a photo needs no caption.
      final message = AiOutgoingMessage(attachments: [imageFixture()]);

      expect(message.isEmpty, isFalse);
      expect(message.hasAttachments, isTrue);
    });

    test('neither text nor attachments is empty', () {
      expect(const AiOutgoingMessage().isEmpty, isTrue);
      expect(const AiOutgoingMessage().hasAttachments, isFalse);
    });

    test('carries every attachment kind in one turn', () {
      final message = AiOutgoingMessage(
        text: 'look at these',
        attachments: [imageFixture(), documentFixture()],
      );

      expect(message.attachments, hasLength(2));
      expect(message.attachments.whereType<AiImageAttachment>(), hasLength(1));
      expect(
        message.attachments.whereType<AiDocumentAttachment>(),
        hasLength(1),
      );
    });
  });

  group('the hierarchy has exactly two variants', () {
    // AI Chat retired recorded audio, so `AiAudioAttachment` was removed from
    // this sealed hierarchy rather than left dormant. These assertions are
    // what makes reintroducing it a visible decision instead of a quiet one.
    test('an attachment is an image or a document, and nothing else', () {
      for (final attachment in <AiChatAttachment>[
        imageFixture(),
        documentFixture(),
      ]) {
        expect(
          attachment,
          anyOf(isA<AiImageAttachment>(), isA<AiDocumentAttachment>()),
        );
      }
    });

    test('no variant carries a transcript, a duration or a waveform', () {
      // Client-derived audio metadata is what the retired voice note carried
      // onto the wire. Nothing in the hierarchy holds it any more, and the
      // exhaustive switch below is the proof: adding a third variant makes
      // this a compile error rather than a silent gap.
      for (final attachment in <AiChatAttachment>[
        imageFixture(),
        documentFixture(),
      ]) {
        final props = switch (attachment) {
          AiImageAttachment() => attachment.props,
          AiDocumentAttachment() => attachment.props,
        };
        expect(props.whereType<Duration>(), isEmpty);
        expect(props.whereType<List<double>>(), isEmpty);
      }
    });
  });
}
