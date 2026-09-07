import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/get_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_usecase.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockBranchRepository extends Mock implements BranchRepository {}

void main() {
  late _MockBranchRepository repository;

  // Custom-schedule branches carry their own hours, so opening them does not
  // fetch the company schedule — keeps these section-save tests focused on the
  // PATCH + re-fetch mechanics.
  const branch = BranchEntity(
    id: 'branch-1',
    branchName: 'Downtown Branch',
    branchAddress: '123 Main St',
    city: 'Dubai',
    branchPhone: '+971501234567',
    isAvailable: true,
    availabilityMode: BranchAvailabilityMode.custom,
    branchType: BranchType.mainBranch,
  );

  const refreshedBranch = BranchEntity(
    id: 'branch-1',
    branchName: 'Renamed Branch',
    branchAddress: '123 Main St',
    city: 'Dubai',
    branchPhone: '+971501234567',
    isAvailable: true,
    availabilityMode: BranchAvailabilityMode.custom,
    branchType: BranchType.mainBranch,
  );

  const updateParams = UpdateBranchParams(
    id: 'branch-1',
    branchName: 'Renamed Branch',
    branchAddress: '123 Main St',
    branchPhone: '+971501234567',
  );

  BranchDetailsBloc buildBloc() => BranchDetailsBloc(
    getBranchUseCase: GetBranchUseCase(repository),
    updateBranchStatusUseCase: UpdateBranchStatusUseCase(repository),
    updateBranchUseCase: UpdateBranchUseCase(repository),
    getCompanyScheduleUseCase: GetCompanyScheduleUseCase(repository),
  );

  setUpAll(() {
    registerFallbackValue(const GetBranchParams(id: 'branch-1'));
  });

  setUp(() {
    repository = _MockBranchRepository();
  });

  blocTest<BranchDetailsBloc, BranchDetailsState>(
    'BranchSectionUpdated: PATCH success → re-fetches and emits the fresh '
    'branch, never the local params',
    build: () {
      when(() => repository.updateBranch(updateParams)).thenAnswer(
        (_) => TaskEither.of(refreshedBranch),
      );
      when(
        () => repository.getBranch(const GetBranchParams(id: 'branch-1')),
      ).thenAnswer((_) => TaskEither.of(refreshedBranch));
      return buildBloc();
    },
    seed: () => const BranchDetailsState(
      branchId: 'branch-1',
      status: RequestStatus.success,
      branch: branch,
    ),
    act: (bloc) => bloc.add(const BranchSectionUpdated(updateParams)),
    expect: () => [
      const BranchDetailsState(
        branchId: 'branch-1',
        status: RequestStatus.success,
        branch: branch,
        sectionSaveStatus: RequestStatus.loading,
      ),
      const BranchDetailsState(
        branchId: 'branch-1',
        status: RequestStatus.success,
        branch: refreshedBranch,
        sectionSaveStatus: RequestStatus.loading,
      ),
      const BranchDetailsState(
        branchId: 'branch-1',
        status: RequestStatus.success,
        branch: refreshedBranch,
        sectionSaveStatus: RequestStatus.success,
      ),
    ],
    verify: (_) {
      verify(() => repository.updateBranch(updateParams)).called(1);
      verify(
        () => repository.getBranch(const GetBranchParams(id: 'branch-1')),
      ).called(1);
    },
  );

  blocTest<BranchDetailsBloc, BranchDetailsState>(
    'BranchSectionUpdated: PATCH failure → keeps the current branch, sets '
    'sectionSaveFailure, never re-fetches',
    build: () {
      when(() => repository.updateBranch(updateParams)).thenAnswer(
        (_) => TaskEither.left(const NetworkFailure(message: 'offline')),
      );
      return buildBloc();
    },
    seed: () => const BranchDetailsState(
      branchId: 'branch-1',
      status: RequestStatus.success,
      branch: branch,
    ),
    act: (bloc) => bloc.add(const BranchSectionUpdated(updateParams)),
    expect: () => [
      const BranchDetailsState(
        branchId: 'branch-1',
        status: RequestStatus.success,
        branch: branch,
        sectionSaveStatus: RequestStatus.loading,
      ),
      const BranchDetailsState(
        branchId: 'branch-1',
        status: RequestStatus.success,
        branch: branch,
        sectionSaveStatus: RequestStatus.failure,
        sectionSaveFailure: NetworkFailure(message: 'offline'),
      ),
    ],
    verify: (_) {
      verify(() => repository.updateBranch(updateParams)).called(1);
      verifyNever(() => repository.getBranch(any()));
    },
  );

  blocTest<BranchDetailsBloc, BranchDetailsState>(
    'droppable(): a second BranchStatusToggleEvent while one is in flight '
    'does not fire a duplicate API call',
    build: () {
      final gate = Completer<BranchEntity>();
      when(
        () => repository.updateBranchStatus(
          const UpdateBranchStatusParams(id: 'branch-1', isAvailable: false),
        ),
      ).thenAnswer((_) => TaskEither(() => gate.future.then(Right.new)));
      addTearDown(() => gate.complete(refreshedBranch));
      return buildBloc();
    },
    seed: () => const BranchDetailsState(
      branchId: 'branch-1',
      status: RequestStatus.success,
      branch: branch,
    ),
    act: (bloc) => bloc
      ..add(const BranchStatusToggleEvent(isAvailable: false))
      ..add(const BranchStatusToggleEvent(isAvailable: false)),
    wait: const Duration(milliseconds: 10),
    verify: (_) {
      verify(
        () => repository.updateBranchStatus(
          const UpdateBranchStatusParams(id: 'branch-1', isAvailable: false),
        ),
      ).called(1);
    },
  );

  group('company-hours branch (SAN-780 / SAN-774)', () {
    // Company-hours branch: its own availability is empty, so the effective
    // schedule lives in the company schedule.
    //
    // `city` is taken straight from the payload. The backend localizes
    // `city.name` from the request language (`x-lang`/`Accept-Language`), and
    // that header now follows the app's single source of truth, so there is no
    // client-side resolution step. The bloc used to re-resolve the name from
    // the cities list, which cost two extra requests per open, could never be
    // cleared after a location edit, and left the City row disagreeing with
    // the address line (SAN-774).
    const companyHoursBranch = BranchEntity(
      id: 'branch-2',
      branchName: 'HQ Branch',
      branchAddress: '1 Sheikh Zayed Rd',
      city: 'حتا',
      branchPhone: '+971501234567',
      isAvailable: true,
      availabilityMode: BranchAvailabilityMode.coreHours,
      branchType: BranchType.mainBranch,
      cityId: 'city-1',
    );

    const companySchedule = [
      BranchAvailabilityEntity(
        day: BranchWeekdays.saturday,
        slots: [BranchTimeSlotEntity(from: '10:00', to: '14:00')],
      ),
    ];

    blocTest<BranchDetailsBloc, BranchDetailsState>(
      'fetch → resolves the company schedule, and surfaces the payload city '
      'verbatim in exactly one emission',
      build: () {
        when(
          () => repository.getBranch(const GetBranchParams(id: 'branch-2')),
        ).thenAnswer((_) => TaskEither.of(companyHoursBranch));
        when(repository.getCompanySchedule).thenAnswer(
          (_) => TaskEither.of(companySchedule),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const BranchDetailsFetchEvent('branch-2')),
      // The company schedule is resolved BEFORE success is surfaced, so it
      // arrives in the same emission as the branch — never a separate
      // "branch present, schedule still null" frame that would flash every
      // day as closed (SAN-780). And there is no third emission: the city
      // needs no follow-up round-trip.
      expect: () => [
        const BranchDetailsState(
          branchId: 'branch-2',
          status: RequestStatus.loading,
        ),
        const BranchDetailsState(
          branchId: 'branch-2',
          status: RequestStatus.success,
          branch: companyHoursBranch,
          companySchedule: companySchedule,
        ),
      ],
      verify: (bloc) => expect(
        bloc.state.branch!.city,
        'حتا',
        reason: 'the header-localized payload value is what the UI shows',
      ),
    );
  });
}
