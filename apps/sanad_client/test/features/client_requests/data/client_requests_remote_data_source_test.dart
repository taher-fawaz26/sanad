import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/client_requests_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';

import '../support/client_requests_fakes.dart';

void main() {
  late RecordingApiClient client;
  late ClientRequestsRepository repository;

  setUp(() {
    client = RecordingApiClient();
    repository = ClientRequestsRepositoryImpl(
      ClientRequestsRemoteDataSourceImpl(client),
    );
  });

  /// Answers every path with a well-formed request payload.
  void stubOk([Map<String, dynamic>? json]) {
    client.defaultResponse = TaskEither.right(json ?? clientRequestJson());
  }

  group('paths and verbs', () {
    test('list is a GET on `requests`', () async {
      client.defaultResponse = TaskEither.right(
        pageJson([clientRequestJson()]),
      );

      await repository.list(const ClientRequestsQuery()).run();

      expect(client.lastCall.path, 'requests');
      expect(client.lastCall.method, RequestMethod.get);
    });

    test(
      'detail, create, update and submit hit the documented paths',
      () async {
        stubOk();

        await repository.getById('req-1').run();
        expect(client.lastCall.path, 'requests/req-1');
        expect(client.lastCall.method, RequestMethod.get);

        await repository.createDraft(const SaveDraftParams()).run();
        expect(client.lastCall.path, 'requests');
        expect(client.lastCall.method, RequestMethod.post);

        await repository.update('req-1', const SaveDraftParams()).run();
        expect(client.lastCall.path, 'requests/req-1');
        expect(client.lastCall.method, RequestMethod.patch);

        await repository.submit('req-1').run();
        expect(client.lastCall.path, 'requests/req-1/submit');
        expect(client.lastCall.method, RequestMethod.post);
      },
    );

    test('cancel, confirm and dispute hit the documented paths', () async {
      stubOk();

      await repository.cancel('req-1', 'changed my mind').run();
      expect(client.lastCall.path, 'requests/req-1/cancel');
      expect(client.lastCall.body, {'reason': 'changed my mind'});

      await repository.confirm('req-1').run();
      expect(client.lastCall.path, 'requests/req-1/confirm');
      expect(client.lastCall.body, isNull);

      await repository.dispute('req-1', 'balcony was skipped').run();
      expect(client.lastCall.path, 'requests/req-1/dispute');
      expect(client.lastCall.body, {'reason': 'balcony was skipped'});
    });

    test('every offer action is nested under its request', () async {
      // The backend enforces that `offerId` belongs to the `:id` in the URL and
      // answers `404` on a mismatch. Sending a bare `/offers/:id` path would be
      // a different endpoint entirely.
      stubOk();

      await repository
          .acceptOffer(requestId: 'req-1', offerId: 'offer-9')
          .run();
      expect(client.lastCall.path, 'requests/req-1/offers/offer-9/accept');

      await repository
          .rejectOffer(requestId: 'req-1', offerId: 'offer-9')
          .run();
      expect(client.lastCall.path, 'requests/req-1/offers/offer-9/reject');

      await repository
          .counterOffer(
            requestId: 'req-1',
            offerId: 'offer-9',
            body: CounterOfferRequest(proposedAt: DateTime(2026, 9, 13, 9)),
          )
          .run();
      expect(client.lastCall.path, 'requests/req-1/offers/offer-9/counter');
      expect(client.lastCall.method, RequestMethod.post);
    });

    test('a counter body carries an offset-bearing proposedAt', () async {
      stubOk();

      await repository
          .counterOffer(
            requestId: 'req-1',
            offerId: 'offer-9',
            body: CounterOfferRequest(
              proposedAt: DateTime(2026, 9, 13, 9),
              note: 'Mornings are easier.',
            ),
          )
          .run();

      final body = client.lastCall.body as Map<String, dynamic>;
      expect(body['proposedAt'], endsWith('Z'));
      expect(body['note'], 'Mornings are easier.');
    });
  });

  group('query parameters', () {
    test('sends the status filter server-side', () async {
      client.defaultResponse = TaskEither.right(pageJson([]));

      await repository
          .list(const ClientRequestsQuery(status: ClientRequestStatus.draft))
          .run();

      expect(client.lastCall.query!['status'], 'DRAFT');
    });

    test('omits the filter when none is set', () async {
      client.defaultResponse = TaskEither.right(pageJson([]));

      await repository.list(const ClientRequestsQuery()).run();

      expect(client.lastCall.query!.containsKey('status'), isFalse);
    });

    test('never sends the parse sentinel as a status', () async {
      client.defaultResponse = TaskEither.right(pageJson([]));

      await repository
          .list(const ClientRequestsQuery(status: ClientRequestStatus.unknown))
          .run();

      expect(client.lastCall.query!.containsKey('status'), isFalse);
    });

    test('clamps limit to the backend cap of 100', () async {
      // 101 or more answers 400, so an over-large caller degrades instead.
      client.defaultResponse = TaskEither.right(pageJson([]));

      await repository.list(const ClientRequestsQuery(limit: 500)).run();

      expect(client.lastCall.query!['limit'], 100);
    });
  });

  group('failures', () {
    test('a 404 on a mismatched offer id reaches the caller', () async {
      client.defaultResponse = TaskEither.left(
        const ServerFailure(message: 'Not found', code: '404'),
      );

      final result = await repository
          .acceptOffer(requestId: 'req-1', offerId: 'other-offer')
          .run();

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ServerFailure>().having((f) => f.code, 'code', '404'),
      );
    });

    test('a structured 409 keeps its code and alternatives', () async {
      client.defaultResponse = TaskEither.left(
        const ConflictFailure(
          message: 'Closed then',
          code: '409',
          metadata: {
            'code': 'OUTSIDE_HOURS',
            'alternatives': [
              {'start': '2026-09-12T09:00:00+04:00'},
            ],
          },
        ),
      );

      final result = await repository.submit('req-1').run();
      final conflict = RequestSubmissionConflict.tryParse(
        result.getLeft().toNullable()!,
      );

      expect(conflict!.code, RequestSubmissionConflictCode.outsideHours);
      expect(conflict.alternatives, hasLength(1));
    });
  });
}
