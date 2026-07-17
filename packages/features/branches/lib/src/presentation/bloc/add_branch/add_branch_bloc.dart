import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branch_managers_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

part 'add_branch_event.dart';
part 'add_branch_state.dart';

class AddBranchBloc extends Bloc<AddBranchEvent, AddBranchState> {
  AddBranchBloc({
    required CreateBranchUseCase createBranchUseCase,
    required GetCompanyScheduleUseCase getCompanyScheduleUseCase,
    required GetBranchManagersUseCase getBranchManagersUseCase,
  })  : _createBranchUseCase = createBranchUseCase,
        _getCompanyScheduleUseCase = getCompanyScheduleUseCase,
        _getBranchManagersUseCase = getBranchManagersUseCase,
        super(const AddBranchState()) {
    on<AddBranchStarted>(_onStarted);
    on<AddBranchSubmitEvent>(_onSubmit);
  }

  final CreateBranchUseCase _createBranchUseCase;
  final GetCompanyScheduleUseCase _getCompanyScheduleUseCase;
  final GetBranchManagersUseCase _getBranchManagersUseCase;

  Future<void> _onStarted(
    AddBranchStarted event,
    Emitter<AddBranchState> emit,
  ) async {
    emit(state.copyWith(
      setupStatus: RequestStatus.loading,
      clearSetupFailure: true,
    ));

    // Fetch schedule and managers in parallel — they are independent.
    final results = await Future.wait([
      _getCompanyScheduleUseCase(const NoParams()).run(),
      _getBranchManagersUseCase(const NoParams()).run(),
    ]);

    final scheduleResult = results[0] as Either<Failure, List<BranchAvailabilityEntity>>;
    final managersResult = results[1] as Either<Failure, List<BranchManagerEntity>>;

    final scheduleFailure = scheduleResult.fold((f) => f, (_) => null);
    final managersFailure = managersResult.fold((f) => f, (_) => null);
    final setupFailure = scheduleFailure ?? managersFailure;

    emit(
      state.copyWith(
        setupStatus: setupFailure != null
            ? RequestStatus.failure
            : RequestStatus.success,
        setupFailure: setupFailure,
        companySchedule: scheduleResult.fold(
          (_) => const <BranchAvailabilityEntity>[],
          (schedule) => schedule,
        ),
        managers: managersResult.fold(
          (_) => const <BranchManagerEntity>[],
          (managers) => managers,
        ),
      ),
    );
  }

  Future<void> _onSubmit(
    AddBranchSubmitEvent event,
    Emitter<AddBranchState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _createBranchUseCase(event.params).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (branch) => emit(
        state.copyWith(
          status: RequestStatus.success,
          createdBranch: branch,
        ),
      ),
    );
  }
}
