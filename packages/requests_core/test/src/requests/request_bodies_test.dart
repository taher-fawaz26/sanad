import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';

void main() {
  group('CounterOfferRequest', () {
    test('serializes proposedAt with an explicit offset', () {
      final body = CounterOfferRequest(
        proposedAt: DateTime(2026, 9, 13, 9),
      ).toJson();
      expect(body['proposedAt'], endsWith('Z'));
      expect(body.containsKey('note'), isFalse);
    });

    test('includes a trimmed note when one is given', () {
      final body = CounterOfferRequest(
        proposedAt: DateTime(2026, 9, 13, 9),
        note: '  Mornings are easier.  ',
      ).toJson();
      expect(body['note'], 'Mornings are easier.');
    });

    test('omits a blank note rather than sending an empty string', () {
      final body = CounterOfferRequest(
        proposedAt: DateTime(2026, 9, 13, 9),
        note: '   ',
      ).toJson();
      expect(body.containsKey('note'), isFalse);
    });
  });

  group('ReasonRequest', () {
    test('trims the reason', () {
      expect(
        const ReasonRequest('  Tenant fixed it.  ').toJson(),
        {'reason': 'Tenant fixed it.'},
      );
    });
  });

  group('RequestValidators.reason', () {
    test('rejects fewer than three characters', () {
      expect(
        RequestValidators.reason('ab'),
        'requests.validation.reason_too_short',
      );
      expect(
        RequestValidators.reason(null),
        'requests.validation.reason_too_short',
      );
      expect(
        RequestValidators.reason('   a  '),
        'requests.validation.reason_too_short',
      );
    });

    test('accepts the boundary lengths', () {
      expect(RequestValidators.reason('abc'), isNull);
      expect(RequestValidators.reason('x' * 1000), isNull);
    });

    test('rejects more than 1000 characters', () {
      expect(
        RequestValidators.reason('x' * 1001),
        'requests.validation.reason_too_long',
      );
    });
  });

  group('RequestValidators.futureInstant', () {
    final now = DateTime(2026, 9, 12, 10);

    test('rejects a past or equal instant', () {
      expect(
        RequestValidators.futureInstant(DateTime(2026, 9, 12, 9), now: now),
        'requests.validation.time_must_be_future',
      );
      expect(
        RequestValidators.futureInstant(now, now: now),
        'requests.validation.time_must_be_future',
      );
    });

    test('accepts a future instant', () {
      expect(
        RequestValidators.futureInstant(DateTime(2026, 9, 12, 11), now: now),
        isNull,
      );
    });

    test('requires a value', () {
      expect(
        RequestValidators.futureInstant(null, now: now),
        'requests.validation.time_required',
      );
    });
  });

  group('RequestValidators.mediaIds', () {
    test('allows up to five', () {
      expect(RequestValidators.mediaIds(List.filled(5, 'id')), isNull);
    });

    test('rejects six', () {
      expect(
        RequestValidators.mediaIds(List.filled(6, 'id')),
        'requests.validation.too_many_attachments',
      );
    });
  });

  group('RequestValidators.offerNote', () {
    test('accepts an absent note', () {
      expect(RequestValidators.offerNote(null), isNull);
    });

    test('rejects more than 1000 characters', () {
      expect(
        RequestValidators.offerNote('x' * 1001),
        'requests.validation.note_too_long',
      );
    });
  });
}
