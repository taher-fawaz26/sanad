// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/get_invitations_usecase.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';

class _MockRepo extends Mock implements WorkerRepository {}

InvitationEntity _invitation(String id) => InvitationEntity(
  id: id,
  fullName: 'Invitee $id',
  role: 'worker',
  initials: 'I$id',
);

Page<InvitationEntity> _page(
  List<String> ids, {
  required int currentPage,
  required int totalPages,
}) => Page(
  items: ids.map(_invitation).toList(),
  meta: PageMeta(
    totalItems: ids.length,
    itemCount: ids.length,
    itemsPerPage: 2,
    totalPages: totalPages,
    currentPage: currentPage,
  ),
);

const _serverFailure = ServerFailure(message: 'boom');

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    registerFallbackValue(const InvitationsQuery());
  });

  InvitationsListBloc buildBloc() =>
      InvitationsListBloc(getInvitationsUseCase: GetInvitationsUseCase(repo));

  group('InvitationsListBloc', () {
    blocTest<InvitationsListBloc, InvitationsListState>(
      'loads the first page on Fetch',
      setUp: () => when(() => repo.getInvitations(any())).thenAnswer(
        (_) => TaskEither.of(_page(['1', '2'], currentPage: 1, totalPages: 2)),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(InvitationsListFetchEvent()),
      verify: (bloc) {
        expect(bloc.state.invitations, hasLength(2));
        expect(bloc.state.hasMore, isTrue);
      },
    );

    blocTest<InvitationsListBloc, InvitationsListState>(
      'empty result surfaces an empty list',
      setUp: () => when(() => repo.getInvitations(any())).thenAnswer(
        (_) => TaskEither.of(const Page<InvitationEntity>.empty()),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(InvitationsListFetchEvent()),
      verify: (bloc) => expect(bloc.state.invitations, isEmpty),
    );

    blocTest<InvitationsListBloc, InvitationsListState>(
      'first-page error surfaces hasError',
      setUp: () => when(
        () => repo.getInvitations(any()),
      ).thenAnswer((_) => TaskEither.left(_serverFailure)),
      build: buildBloc,
      act: (bloc) => bloc.add(InvitationsListFetchEvent()),
      verify: (bloc) {
        expect(bloc.state.hasError, isTrue);
        expect(bloc.state.failure, _serverFailure);
      },
    );

    blocTest<InvitationsListBloc, InvitationsListState>(
      'search resets to page 1 and replaces previously loaded invitations',
      setUp: () {
        when(() => repo.getInvitations(const InvitationsQuery())).thenAnswer(
          (_) =>
              TaskEither.of(_page(['1', '2'], currentPage: 3, totalPages: 3)),
        );
        when(
          () => repo.getInvitations(const InvitationsQuery(search: 'Sara')),
        ).thenAnswer(
          (_) => TaskEither.of(_page(['7'], currentPage: 1, totalPages: 1)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const InvitationsListSearchChangedEvent('Sara')),
      wait: const Duration(milliseconds: 400),
      verify: (bloc) {
        expect(bloc.state.invitations.map((i) => i.id), ['7']);
        expect(bloc.state.page, 1);
      },
    );

    blocTest<InvitationsListBloc, InvitationsListState>(
      'removing an invitation drops it from the list',
      build: buildBloc,
      seed: () => InvitationsListState(
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_invitation('1'), _invitation('2')],
        ),
      ),
      act: (bloc) => bloc.add(const InvitationRemovedFromListEvent('1')),
      verify: (bloc) {
        expect(bloc.state.invitations.map((i) => i.id), ['2']);
      },
    );

    blocTest<InvitationsListBloc, InvitationsListState>(
      'cancelling an invitation marks it cancelled in place',
      build: buildBloc,
      seed: () => InvitationsListState(
        pagination: PaginationData(
          status: RequestStatus.success,
          items: [_invitation('1')],
        ),
      ),
      act: (bloc) => bloc.add(const InvitationCancelledInListEvent('1')),
      verify: (bloc) {
        expect(
          bloc.state.invitations.single.status,
          InvitationStatus.cancelled,
        );
      },
    );
  });
}
