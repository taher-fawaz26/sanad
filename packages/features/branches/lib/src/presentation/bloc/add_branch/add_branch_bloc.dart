import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_branch_event.dart';
part 'add_branch_state.dart';

class AddBranchBloc extends Bloc<AddBranchEvent, AddBranchState> {
  AddBranchBloc({
    required CreateBranchUseCase createBranchUseCase,
    required GetCompanyScheduleUseCase getCompanyScheduleUseCase,
  }) : _createBranchUseCase = createBranchUseCase,
       _getCompanyScheduleUseCase = getCompanyScheduleUseCase,
       super(const AddBranchState()) {
    on<AddBranchStarted>(_onStarted);
    on<AddBranchSubmitEvent>(_onSubmit);
  }

  final CreateBranchUseCase _createBranchUseCase;
  final GetCompanyScheduleUseCase _getCompanyScheduleUseCase;

  Future<void> _onStarted(
    AddBranchStarted event,
    Emitter<AddBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        setupStatus: RequestStatus.loading,
        clearSetupFailure: true,
      ),
    );

    final result = await _getCompanyScheduleUseCase(const NoParams()).run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          setupStatus: RequestStatus.failure,
          setupFailure: failure,
        ),
      ),
      (schedule) => emit(
        state.copyWith(
          setupStatus: RequestStatus.success,
          companySchedule: schedule,
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
