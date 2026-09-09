import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';

ConflictFailure _conflict(Map<String, dynamic> body) => ConflictFailure(
  message: body['message']?.toString() ?? '',
  code: '409',
  metadata: body,
);

void main() {
  group('RequestSubmissionConflict.tryParse', () {
    test('returns null for anything that is not a 409', () {
      expect(
        RequestSubmissionConflict.tryParse(
          const ServerFailure(message: 'boom', code: '500'),
        ),
        isNull,
      );
      expect(
        RequestSubmissionConflict.tryParse(
          const ValidationFailure(message: 'bad', code: '400'),
        ),
        isNull,
      );
    });

    test('reads NO_PROVIDERS_FOR_SERVICE with an empty alternatives list', () {
      final parsed = RequestSubmissionConflict.tryParse(
        _conflict({
          'statusCode': 409,
          'code': 'NO_PROVIDERS_FOR_SERVICE',
          'message': 'No provider offers this service',
          'alternatives': <dynamic>[],
        }),
      );
      expect(parsed!.code, RequestSubmissionConflictCode.noProvidersForService);
      expect(parsed.hasAlternatives, isFalse);
      expect(parsed.message, 'No provider offers this service');
    });

    test('reads NO_COVERAGE', () {
      final parsed = RequestSubmissionConflict.tryParse(
        _conflict({
          'code': 'NO_COVERAGE',
          'message': 'Nobody serves that address',
        }),
      );
      expect(parsed!.code, RequestSubmissionConflictCode.noCoverage);
      expect(parsed.alternatives, isEmpty);
    });

    test('reads OUTSIDE_HOURS and its retry windows', () {
      final parsed = RequestSubmissionConflict.tryParse(
        _conflict({
          'code': 'OUTSIDE_HOURS',
          'message': 'Closed then',
          'alternatives': [
            {
              'start': '2026-09-12T09:00:00+04:00',
              'end': '2026-09-12T12:00:00+04:00',
            },
            {'start': '2026-09-13T09:00:00+04:00'},
          ],
        }),
      );
      expect(parsed!.code, RequestSubmissionConflictCode.outsideHours);
      expect(parsed.alternatives, hasLength(2));
      expect(
        parsed.alternatives.first.start.toUtc(),
        DateTime.utc(2026, 9, 12, 5),
      );
      expect(
        parsed.alternatives.first.end!.toUtc(),
        DateTime.utc(2026, 9, 12, 8),
      );
      expect(parsed.alternatives.last.end, isNull);
    });

    test('accepts the alternative key spellings the spec leaves open', () {
      // The OpenAPI spec documents neither the 409 body nor this item's shape,
      // so the parser accepts the plausible spellings rather than betting on
      // one. Tighten this once a live 409 confirms the real keys.
      final parsed = RequestSubmissionConflict.tryParse(
        _conflict({
          'code': 'OUTSIDE_HOURS',
          'alternatives': [
            {'from': '2026-09-12T09:00:00Z', 'to': '2026-09-12T12:00:00Z'},
            {'startsAt': '2026-09-13T09:00:00Z'},
            '2026-09-14T09:00:00Z',
          ],
        }),
      );
      expect(parsed!.alternatives, hasLength(3));
    });

    test('drops unreadable alternatives instead of rendering broken chips', () {
      final parsed = RequestSubmissionConflict.tryParse(
        _conflict({
          'code': 'OUTSIDE_HOURS',
          'alternatives': [
            {'start': 'not-a-date'},
            {'unrelated': 1},
            null,
            {'start': '2026-09-12T09:00:00Z'},
          ],
        }),
      );
      expect(parsed!.alternatives, hasLength(1));
    });

    test('survives alternatives being absent or the wrong type', () {
      expect(
        RequestSubmissionConflict.tryParse(
          _conflict({'code': 'OUTSIDE_HOURS'}),
        )!.alternatives,
        isEmpty,
      );
      expect(
        RequestSubmissionConflict.tryParse(
          _conflict({'code': 'OUTSIDE_HOURS', 'alternatives': 'soon'}),
        )!.alternatives,
        isEmpty,
      );
    });

    test('still produces a value for an unrecognised 409 code', () {
      // e.g. "already submitted" — the caller gets one branch for "the server
      // refused the transition" and falls back to the server prose.
      final parsed = RequestSubmissionConflict.tryParse(
        _conflict({'message': 'Already submitted'}),
      );
      expect(parsed!.code, RequestSubmissionConflictCode.unknown);
      expect(parsed.message, 'Already submitted');
    });

    test('reads the errorCode alias and is case-insensitive', () {
      expect(
        RequestSubmissionConflict.tryParse(
          _conflict({'errorCode': 'no_coverage'}),
        )!.code,
        RequestSubmissionConflictCode.noCoverage,
      );
    });

    test('does not mistake a NestJS reason phrase for a business code', () {
      // A NestJS 409 body carries `error: "Conflict"`. Reading that as a code
      // would produce a bogus CONFLICT value, so `error` is not an alias.
      expect(
        RequestSubmissionConflict.tryParse(
          _conflict({'error': 'Conflict', 'message': 'Already booked'}),
        )!.code,
        RequestSubmissionConflictCode.unknown,
      );
    });
  });
}
