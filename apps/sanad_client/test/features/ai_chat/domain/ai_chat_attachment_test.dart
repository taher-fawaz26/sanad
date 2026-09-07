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

    test('preserves audio duration and waveform', () {
      final moved = audioFixture(
        duration: const Duration(seconds: 42),
        waveform: const [0.2, 0.4],
      ).withStatus(AiAttachmentStatus.ready);

      final typed = moved;
      expect(typed.duration, const Duration(seconds: 42));
      expect(typed.waveform, const [0.2, 0.4]);
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
      expect(
        audioFixture(duration: const Duration(seconds: 1)),
        isNot(audioFixture(duration: const Duration(seconds: 2))),
      );
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
      // An audio-only or image-only turn is legitimate.
      final message = AiOutgoingMessage(attachments: [audioFixture()]);

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
        attachments: [imageFixture(), documentFixture(), audioFixture()],
      );

      expect(message.attachments, hasLength(3));
      expect(message.attachments.whereType<AiImageAttachment>(), hasLength(1));
      expect(
        message.attachments.whereType<AiDocumentAttachment>(),
        hasLength(1),
      );
      expect(message.attachments.whereType<AiAudioAttachment>(), hasLength(1));
    });
  });

  group('no bytes anywhere', () {
    test(
      'the waveform is capped so a long take costs no more than a short one',
      () {
        expect(AiAudioAttachment.maxWaveformSamples, 40);
      },
    );
  });

  group('a voice note remembers its own words', () {
    test('the transcript defaults to empty', () {
      // Empty is the normal outcome when the recogniser was unavailable or
      // heard nothing, so it must not be a required argument.
      expect(audioFixture().transcript, isEmpty);
    });

    test('it is part of the identity', () {
      // Not decoration: two takes of the same file that were heard
      // differently are different attachments, and a bubble that held the
      // stale one would send the wrong words.
      expect(
        audioFixture(transcript: 'hello'),
        isNot(audioFixture(transcript: 'goodbye')),
      );
      expect(
        audioFixture(transcript: 'hello'),
        audioFixture(transcript: 'hello'),
      );
    });

    test('copyWith preserves it', () {
      final take = audioFixture(transcript: 'book me a plumber');

      expect(
        take.copyWith(duration: Duration.zero).transcript,
        take.transcript,
      );
    });

    test('a status change preserves it', () {
      // The composer's only mutation. Losing the transcript on the way to
      // `ready` would mean every voice note shipped without its words.
      final take = audioFixture(transcript: 'book me a plumber');

      expect(
        take.withStatus(AiAttachmentStatus.ready).transcript,
        'book me a plumber',
      );
    });

    test('only audio carries one', () {
      // Images and documents have nothing to transcribe, and a permanently
      // empty field on them would be model rather than information.
      expect(imageFixture(), isNot(isA<AiAudioAttachment>()));
      expect(documentFixture(), isNot(isA<AiAudioAttachment>()));
    });
  });
}
