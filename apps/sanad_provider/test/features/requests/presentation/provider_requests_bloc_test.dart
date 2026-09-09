import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/requests.dart';
import 'package:sanad_provider/src/features/requests/src/data/datasources/provider_requests_remote_data_source.dart';
import 'package:sanad_provider/src/features/requests/src/data/repositories/provider_requests_repository_impl.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';
import 'package:sanad_provider/src/features/requests/src/domain/usecases/provider_request_usecases.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/bloc/detail/provider_request_detail_bloc.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/bloc/workspace/provider_requests_workspace_bloc.dart';
import 'package:testing/testing.dart';

import '../support/provider_requests_fakes.dart';

void main() {
  late RecordingApiClient client;

  ProviderRequestsRepository buildRepository() =>
      ProviderRequestsRepositoryImpl(
        ProviderRequestsRemoteDataSourceImpl(client),
      );

  ProviderRequestsWorkspaceBloc buildWorkspace() {
    final repository = buildRepository();
    return ProviderRequestsWorkspaceBloc(
      listRequests: ListProviderRequestsUseCase(repository),
      getCounts: GetProviderRequestCountsUseCase(repository),
      getStats: GetProviderRequestStatsUseCase(repository),
    );
  }

  ProviderRequestDetailBloc buildDetail() {
    final repository = buildRepository();
    return ProviderRequestDetailBloc(
      requestId: 'req-1',
      getRequest: GetProviderRequestUseCase(repository),
      createOffer: CreateProviderOfferUseCase(repository),
      withdrawOffer: WithdrawProviderOfferUseCase(repository),
      acceptCounter: AcceptClientCounterUseCase(repository),
      declineCounter: DeclineClientCounterUseCase(repository),
      counterOffer: CounterClientOfferUseCase(repository),
      completeJob: CompleteProviderJobUseCase(repository),
      cancelJob: CancelProviderJobUseCase(repository),
    );
  }

  void stubWorkspace({List<Map<String, dynamic>>? rows}) {
    client
      ..stub(
        'provider/requests',
        TaskEither.right(pageJson(rows ?? [providerRequestJson()])),
      )
      ..stub('provider/requests/counts', TaskEither.right(countsJson()))
      ..stub('provider/requests/stats', TaskEither.right(statsJson()));
  }

  setUp(() => client = RecordingApiClient());

  group('workspace', () {
    blocTest<ProviderRequestsWorkspaceBloc, ProviderRequestsWorkspaceState>(
      'loads the feed, the counts and the stats together',
      setUp: stubWorkspace,
      build: buildWorkspace,
      act: (bloc) => bloc.add(const ProviderWorkspaceStarted()),
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.data.status, RequestStatus.success);
        expect(bloc.state.data.items, hasLength(1));
        expect(bloc.state.counts.of(ProviderRequestTab.newRequest), 7);
        expect(bloc.state.stats.completedThisMonth, 14);
      },
    );

    blocTest<ProviderRequestsWorkspaceBloc, ProviderRequestsWorkspaceState>(
      'switching tab re-queries the server from page 1',
      setUp: stubWorkspace,
      build: buildWorkspace,
      act: (bloc) async {
        bloc.add(const ProviderWorkspaceStarted());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(
          const ProviderWorkspaceTabChanged(ProviderRequestTab.yourTurn),
        );
      },
      wait: const Duration(milliseconds: 120),
      verify: (bloc) {
        expect(bloc.state.tab, ProviderRequestTab.yourTurn);
        final feed = client.calls
            .where((c) => c.path == 'provider/requests')
            .last;
        expect(feed.query!['tab'], 'YOUR_TURN');
        expect(feed.query!['page'], 1);
      },
    );

    blocTest<ProviderRequestsWorkspaceBloc, ProviderRequestsWorkspaceState>(
      'deselecting a tab drops the parameter entirely',
      setUp: stubWorkspace,
      build: buildWorkspace,
      act: (bloc) async {
        bloc.add(const ProviderWorkspaceStarted());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(
          const ProviderWorkspaceTabChanged(ProviderRequestTab.newRequest),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const ProviderWorkspaceTabChanged(null));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.tab, isNull);
        expect(
          client.calls
              .where((c) => c.path == 'provider/requests')
              .last
              .query!
              .containsKey('tab'),
          isFalse,
        );
      },
    );

    blocTest<ProviderRequestsWorkspaceBloc, ProviderRequestsWorkspaceState>(
      'search reaches the server once, after the debounce',
      setUp: stubWorkspace,
      build: buildWorkspace,
      act: (bloc) async {
        bloc.add(const ProviderWorkspaceStarted());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // Three keystrokes in quick succession: restartable() plus the
        // in-handler delay collapses them into one query.
        bloc
          ..add(const ProviderWorkspaceSearchChanged('cle'))
          ..add(const ProviderWorkspaceSearchChanged('clean'))
          ..add(const ProviderWorkspaceSearchChanged('cleaning'));
      },
      wait: const Duration(milliseconds: 700),
      verify: (bloc) {
        expect(bloc.state.search, 'cleaning');
        final searched = client.calls.where(
          (c) => c.path == 'provider/requests' && c.query!['search'] != null,
        );
        expect(searched, hasLength(1));
        expect(searched.single.query!['search'], 'cleaning');
      },
    );

    blocTest<ProviderRequestsWorkspaceBloc, ProviderRequestsWorkspaceState>(
      'a failed counts read does not take the feed down with it',
      setUp: () {
        client
          ..stub(
            'provider/requests',
            TaskEither.right(pageJson([providerRequestJson()])),
          )
          ..stub(
            'provider/requests/counts',
            TaskEither.left(const ServerFailure(message: 'boom')),
          )
          ..stub(
            'provider/requests/stats',
            TaskEither.left(const ServerFailure(message: 'boom')),
          );
      },
      build: buildWorkspace,
      act: (bloc) => bloc.add(const ProviderWorkspaceStarted()),
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        // A workspace that cannot show its badges is still usable.
        expect(bloc.state.data.status, RequestStatus.success);
        expect(bloc.state.data.items, hasLength(1));
        expect(bloc.state.counts, ProviderRequestCounts.empty);
      },
    );

    blocTest<ProviderRequestsWorkspaceBloc, ProviderRequestsWorkspaceState>(
      'a refresh re-reads the counts as well as the feed',
      setUp: stubWorkspace,
      build: buildWorkspace,
      act: (bloc) async {
        bloc.add(const ProviderWorkspaceStarted());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const ProviderWorkspaceRefreshed());
      },
      wait: const Duration(milliseconds: 120),
      verify: (_) {
        // Counts move with the feed: a request that expired on a server timer
        // leaves one tab and enters another.
        expect(
          client.calls
              .where((c) => c.path == 'provider/requests/counts')
              .length,
          2,
        );
      },
    );
  });

  group('detail', () {
    blocTest<ProviderRequestDetailBloc, ProviderRequestDetailState>(
      'sending an offer re-reads the request afterwards',
      setUp: () {
        client
          ..stub(
            'provider/requests/req-1',
            TaskEither.right(
              providerRequestJson(
                tab: 'AWAITING_CLIENT',
                myOffers: [providerOfferJson()],
                myOfferStatus: 'PENDING',
              ),
            ),
          )
          ..stub('provider/requests/req-1/offers', TaskEither.right(null));
      },
      build: buildDetail,
      act: (bloc) async {
        bloc.add(const ProviderRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          ProviderOfferCreated(
            branchId: 'branch-1',
            proposedAt: DateTime(2026, 9, 12, 11),
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.mutationStatus, RequestStatus.success);
        expect(bloc.state.request!.tab, ProviderRequestTab.awaitingClient);
        expect(bloc.state.request!.isAwaitingClient, isTrue);
      },
    );

    blocTest<ProviderRequestDetailBloc, ProviderRequestDetailState>(
      'accepting a client counter unlocks the contact block',
      setUp: () {
        client
          ..stub(
            'provider/requests/req-1',
            TaskEither.right(
              providerRequestJson(
                status: 'SCHEDULED',
                tab: 'SCHEDULED',
                contact: unlockedContactJson(),
                myOffers: [providerOfferJson(status: 'ACCEPTED')],
                myOfferStatus: 'ACCEPTED',
              ),
            ),
          )
          ..stub('provider/offers/offer-1/accept', TaskEither.right(null));
      },
      build: buildDetail,
      act: (bloc) async {
        bloc.add(const ProviderRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProviderCounterAccepted('offer-1'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        // Unlocking is the server's decision, observed by re-reading — never
        // inferred from "we accepted, so we must have won".
        expect(bloc.state.request!.contact.isUnlocked, isTrue);
        expect(bloc.state.request!.contact.clientPhone, '+971501234567');
      },
    );

    blocTest<ProviderRequestDetailBloc, ProviderRequestDetailState>(
      'an exhausted re-bid budget surfaces the 409 and forces a re-read',
      setUp: () {
        client
          ..stub(
            'provider/requests/req-1',
            TaskEither.right(providerRequestJson(remainingRebids: 0)),
          )
          ..stub(
            'provider/requests/req-1/offers',
            TaskEither.left(
              const ConflictFailure(message: 'No re-bids left', code: '409'),
            ),
          );
      },
      build: buildDetail,
      act: (bloc) async {
        bloc.add(const ProviderRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          ProviderOfferCreated(
            branchId: 'branch-1',
            proposedAt: DateTime(2026, 9, 12, 11),
          ),
        );
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.mutationFailure, isA<ConflictFailure>());
        expect(
          client.calls.where((c) => c.path == 'provider/requests/req-1').length,
          2,
          reason: 'a 409 usually means the server state moved underneath us',
        );
      },
    );

    blocTest<ProviderRequestDetailBloc, ProviderRequestDetailState>(
      'completing moves the request to AWAITING_CONFIRMATION',
      setUp: () {
        client
          ..stub(
            'provider/requests/req-1',
            TaskEither.right(
              providerRequestJson(
                status: 'AWAITING_CONFIRMATION',
                tab: 'TO_CONFIRM',
                contact: unlockedContactJson(),
              ),
            ),
          )
          ..stub('provider/requests/req-1/complete', TaskEither.right(null));
      },
      build: buildDetail,
      act: (bloc) async {
        bloc.add(const ProviderRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProviderJobCompleted());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) => expect(
        bloc.state.request!.status,
        ClientRequestStatus.awaitingConfirmation,
      ),
    );

    blocTest<ProviderRequestDetailBloc, ProviderRequestDetailState>(
      'cancelling a booking sends the reason',
      setUp: () {
        client
          ..stub(
            'provider/requests/req-1',
            TaskEither.right(
              providerRequestJson(status: 'CANCELLED', tab: 'CLOSED'),
            ),
          )
          ..stub('provider/requests/req-1/cancel', TaskEither.right(null));
      },
      build: buildDetail,
      act: (bloc) async {
        bloc.add(const ProviderRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProviderJobCancelled('Van broke down.'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.request!.status, ClientRequestStatus.cancelled);
        final cancel = client.calls.firstWhere(
          (c) => c.path == 'provider/requests/req-1/cancel',
        );
        expect(cancel.body, {'reason': 'Van broke down.'});
      },
    );

    blocTest<ProviderRequestDetailBloc, ProviderRequestDetailState>(
      'a failed action leaves the loaded request in place',
      setUp: () {
        client
          ..stub(
            'provider/requests/req-1',
            TaskEither.right(providerRequestJson()),
          )
          ..stub(
            'provider/requests/req-1/complete',
            TaskEither.left(
              const ConflictFailure(message: 'Not started yet', code: '409'),
            ),
          );
      },
      build: buildDetail,
      act: (bloc) async {
        bloc.add(const ProviderRequestDetailStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProviderJobCompleted());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        // The action did not happen, so the screen keeps showing what is true.
        expect(bloc.state.request!.status, ClientRequestStatus.submitted);
        expect(bloc.state.mutationStatus, RequestStatus.failure);
      },
    );
  });
}
