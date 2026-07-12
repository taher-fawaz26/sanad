import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_branch_event.dart';
part 'add_branch_state.dart';

class AddBranchBloc extends Bloc<AddBranchEvent, AddBranchState> {
  AddBranchBloc({required CreateBranchUseCase createBranchUseCase})
      : _createBranchUseCase = createBranchUseCase,
        super(const AddBranchState()) {
    on<AddBranchSubmitEvent>(_onSubmit);
  }

  final CreateBranchUseCase _createBranchUseCase;

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
