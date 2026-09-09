import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';

void main() {
  group('ClientRequestStatus', () {
    test('round-trips every backend value', () {
      const wire = [
        'DRAFT',
        'SUBMITTED',
        'SCHEDULED',
        'IN_PROGRESS',
        'AWAITING_CONFIRMATION',
        'DISPUTED',
        'COMPLETED',
        'CANCELLED',
        'EXPIRED',
      ];
      for (final raw in wire) {
        final parsed = ClientRequestStatus.fromApi(raw);
        expect(parsed, isNot(ClientRequestStatus.unknown), reason: raw);
        expect(parsed.apiValue, raw);
      }
    });

    test(
      'declares exactly the nine contract states plus the parse sentinel',
      () {
        // Guards against a client-invented status: the spec says "do not invent
        // extra statuses", and `unknown` is a parse sentinel, not a lifecycle
        // state (it has no apiValue).
        expect(ClientRequestStatus.values, hasLength(10));
        expect(
          ClientRequestStatus.values.where(
            (s) => s != ClientRequestStatus.unknown,
          ),
          hasLength(9),
        );
      },
    );

    test('falls back to unknown for an unrecognised or absent value', () {
      expect(
        ClientRequestStatus.fromApi('ON_HOLD'),
        ClientRequestStatus.unknown,
      );
      expect(ClientRequestStatus.fromApi(null), ClientRequestStatus.unknown);
      expect(ClientRequestStatus.fromApi(''), ClientRequestStatus.unknown);
    });

    test('unknown refuses to serialize', () {
      expect(() => ClientRequestStatus.unknown.apiValue, throwsStateError);
    });

    test('isClosed covers only the terminal states', () {
      expect(ClientRequestStatus.completed.isClosed, isTrue);
      expect(ClientRequestStatus.cancelled.isClosed, isTrue);
      expect(ClientRequestStatus.expired.isClosed, isTrue);
      expect(ClientRequestStatus.disputed.isClosed, isFalse);
      expect(ClientRequestStatus.awaitingConfirmation.isClosed, isFalse);
      expect(ClientRequestStatus.draft.isClosed, isFalse);
    });
  });

  group('RequestOfferStatus', () {
    test('round-trips every backend value', () {
      const wire = [
        'PENDING',
        'ACCEPTED',
        'REJECTED',
        'SUPERSEDED',
        'LOST',
        'WITHDRAWN',
        'VOIDED',
        'EXPIRED',
      ];
      for (final raw in wire) {
        expect(RequestOfferStatus.fromApi(raw).apiValue, raw);
      }
    });

    test('keeps LOST and REJECTED distinct', () {
      // Provider copy must distinguish "another provider won" from "the client
      // declined you" — collapsing them is the bug this pins.
      expect(
        RequestOfferStatus.fromApi('LOST'),
        isNot(RequestOfferStatus.fromApi('REJECTED')),
      );
    });

    test('falls back to unknown', () {
      expect(RequestOfferStatus.fromApi('MAYBE'), RequestOfferStatus.unknown);
    });
  });

  group('RequestOfferActorType', () {
    test('round-trips both actors', () {
      expect(RequestOfferActorType.fromApi('PROVIDER').apiValue, 'PROVIDER');
      expect(RequestOfferActorType.fromApi('CLIENT').apiValue, 'CLIENT');
    });

    test('falls back to unknown', () {
      expect(
        RequestOfferActorType.fromApi('ADMIN'),
        RequestOfferActorType.unknown,
      );
    });
  });

  group('RequestAttachment', () {
    test('round-trips a full payload', () {
      const json = {
        'id': 'att-1',
        'mediaId': 'media-1',
        'url': 'https://cdn.example.com/leak.jpg',
        'mimeType': 'image/jpeg',
      };
      final parsed = RequestAttachment.fromJson(json);
      expect(parsed.mediaId, 'media-1');
      expect(parsed.isImage, isTrue);
      expect(parsed.toJson(), json);
    });

    test('treats a PDF as a non-image', () {
      final parsed = RequestAttachment.fromJson(const {
        'id': 'a',
        'mediaId': 'm',
        'url': 'u',
        'mimeType': 'application/pdf',
      });
      expect(parsed.isImage, isFalse);
    });

    test('degrades a malformed entry instead of throwing', () {
      final parsed = RequestAttachment.fromJson(const {'id': 'a'});
      expect(parsed.mediaId, isEmpty);
    });
  });
}
