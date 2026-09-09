import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/client_requests_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_request_detail/client_request_detail_bloc.dart';
import 'package:testing/testing.dart';

import '../support/client_requests_fakes.dart';

void main() {
  late RecordingApiClient client;

  ClientRequestDetailBloc buildBloc() {
    final ClientRequestsRepository repository = ClientRequestsRepositoryImpl(
      ClientRequestsRemoteDataSourceImpl(client),
    );
    return ClientRequestDetailBloc(
      requestId: 'req-1',
      getRequest: GetClientRequestUseCase(repository),
      cancelRequest: CancelClientRequestUseCase(repository),
      confirmRequest: ConfirmClientRequestUseCase(repository),
      disputeRequest: DisputeClientRequestUseCase(repository),
      acceptOffer: AcceptOfferUseCase(repository),
      rejectOffer: RejectOfferUseCase(repository),
      counterOffer: CounterOfferUseCase(repository),
    );
  }

  setUp(() => client = RecordingApiClient());

  group('loading', () {
    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'reads the request with its threads and matched branches',
      setUp: () =>
          client.defaultResponse = TaskEither.right(clientRequestJson()),
      build: buildBloc,
      act: (bloc) => bloc.add(const ClientRequestDetailStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.loadStatus, RequestStatus.success);
        expect(bloc.state.request!.threads, hasLength(1));
        expect(bloc.state.request!.matchedBranches, hasLength(1));
      },
    );

    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'a 404 for another client request surfaces as a failure',
      setUp: () => client.defaultResponse = TaskEither.left(
        const ServerFailure(message: 'Not found', code: '404'),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const ClientRequestDetailStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.loadStatus, RequestStatus.failure);
        expect(bloc.state.request, isNull);
      },
    );
  });

  group('request actions', () {
    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'cancel sends the reason and adopts the returned status',
      setUp: () {
        client
          ..stub('requests/req-1', TaskEither.right(clientRequestJson()))
          ..stub(
            'requests/req-1/cancel',
            TaskEither.right(clientRequestJson(status: 'CANCELLED')),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ClientRequestCancelled('tenant fixed it'));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.mutationStatus, RequestStatus.success);
        expect(bloc.state.request!.status, ClientRequestStatus.cancelled);
        expect(client.lastCall.body, {'reason': 'tenant fixed it'});
      },
    );

    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'confirm adopts whatever status the server reports',
      // If the client never confirms the server auto-completes on a timer, so
      // the post-action status is read back rather than assumed.
      setUp: () {
        client
          ..stub(
            'requests/req-1',
            TaskEither.right(
              clientRequestJson(status: 'AWAITING_CONFIRMATION'),
            ),
          )
          ..stub(
            'requests/req-1/confirm',
            TaskEither.right(clientRequestJson(status: 'COMPLETED')),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ClientRequestConfirmed());
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) =>
          expect(bloc.state.request!.status, ClientRequestStatus.completed),
    );

    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'dispute sends the reason and moves to DISPUTED',
      setUp: () {
        client
          ..stub(
            'requests/req-1',
            TaskEither.right(
              clientRequestJson(status: 'AWAITING_CONFIRMATION'),
            ),
          )
          ..stub(
            'requests/req-1/dispute',
            TaskEither.right(clientRequestJson(status: 'DISPUTED')),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ClientRequestDisputed('the balcony was skipped'));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.request!.status, ClientRequestStatus.disputed);
        expect(client.lastCall.path, 'requests/req-1/dispute');
      },
    );
  });

  group('offer negotiation', () {
    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'accepting an offer books the job and loses the rivals',
      setUp: () {
        client
          ..stub(
            'requests/req-1',
            TaskEither.right(
              clientRequestJson(
                threads: [
                  offerThreadJson(),
                  offerThreadJson(
                    rootOfferId: 'offer-2',
                    providerId: 'prov-2',
                    offers: [offerJson(id: 'offer-2')],
                  ),
                ],
                offerCount: 2,
              ),
            ),
          )
          ..stub(
            'requests/req-1/offers/offer-1/accept',
            TaskEither.right(
              clientRequestJson(
                status: 'SCHEDULED',
                threads: [
                  offerThreadJson(
                    offers: [offerJson(status: 'ACCEPTED')],
                  ),
                  offerThreadJson(
                    rootOfferId: 'offer-2',
                    providerId: 'prov-2',
                    offers: [offerJson(id: 'offer-2', status: 'LOST')],
                  ),
                ],
              ),
            ),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ClientRequestOfferAccepted('offer-1'));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        final request = bloc.state.request!;
        expect(request.status, ClientRequestStatus.scheduled);
        expect(
          request.threads.first.offers.single.status,
          RequestOfferStatus.accepted,
        );
        // The rival was not personally judged — it lost, it was not rejected.
        expect(
          request.threads.last.offers.single.status,
          RequestOfferStatus.lost,
        );
      },
    );

    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'rejecting ends only that thread',
      setUp: () {
        client
          ..stub('requests/req-1', TaskEither.right(clientRequestJson()))
          ..stub(
            'requests/req-1/offers/offer-1/reject',
            TaskEither.right(
              clientRequestJson(
                threads: [
                  offerThreadJson(
                    offers: [offerJson(status: 'REJECTED')],
                  ),
                  offerThreadJson(
                    rootOfferId: 'offer-2',
                    providerId: 'prov-2',
                    offers: [offerJson(id: 'offer-2')],
                  ),
                ],
              ),
            ),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ClientRequestOfferRejected('offer-1'));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        final threads = bloc.state.request!.threads;
        expect(threads.first.offers.single.status, RequestOfferStatus.rejected);
        // The other provider is still in play.
        expect(threads.last.isAwaitingClient, isTrue);
        expect(bloc.state.request!.status, ClientRequestStatus.submitted);
      },
    );

    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'countering supersedes the provider offer and hands back the turn',
      setUp: () {
        client
          ..stub('requests/req-1', TaskEither.right(clientRequestJson()))
          ..stub(
            'requests/req-1/offers/offer-1/counter',
            TaskEither.right(
              clientRequestJson(
                threads: [
                  offerThreadJson(
                    offers: [
                      offerJson(status: 'SUPERSEDED'),
                      offerJson(
                        id: 'offer-1b',
                        actorType: 'CLIENT',
                        parentOfferId: 'offer-1',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          ClientRequestOfferCountered(
            offerId: 'offer-1',
            proposedAt: DateTime(2026, 9, 13, 9),
            note: 'mornings are easier',
          ),
        );
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        final thread = bloc.state.request!.threads.single;
        // SUPERSEDED, not REJECTED: the offer was answered, not refused.
        expect(thread.offers.first.status, RequestOfferStatus.superseded);
        expect(thread.isAwaitingProvider, isTrue);
        expect(thread.isAwaitingClient, isFalse);

        final body = client.lastCall.body as Map<String, dynamic>;
        expect(body['proposedAt'], endsWith('Z'));
        expect(body['note'], 'mornings are easier');
      },
    );

    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'an offer that belongs to another request surfaces the 404',
      setUp: () {
        client
          ..stub('requests/req-1', TaskEither.right(clientRequestJson()))
          ..stub(
            'requests/req-1/offers/other-offer/accept',
            TaskEither.left(
              const ServerFailure(message: 'Not found', code: '404'),
            ),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ClientRequestOfferAccepted('other-offer'));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.mutationStatus, RequestStatus.failure);
        expect(bloc.state.mutationFailure, isA<ServerFailure>());
        // The action did not happen, so the screen keeps showing what is true.
        expect(bloc.state.request!.status, ClientRequestStatus.submitted);
      },
    );
  });

  group('server state moving underneath the view', () {
    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'a 409 triggers a re-read rather than a guessed local transition',
      // A rival accepted first, or a timer fired. The server is the authority,
      // so the only correct response is to ask it again.
      setUp: () {
        client
          ..stub('requests/req-1', TaskEither.right(clientRequestJson()))
          ..stub(
            'requests/req-1/offers/offer-1/accept',
            TaskEither.left(
              const ConflictFailure(message: 'Already booked', code: '409'),
            ),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ClientRequestOfferAccepted('offer-1'));
      },
      wait: const Duration(milliseconds: 120),
      verify: (bloc) {
        expect(bloc.state.mutationFailure, isA<ConflictFailure>());
        final reads = client.calls
            .where((c) => c.path == 'requests/req-1')
            .length;
        expect(reads, 2, reason: 'the conflict forces a refresh');
      },
    );

    blocTest<ClientRequestDetailBloc, ClientRequestDetailState>(
      'a refresh picks up a timer-driven transition',
      setUp: () {
        var call = 0;
        client
          ..defaultResponse = TaskEither.right(clientRequestJson())
          ..stub(
            'requests/req-1',
            TaskEither(() async {
              call++;
              return right(
                clientRequestJson(status: call == 1 ? 'SUBMITTED' : 'EXPIRED'),
              );
            }),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ClientRequestDetailStarted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const ClientRequestDetailRefreshed());
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) =>
          expect(bloc.state.request!.status, ClientRequestStatus.expired),
    );
  });
}
