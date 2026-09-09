import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/client_requests_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/request_draft/request_draft_bloc.dart';
import 'package:testing/testing.dart';

import '../support/client_requests_fakes.dart';

void main() {
  late RecordingApiClient client;

  // A plain function, not a `late` variable: `blocTest(build: ...)` reads its
  // argument while the test is being *declared*, before `setUp` has run.
  RequestDraftBloc buildBloc() {
    final repository = ClientRequestsRepositoryImpl(
      ClientRequestsRemoteDataSourceImpl(client),
    );
    return RequestDraftBloc(
      createDraft: CreateDraftRequestUseCase(repository),
      updateDraft: UpdateDraftRequestUseCase(repository),
      submitRequest: SubmitRequestUseCase(repository),
      getRequest: GetClientRequestUseCase(repository),
    );
  }

  setUp(() => client = RecordingApiClient());

  ConflictFailure conflict(String code, {List<dynamic>? alternatives}) =>
      ConflictFailure(
        message: 'Nothing matched',
        code: '409',
        metadata: {
          'code': code,
          if (alternatives != null) 'alternatives': alternatives,
        },
      );

  group('partial drafts', () {
    blocTest<RequestDraftBloc, RequestDraftState>(
      'saves a draft with only a service chosen',
      setUp: () => client.defaultResponse = TaskEither.right(
        clientRequestJson(
          status: 'DRAFT',
          lat: null,
          lng: null,
          preferredAt: null,
          threads: const [],
          matchedBranches: const [],
          offerCount: 0,
        ),
      ),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          const RequestDraftServiceChanged(
            serviceId: 'svc-1',
            serviceName: 'Deep cleaning',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RequestDraftSaved());
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        // Nothing ran submit-time validation: an incomplete draft saved fine.
        expect(bloc.state.saveStatus, RequestStatus.success);
        expect(client.lastCall.path, 'requests');
        expect(client.lastCall.body, {'serviceId': 'svc-1'});
      },
    );

    blocTest<RequestDraftBloc, RequestDraftState>(
      'patches instead of re-creating once the draft has an id',
      setUp: () => client.defaultResponse = TaskEither.right(
        clientRequestJson(status: 'DRAFT'),
      ),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const RequestDraftSaved());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const RequestDraftNoteChanged('leaking tap'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RequestDraftSaved());
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        expect(client.calls.first.method, RequestMethod.post);
        expect(client.lastCall.method, RequestMethod.patch);
        expect(client.lastCall.path, 'requests/req-1');
      },
    );

    blocTest<RequestDraftBloc, RequestDraftState>(
      'reports what submit still needs',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const RequestDraftServiceChanged(
          serviceId: 'svc-1',
          serviceName: 'Deep cleaning',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.canSubmit, isFalse);
        expect(bloc.state.missingForSubmit, ['location', 'preferredAt']);
      },
    );
  });

  group('a failed save keeps the entered input', () {
    blocTest<RequestDraftBloc, RequestDraftState>(
      'preserves every field so the user can retry without retyping',
      setUp: () => client.defaultResponse = TaskEither.left(
        const NoInternetFailure(message: 'errors.no_internet'),
      ),
      build: buildBloc,
      act: (bloc) async {
        bloc
          ..add(
            const RequestDraftServiceChanged(
              serviceId: 'svc-1',
              serviceName: 'Deep cleaning',
            ),
          )
          ..add(const RequestDraftNoteChanged('the kitchen tap leaks'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RequestDraftSaved());
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        expect(bloc.state.saveStatus, RequestStatus.failure);
        expect(bloc.state.saveFailure, isA<NoInternetFailure>());
        expect(bloc.state.serviceId, 'svc-1');
        expect(bloc.state.note, 'the kitchen tap leaks');
      },
    );
  });

  group('submit', () {
    blocTest<RequestDraftBloc, RequestDraftState>(
      'saves then submits, and adopts the server request',
      setUp: () {
        client
          ..stub(
            'requests',
            TaskEither.right(clientRequestJson(status: 'DRAFT')),
          )
          ..stub(
            'requests/req-1/submit',
            TaskEither.right(clientRequestJson()),
          );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          const RequestDraftServiceChanged(
            serviceId: 'svc-1',
            serviceName: 'Deep cleaning',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RequestDraftSubmitted());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.submitStatus, RequestStatus.success);
        // The status comes from the response, never from a local assumption.
        expect(bloc.state.status, ClientRequestStatus.submitted);
        expect(
          client.calls.map((c) => c.path),
          containsAllInOrder(['requests', 'requests/req-1/submit']),
        );
      },
    );

    blocTest<RequestDraftBloc, RequestDraftState>(
      'surfaces a 400 for a past preferredAt without clearing the form',
      setUp: () {
        client
          ..stub(
            'requests',
            TaskEither.right(clientRequestJson(status: 'DRAFT')),
          )
          ..stub(
            'requests/req-1/submit',
            TaskEither.left(
              const ValidationFailure(
                message: 'preferredAt must be in the future',
                code: '400',
              ),
            ),
          );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const RequestDraftSubmitted()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.submitStatus, RequestStatus.failure);
        expect(bloc.state.submitFailure, isA<ValidationFailure>());
        // Not a matching conflict, so no code-specific recovery banner.
        expect(bloc.state.submissionConflict, isNull);
      },
    );
  });

  group('structured 409 submission conflicts', () {
    Future<RequestDraftBloc> submitWith(Failure failure) async {
      client
        ..stub('requests', TaskEither.right(clientRequestJson(status: 'DRAFT')))
        ..stub('requests/req-1/submit', TaskEither.left(failure));
      final bloc = buildBloc()..add(const RequestDraftSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return bloc;
    }

    test(
      'NO_PROVIDERS_FOR_SERVICE arrives typed, with no alternatives',
      () async {
        final bloc = await submitWith(conflict('NO_PROVIDERS_FOR_SERVICE'));

        final c = bloc.state.submissionConflict!;
        expect(c.code, RequestSubmissionConflictCode.noProvidersForService);
        expect(c.hasAlternatives, isFalse);
        await bloc.close();
      },
    );

    test('NO_COVERAGE arrives typed', () async {
      final bloc = await submitWith(conflict('NO_COVERAGE'));

      expect(
        bloc.state.submissionConflict!.code,
        RequestSubmissionConflictCode.noCoverage,
      );
      await bloc.close();
    });

    test('OUTSIDE_HOURS carries its retry windows', () async {
      final bloc = await submitWith(
        conflict(
          'OUTSIDE_HOURS',
          alternatives: [
            {
              'start': '2026-09-12T09:00:00+04:00',
              'end': '2026-09-12T12:00:00+04:00',
            },
            {'start': '2026-09-13T09:00:00+04:00'},
          ],
        ),
      );

      final c = bloc.state.submissionConflict!;
      expect(c.code, RequestSubmissionConflictCode.outsideHours);
      expect(c.alternatives, hasLength(2));
      expect(c.alternatives.first.start.toUtc(), DateTime.utc(2026, 9, 12, 5));
      await bloc.close();
    });

    test('an unrecognised 409 still yields a typed conflict', () async {
      final bloc = await submitWith(
        const ConflictFailure(
          message: 'Already submitted',
          code: '409',
          metadata: {'message': 'Already submitted'},
        ),
      );

      expect(
        bloc.state.submissionConflict!.code,
        RequestSubmissionConflictCode.unknown,
      );
      await bloc.close();
    });

    test('picking a new time clears the OUTSIDE_HOURS banner', () async {
      // Tapping one of the offered windows is the recovery action, so the
      // banner must not linger over the corrected draft.
      final bloc = await submitWith(
        conflict(
          'OUTSIDE_HOURS',
          alternatives: [
            {'start': '2026-09-13T09:00:00+04:00'},
          ],
        ),
      );
      expect(bloc.state.submissionConflict, isNotNull);

      bloc.add(RequestDraftPreferredAtChanged(DateTime(2026, 9, 13, 9)));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.submissionConflict, isNull);
      await bloc.close();
    });

    test('picking a new service clears the NO_PROVIDERS banner', () async {
      final bloc = await submitWith(conflict('NO_PROVIDERS_FOR_SERVICE'));

      bloc.add(
        const RequestDraftServiceChanged(
          serviceId: 'svc-2',
          serviceName: 'Plumbing',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.submissionConflict, isNull);
      await bloc.close();
    });

    test('picking a new address clears the NO_COVERAGE banner', () async {
      final bloc = await submitWith(conflict('NO_COVERAGE'));

      bloc.add(
        const RequestDraftLocationChanged(lat: 25.3, lng: 55.4),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.submissionConflict, isNull);
      await bloc.close();
    });
  });

  group('editing a request the server will not let us edit', () {
    test(
      'a 409 from PATCH is surfaced and the input is kept',
      () async {
        // The backend refuses an edit once an offer awaits a reply. The
        // composer must not go on treating the request as editable, and must
        // not throw away what the user just typed.
        client.defaultResponse = TaskEither.left(
          const ConflictFailure(
            message: 'Offers are awaiting a reply',
            code: '409',
          ),
        );
        final repository = ClientRequestsRepositoryImpl(
          ClientRequestsRemoteDataSourceImpl(client),
        );
        final bloc = RequestDraftBloc(
          createDraft: CreateDraftRequestUseCase(repository),
          updateDraft: UpdateDraftRequestUseCase(repository),
          submitRequest: SubmitRequestUseCase(repository),
          getRequest: GetClientRequestUseCase(repository),
          initial: ClientRequest(
            id: 'req-1',
            status: ClientRequestStatus.submitted,
            createdAt: DateTime(2026, 9, 11),
          ),
        )..add(const RequestDraftNoteChanged('new note'));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const RequestDraftSaved());
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(bloc.state.saveStatus, RequestStatus.failure);
        expect(bloc.state.saveFailure, isA<ConflictFailure>());
        expect(bloc.state.note, 'new note');
        // Patched, not created: the request already exists server-side.
        expect(client.lastCall.method, RequestMethod.patch);
        await bloc.close();
      },
    );
  });
}
