import 'package:bloc_test/bloc_test.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/get_branch_usecase.dart';
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

  const branch = BranchEntity(
    id: 'branch-1',
    branchName: 'Downtown Branch',
    branchAddress: '123 Main St',
    city: 'Dubai',
    branchPhone: '+971501234567',
    isAvailable: true,
    availabilityMode: BranchAvailabilityMode.coreHours,
    branchType: BranchType.mainBranch,
  );

  const refreshedBranch = BranchEntity(
    id: 'branch-1',
    branchName: 'Renamed Branch',
    branchAddress: '123 Main St',
    city: 'Dubai',
    branchPhone: '+971501234567',
    isAvailable: true,
    availabilityMode: BranchAvailabilityMode.coreHours,
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
  );

  setUpAll(() {
    registerFallbackValue(const GetBranchParams(id: 'branch-1'));
  });

  setUp(() => repository = _MockBranchRepository());

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
}
