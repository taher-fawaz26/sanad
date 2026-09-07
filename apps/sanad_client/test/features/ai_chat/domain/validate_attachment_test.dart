import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/validate_attachment.dart';

import '../support/attachment_fixtures.dart';

void main() {
  const validate = ValidateAttachment();
  const rules = AiAttachmentRules();

  group('size', () {
    // The whole point of routing through FileSizePolicy rather than a local
    // constant: if the repo-wide ceiling moves, this feature moves with it.
    test('the ceiling is the repo-wide FileSizePolicy limit', () {
      expect(rules.maxSizeBytes, FileSizePolicy.maxBytes);
      expect(rules.maxSizeBytes, 5 * 1024 * 1024);
    });

    test('a file exactly at the ceiling is accepted', () {
      final result = validate(
        imageFixture(sizeBytes: FileSizePolicy.maxBytes),
        currentCount: 0,
      );

      expect(result.status, AiAttachmentStatus.ready);
      expect(result.failureKey, isNull);
    });

    test('one byte over the ceiling is rejected', () {
      final result = validate(
        imageFixture(sizeBytes: FileSizePolicy.maxBytes + 1),
        currentCount: 0,
      );

      expect(result.status, AiAttachmentStatus.failed);
      expect(result.failureKey, AiAttachmentFailureKeys.tooLarge);
    });

    test('an empty file is rejected as unreadable, not as too large', () {
      final result = validate(imageFixture(sizeBytes: 0), currentCount: 0);

      expect(result.failureKey, AiAttachmentFailureKeys.unreadable);
    });

    test('a negative size is rejected as unreadable', () {
      final result = validate(imageFixture(sizeBytes: -1), currentCount: 0);

      expect(result.failureKey, AiAttachmentFailureKeys.unreadable);
    });
  });

  group('count', () {
    test('accepts up to the limit', () {
      final result = validate(
        imageFixture(),
        currentCount: rules.maxAttachments - 1,
      );

      expect(result.status, AiAttachmentStatus.ready);
    });

    test('rejects once the limit is reached', () {
      final result = validate(
        imageFixture(),
        currentCount: rules.maxAttachments,
      );

      expect(result.status, AiAttachmentStatus.failed);
      expect(result.failureKey, AiAttachmentFailureKeys.tooMany);
    });

    test('the count rule outranks the size rule', () {
      // Both broken at once: the user is told the actionable thing (remove
      // something) rather than the incidental one.
      final result = validate(
        imageFixture(sizeBytes: FileSizePolicy.maxBytes + 1),
        currentCount: rules.maxAttachments,
      );

      expect(result.failureKey, AiAttachmentFailureKeys.tooMany);
    });
  });

  group('image type', () {
    test('accepts an image mime type', () {
      for (final mime in ['image/jpeg', 'image/png', 'image/heic']) {
        expect(
          validate(imageFixture(mimeType: mime), currentCount: 0).status,
          AiAttachmentStatus.ready,
          reason: mime,
        );
      }
    });

    test('rejects a non-image mime type', () {
      final result = validate(
        imageFixture(mimeType: 'application/octet-stream'),
        currentCount: 0,
      );

      expect(result.failureKey, AiAttachmentFailureKeys.unsupportedType);
    });
  });

  group('document type', () {
    test('accepts every documented extension', () {
      for (final ext in rules.documentExtensions) {
        expect(
          validate(
            documentFixture(extension: ext, fileName: 'file.$ext'),
            currentCount: 0,
          ).status,
          AiAttachmentStatus.ready,
          reason: ext,
        );
      }
    });

    test('accepts the documented set exactly', () {
      expect(rules.documentExtensions, {
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
      });
    });

    test('is case insensitive', () {
      final result = validate(
        documentFixture(extension: 'PDF'),
        currentCount: 0,
      );

      expect(result.status, AiAttachmentStatus.ready);
    });

    test('rejects an undocumented extension', () {
      final result = validate(
        documentFixture(extension: 'exe', fileName: 'thing.exe'),
        currentCount: 0,
      );

      expect(result.failureKey, AiAttachmentFailureKeys.unsupportedType);
    });
  });

  group('audio', () {
    test('is accepted without an extension check', () {
      // Audio is produced by the recorder, not chosen by the user, so there is
      // no untrusted extension to police.
      final result = validate(audioFixture(), currentCount: 0);

      expect(result.status, AiAttachmentStatus.ready);
    });

    test('is still subject to the size ceiling', () {
      final result = validate(
        audioFixture(sizeBytes: FileSizePolicy.maxBytes + 1),
        currentCount: 0,
      );

      expect(result.failureKey, AiAttachmentFailureKeys.tooLarge);
    });

    test('the recording cap keeps a take inside the size ceiling', () {
      // AAC ~32 kbps mono is ~4 KB/s. The cap must leave real headroom
      // against the 5 MiB ceiling, or a long take would be recorded and then
      // rejected — the worst possible moment to tell someone.
      const bytesPerSecond = 4 * 1024;
      final worstCase = rules.maxRecordingDuration.inSeconds * bytesPerSecond;

      expect(worstCase, lessThan(FileSizePolicy.maxBytes));
    });
  });

  group('purity', () {
    test('validation never mutates its input', () {
      final original = imageFixture();
      final result = validate(original, currentCount: 0);

      expect(original.status, AiAttachmentStatus.picked);
      expect(result.status, AiAttachmentStatus.ready);
      expect(identical(original, result), isFalse);
    });

    test('every failure key is a dotted lower-snake i18n key', () {
      // The page resolves a failure by this shape; prose would be shown raw.
      final pattern = RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+)+$');
      for (final key in [
        AiAttachmentFailureKeys.tooLarge,
        AiAttachmentFailureKeys.unsupportedType,
        AiAttachmentFailureKeys.tooMany,
        AiAttachmentFailureKeys.unreadable,
      ]) {
        expect(pattern.hasMatch(key), isTrue, reason: key);
      }
    });
  });
}
