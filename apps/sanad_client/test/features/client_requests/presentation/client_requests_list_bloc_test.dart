import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/client_requests_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_requests_tab.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:testing/testing.dart';

import '../support/client_requests_fakes.dart';

void main() {
  late RecordingApiClient client;

  ClientRequestsListBloc buildBloc() {
    final repository = ClientRequestsRepositoryImpl(
      ClientRequestsRemoteDataSourceImpl(client),
    );
    return ClientRequestsListBloc(
      listRequests: ListClientRequestsUseCase(repository),
      cancelRequest: CancelClientRequestUseCase(repository),
    );
  }

  setUp(() => client = RecordingApiClient());

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'loads the first page',
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([clientRequestJson(), clientRequestJson(id: 'req-2')]),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ClientRequestsStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.data.status, RequestStatus.success);
      expect(bloc.state.data.items, hasLength(2));
      expect(client.lastCall.query!['page'], 1);
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'renders a page of drafts with their nullable fields intact',
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([
        {
          'id': 'req-draft',
          'status': 'DRAFT',
          'attachments': <dynamic>[],
          'offerCount': 0,
          'matchedBranches': <dynamic>[],
          'threads': <dynamic>[],
          'createdAt': '2026-09-11T07:00:00+04:00',
        },
      ]),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ClientRequestsStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      final row = bloc.state.data.items.single;
      expect(row.status, ClientRequestStatus.draft);
      expect(row.serviceName, isNull);
      expect(row.preferredAt, isNull);
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'the Scheduled tab filters server-side and resets to page 1',
    // Filtering a loaded page client-side would show an arbitrary subset of
    // the matches and an incorrect "no more" state, so a tab that maps onto
    // one status sends it.
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([clientRequestJson(status: 'SCHEDULED')]),
    ),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsTabChanged(ClientRequestsTab.scheduled));
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(bloc.state.tab, ClientRequestsTab.scheduled);
      expect(client.lastCall.query!['status'], 'SCHEDULED');
      expect(client.lastCall.query!['page'], 1);
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'the Cancelled tab asks the server for CANCELLED only',
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([clientRequestJson(status: 'CANCELLED')]),
    ),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsTabChanged(ClientRequestsTab.cancelled));
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(client.lastCall.query!['status'], 'CANCELLED');
      expect(
        bloc.state.data.items.single.status,
        ClientRequestStatus.cancelled,
      );
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'returning to Active drops the status parameter entirely',
    // Active spans five statuses and the endpoint takes one, so it reads
    // unfiltered rather than inventing a repeated-parameter contract.
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([clientRequestJson()]),
    ),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsTabChanged(ClientRequestsTab.scheduled));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsTabChanged(ClientRequestsTab.active));
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.tab, ClientRequestsTab.active);
      expect(client.lastCall.query!.containsKey('status'), isFalse);
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'Active hides only the rows the other two tabs own',
    // A completed request still appears: dropping it would make it
    // unreachable in a three-tab design.
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([
        clientRequestJson(id: 'live'),
        clientRequestJson(id: 'booked', status: 'SCHEDULED'),
        clientRequestJson(id: 'called-off', status: 'CANCELLED'),
        clientRequestJson(id: 'done', status: 'COMPLETED'),
      ]),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ClientRequestsStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) => expect(
      bloc.state.data.items.map((request) => request.id),
      ['live', 'done'],
    ),
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'rows waiting on the client are hoisted above the rest, stably',
    // The screen draws "Needs your attention" and then the tab's own heading
    // as two runs of one list, so the order has to put them in that order.
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([
        // No pending offer: nothing for the client to answer.
        clientRequestJson(id: 'quiet-1', threads: [], offerCount: 0),
        clientRequestJson(id: 'needs-you'),
        clientRequestJson(id: 'quiet-2', threads: [], offerCount: 0),
      ]),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ClientRequestsStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(
        bloc.state.data.items.map((request) => request.id),
        ['needs-you', 'quiet-1', 'quiet-2'],
      );
      expect(
        bloc.state.needingAttention.map((request) => request.id),
        ['needs-you'],
      );
      expect(
        bloc.state.remaining.map((request) => request.id),
        ['quiet-1', 'quiet-2'],
      );
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'cancelling adopts the server answer, which moves the row off Active',
    // The row is replaced by the server's own post-action request — never a
    // locally-assumed CANCELLED, which a concurrent server transition could
    // already have overtaken. Re-arranging then drops it from Active, because
    // a cancelled request belongs to the Cancelled tab.
    setUp: () {
      client
        ..defaultResponse = TaskEither.right(
          pageJson([clientRequestJson()]),
        )
        ..stub(
          'requests/req-1/cancel',
          TaskEither.right(
            clientRequestJson(status: 'CANCELLED'),
          ),
        );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(
        const ClientRequestCancelRequested(
          id: 'req-1',
          reason: 'Plans changed.',
        ),
      );
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.mutation, RequestStatus.success);
      expect(bloc.state.data.items, isEmpty);
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'on the Cancelled tab the cancelled row stays, with the new status',
    setUp: () {
      client
        ..defaultResponse = TaskEither.right(
          pageJson([clientRequestJson(status: 'CANCELLED')]),
        )
        ..stub(
          'requests/req-1/cancel',
          TaskEither.right(clientRequestJson(status: 'CANCELLED')),
        );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsTabChanged(ClientRequestsTab.cancelled));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(
        const ClientRequestCancelRequested(
          id: 'req-1',
          reason: 'Done with it.',
        ),
      );
    },
    wait: const Duration(milliseconds: 120),
    verify: (bloc) => expect(
      bloc.state.data.items.single.status,
      ClientRequestStatus.cancelled,
    ),
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'a failed cancellation keeps the row and reports the failure',
    setUp: () {
      client
        ..defaultResponse = TaskEither.right(
          pageJson([clientRequestJson()]),
        )
        ..stub(
          'requests/req-1/cancel',
          TaskEither.left(
            const NoInternetFailure(message: 'errors.no_internet'),
          ),
        );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(
        const ClientRequestCancelRequested(id: 'req-1', reason: 'Nope.'),
      );
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.mutation, RequestStatus.failure);
      expect(bloc.state.failure, isA<NoInternetFailure>());
      expect(bloc.state.data.items, hasLength(1));
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'appends the next page and dedupes by request id',
    setUp: () {
      var call = 0;
      client.defaultResponse = TaskEither(() async {
        call++;
        return right(
          call == 1
              ? pageJson([clientRequestJson()], totalPages: 2)
              : pageJson(
                  // The first row repeats because the backing list shifted
                  // between requests.
                  [clientRequestJson(), clientRequestJson(id: 'req-2')],
                  totalPages: 2,
                  currentPage: 2,
                ),
        );
      });
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsNextPageRequested());
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) =>
        expect(bloc.state.data.items.map((e) => e.id), ['req-1', 'req-2']),
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'keeps loaded rows when a next-page fetch fails',
    setUp: () {
      var call = 0;
      client.defaultResponse = TaskEither(() async {
        call++;
        return call == 1
            ? right(pageJson([clientRequestJson()], totalPages: 2))
            : left(const NoInternetFailure(message: 'errors.no_internet'));
      });
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsNextPageRequested());
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.data.items, hasLength(1));
      expect(bloc.state.data.nextPageError, isA<NoInternetFailure>());
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'never asks for more than the backend page cap',
    setUp: () => client.defaultResponse = TaskEither.right(pageJson([])),
    build: buildBloc,
    act: (bloc) => bloc.add(const ClientRequestsStarted()),
    wait: const Duration(milliseconds: 50),
    verify: (_) => expect(
      client.lastCall.query!['limit'],
      lessThanOrEqualTo(kMaxPageLimit),
    ),
  );
}
