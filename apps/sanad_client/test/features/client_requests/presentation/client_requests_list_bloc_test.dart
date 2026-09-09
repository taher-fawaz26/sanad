import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/client_requests_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:testing/testing.dart';

import '../support/client_requests_fakes.dart';

void main() {
  late RecordingApiClient client;

  ClientRequestsListBloc buildBloc() => ClientRequestsListBloc(
    listRequests: ListClientRequestsUseCase(
      ClientRequestsRepositoryImpl(
        ClientRequestsRemoteDataSourceImpl(client),
      ),
    ),
  );

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
    'filters server-side and resets to page 1',
    // Filtering a loaded page client-side would show an arbitrary subset of
    // the matches and an incorrect "no more" state.
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([clientRequestJson(status: 'DRAFT')]),
    ),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(
        const ClientRequestsFilterChanged(ClientRequestStatus.draft),
      );
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(bloc.state.statusFilter, ClientRequestStatus.draft);
      expect(client.lastCall.query!['status'], 'DRAFT');
      expect(client.lastCall.query!['page'], 1);
    },
  );

  blocTest<ClientRequestsListBloc, ClientRequestsListState>(
    'clearing the filter drops the query parameter entirely',
    setUp: () => client.defaultResponse = TaskEither.right(
      pageJson([clientRequestJson()]),
    ),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ClientRequestsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsFilterChanged(ClientRequestStatus.draft));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ClientRequestsFilterChanged(null));
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.statusFilter, isNull);
      expect(client.lastCall.query!.containsKey('status'), isFalse);
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
