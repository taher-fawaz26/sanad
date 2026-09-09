import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/requests.dart';
import 'package:sanad_provider/src/features/requests/src/data/datasources/provider_requests_remote_data_source.dart';
import 'package:sanad_provider/src/features/requests/src/data/repositories/provider_requests_repository_impl.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';

import '../support/provider_requests_fakes.dart';

void main() {
  late RecordingApiClient client;
  late ProviderRequestsRepository repository;

  setUp(() {
    client = RecordingApiClient();
    repository = ProviderRequestsRepositoryImpl(
      ProviderRequestsRemoteDataSourceImpl(client),
    );
  });

  /// Answers the request read, which every mutation performs afterwards.
  void stubReload([Map<String, dynamic>? json]) {
    client.stub(
      'provider/requests/req-1',
      TaskEither.right(json ?? providerRequestJson()),
    );
  }

  group('reads', () {
    test('the feed, counts and stats hit the documented paths', () async {
      client
        ..stub(
          'provider/requests',
          TaskEither.right(pageJson([providerRequestJson()])),
        )
        ..stub('provider/requests/counts', TaskEither.right(countsJson()))
        ..stub('provider/requests/stats', TaskEither.right(statsJson()));

      await repository.list(const ProviderRequestsQuery()).run();
      expect(client.lastCall.path, 'provider/requests');
      expect(client.lastCall.method, RequestMethod.get);

      await repository.counts().run();
      expect(client.lastCall.path, 'provider/requests/counts');

      await repository.stats().run();
      expect(client.lastCall.path, 'provider/requests/stats');
    });

    test('sends the tab server-side rather than filtering locally', () async {
      // A paginated feed cannot be re-bucketed after the fact without also
      // invalidating the per-tab counts.
      client.stub('provider/requests', TaskEither.right(pageJson([])));

      await repository
          .list(
            const ProviderRequestsQuery(tab: ProviderRequestTab.yourTurn),
          )
          .run();

      expect(client.lastCall.query!['tab'], 'YOUR_TURN');
    });

    test('never sends the parse sentinel as a tab', () async {
      client.stub('provider/requests', TaskEither.right(pageJson([])));

      await repository
          .list(const ProviderRequestsQuery(tab: ProviderRequestTab.unknown))
          .run();

      expect(client.lastCall.query!.containsKey('tab'), isFalse);
    });

    test('sends search and branchId when set', () async {
      client.stub('provider/requests', TaskEither.right(pageJson([])));

      await repository
          .list(
            const ProviderRequestsQuery(
              search: '  Deep cleaning  ',
              branchId: 'branch-1',
            ),
          )
          .run();

      expect(client.lastCall.query!['search'], 'Deep cleaning');
      expect(client.lastCall.query!['branchId'], 'branch-1');
    });

    test('clamps limit to the backend cap of 100', () async {
      client.stub('provider/requests', TaskEither.right(pageJson([])));

      await repository.list(const ProviderRequestsQuery(limit: 250)).run();

      expect(client.lastCall.query!['limit'], 100);
    });
  });

  group('offer actions', () {
    test('are addressed by offer id, then re-read the request', () async {
      // The mutation endpoints do not document a response body, and accepting
      // a counter changes the contact gate — so the resource is read back
      // rather than inferred from whatever the action returned.
      stubReload();
      client
        ..stub('provider/offers/offer-1/withdraw', TaskEither.right(null))
        ..stub('provider/offers/offer-1/accept', TaskEither.right(null))
        ..stub('provider/offers/offer-1/decline', TaskEither.right(null))
        ..stub('provider/offers/offer-1/counter', TaskEither.right(null));

      await repository
          .withdrawOffer(requestId: 'req-1', offerId: 'offer-1')
          .run();
      expect(
        client.calls.map((c) => c.path).toList(),
        containsAllInOrder([
          'provider/offers/offer-1/withdraw',
          'provider/requests/req-1',
        ]),
      );

      await repository
          .acceptCounter(requestId: 'req-1', offerId: 'offer-1')
          .run();
      expect(client.calls[2].path, 'provider/offers/offer-1/accept');

      await repository
          .declineCounter(requestId: 'req-1', offerId: 'offer-1')
          .run();
      expect(client.calls[4].path, 'provider/offers/offer-1/decline');
    });

    test('a counter body carries an offset-bearing proposedAt', () async {
      stubReload();
      client.stub('provider/offers/offer-1/counter', TaskEither.right(null));

      await repository
          .counterOffer(
            requestId: 'req-1',
            offerId: 'offer-1',
            body: CounterOfferRequest(
              proposedAt: DateTime(2026, 9, 13, 9),
              note: 'Mornings work better.',
            ),
          )
          .run();

      final counter = client.calls.firstWhere(
        (c) => c.path == 'provider/offers/offer-1/counter',
      );
      final body = counter.body as Map<String, dynamic>;
      expect(body['proposedAt'], endsWith('Z'));
      expect(body['note'], 'Mornings work better.');
    });

    test('creating an offer is nested under the request', () async {
      stubReload();
      client.stub('provider/requests/req-1/offers', TaskEither.right(null));

      await repository
          .createOffer(
            CreateOfferParams(
              requestId: 'req-1',
              branchId: 'branch-1',
              proposedAt: DateTime(2026, 9, 12, 11),
              note: '  We can bring the parts.  ',
            ),
          )
          .run();

      final create = client.calls.first;
      expect(create.path, 'provider/requests/req-1/offers');
      final body = create.body as Map<String, dynamic>;
      expect(body['branchId'], 'branch-1');
      expect(body['proposedAt'], endsWith('Z'));
      expect(body['note'], 'We can bring the parts.');
    });

    test('an offer with no note omits the key', () async {
      stubReload();
      client.stub('provider/requests/req-1/offers', TaskEither.right(null));

      await repository
          .createOffer(
            CreateOfferParams(
              requestId: 'req-1',
              branchId: 'branch-1',
              proposedAt: DateTime(2026, 9, 12, 11),
              note: '   ',
            ),
          )
          .run();

      expect(
        (client.calls.first.body as Map<String, dynamic>).containsKey('note'),
        isFalse,
      );
    });

    test(
      'an exhausted re-bid budget surfaces the 409 and skips the re-read',
      () async {
        // The caller must see the action's own failure, not a misleading read
        // error from a follow-up that should never have run.
        stubReload();
        client.stub(
          'provider/requests/req-1/offers',
          TaskEither.left(
            const ConflictFailure(message: 'No re-bids left', code: '409'),
          ),
        );

        final result = await repository
            .createOffer(
              CreateOfferParams(
                requestId: 'req-1',
                branchId: 'branch-1',
                proposedAt: DateTime(2026, 9, 12, 11),
              ),
            )
            .run();

        expect(result.getLeft().toNullable(), isA<ConflictFailure>());
        expect(
          client.calls.where((c) => c.path == 'provider/requests/req-1'),
          isEmpty,
        );
      },
    );
  });

  group('job actions', () {
    test('complete and cancel are nested under the request', () async {
      stubReload();
      client
        ..stub('provider/requests/req-1/complete', TaskEither.right(null))
        ..stub('provider/requests/req-1/cancel', TaskEither.right(null));

      await repository.complete('req-1').run();
      expect(client.calls.first.path, 'provider/requests/req-1/complete');

      await repository
          .cancel(requestId: 'req-1', reason: '  Van broke down.  ')
          .run();
      final cancel = client.calls.firstWhere(
        (c) => c.path == 'provider/requests/req-1/cancel',
      );
      expect(cancel.body, {'reason': 'Van broke down.'});
    });

    test('completion adopts the status the server reports', () async {
      // AWAITING_CONFIRMATION, then COMPLETED on a timer if the client never
      // confirms — neither is predicted locally.
      stubReload(
        providerRequestJson(status: 'AWAITING_CONFIRMATION', tab: 'TO_CONFIRM'),
      );
      client.stub('provider/requests/req-1/complete', TaskEither.right(null));

      final result = await repository.complete('req-1').run();

      expect(
        result.toNullable()!.status,
        ClientRequestStatus.awaitingConfirmation,
      );
    });
  });
}
