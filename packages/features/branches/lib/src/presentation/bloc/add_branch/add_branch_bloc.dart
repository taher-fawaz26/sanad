import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_branch_event.dart';
part 'add_branch_state.dart';

class AddBranchBloc extends Bloc<AddBranchEvent, AddBranchState> {
  AddBranchBloc({
    required CreateBranchUseCase createBranchUseCase,
    required GetCompanyScheduleUseCase getCompanyScheduleUseCase,
    UpdateBranchUseCase? updateBranchUseCase,
    GetBranchUseCase? getBranchUseCase,
  }) : _createBranchUseCase = createBranchUseCase,
       _getCompanyScheduleUseCase = getCompanyScheduleUseCase,
       _updateBranchUseCase = updateBranchUseCase,
       _getBranchUseCase = getBranchUseCase,
       super(const AddBranchState()) {
    on<AddBranchStarted>(_onStarted);
    on<AddBranchSubmitEvent>(_onSubmit);
    on<UpdateBranchSubmitEvent>(_onUpdateSubmit);
    on<AddBranchLoadForEditEvent>(_onLoadForEdit);
  }

  final CreateBranchUseCase _createBranchUseCase;
  final GetCompanyScheduleUseCase _getCompanyScheduleUseCase;
  final UpdateBranchUseCase? _updateBranchUseCase;
  final GetBranchUseCase? _getBranchUseCase;

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

  Future<void> _onUpdateSubmit(
    UpdateBranchSubmitEvent event,
    Emitter<AddBranchState> emit,
  ) async {
    final useCase = _updateBranchUseCase;
    if (useCase == null) {
      throw StateError('UpdateBranchUseCase is required in edit mode.');
    }
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await useCase(event.params).run();

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

  Future<void> _onLoadForEdit(
    AddBranchLoadForEditEvent event,
    Emitter<AddBranchState> emit,
  ) async {
    final useCase = _getBranchUseCase;
    if (useCase == null) {
      throw StateError('GetBranchUseCase is required in edit mode.');
    }
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, clearLoadFailure: true),
    );

    final result = await useCase(GetBranchParams(id: event.branchId)).run();

    result.fold(
      (failure) => emit(
        state.copyWith(loadStatus: RequestStatus.failure, loadFailure: failure),
      ),
      (branch) => emit(
        state.copyWith(
          loadStatus: RequestStatus.success,
          loadedBranch: branch,
        ),
      ),
    );
  }
}
