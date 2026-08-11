import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';

/// Type of worker action currently in flight.
enum WorkerActionType { suspend, unsuspend, delete }

/// One-shot side-effect emitted after a worker action.
///
/// Consumed by the page via a [StreamSubscription] on
/// [WorkerActionCubit.effects] (typically inside a `BlocListener` scoped
/// `MultiBlocProvider`). Using a
/// stream instead of state polling avoids the "ack event" anti-pattern and the
/// race between a mutable `progressVisible` bool and a re-render.
sealed class WorkerActionEffect extends Equatable {
  const WorkerActionEffect();

  @override
  List<Object?> get props => [];
}

final class WorkerActionStarted extends WorkerActionEffect {
  const WorkerActionStarted(this.type);
  final WorkerActionType type;

  @override
  List<Object?> get props => [type];
}

final class WorkerActionSucceeded extends WorkerActionEffect {
  const WorkerActionSucceeded({
    required this.type,
    required this.workerId,
    this.updatedWorker,
  });

  final WorkerActionType type;
  final String workerId;

  /// For status changes, the freshly-fetched worker so the list can be
  /// updated in place. Null for deletes.
  final WorkerEntity? updatedWorker;

  @override
  List<Object?> get props => [type, workerId, updatedWorker];
}

final class WorkerActionFailed extends WorkerActionEffect {
  const WorkerActionFailed({required this.type, required this.failure});

  final WorkerActionType type;
  final Failure failure;

  @override
  List<Object?> get props => [type, failure];
}

/// Simple in-flight tracker so the page can disable duplicate taps.
class WorkerActionState extends Equatable {
  const WorkerActionState({this.inFlight});
  final WorkerActionType? inFlight;

  bool get isBusy => inFlight != null;

  @override
  List<Object?> get props => [inFlight];
}

class WorkerActionCubit extends Cubit<WorkerActionState> {
  WorkerActionCubit({
    required DeleteWorkerUseCase deleteWorkerUseCase,
    required UpdateWorkerStatusUseCase updateWorkerStatusUseCase,
  }) : _deleteWorkerUseCase = deleteWorkerUseCase,
       _updateWorkerStatusUseCase = updateWorkerStatusUseCase,
       super(const WorkerActionState());

  final DeleteWorkerUseCase _deleteWorkerUseCase;
  final UpdateWorkerStatusUseCase _updateWorkerStatusUseCase;

  final _effects = StreamController<WorkerActionEffect>.broadcast();

  Stream<WorkerActionEffect> get effects => _effects.stream;

  @override
  Future<void> close() async {
    await _effects.close();
    await super.close();
  }

  Future<void> delete(String workerId) async {
    if (state.isBusy) return;
    emit(const WorkerActionState(inFlight: WorkerActionType.delete));
    _effects.add(const WorkerActionStarted(WorkerActionType.delete));

    final result = await _deleteWorkerUseCase(
      DeleteWorkerParams(id: workerId),
    ).run();

    result.fold(
      (failure) => _effects.add(
        WorkerActionFailed(
          type: WorkerActionType.delete,
          failure: failure,
        ),
      ),
      (_) => _effects.add(
        WorkerActionSucceeded(
          type: WorkerActionType.delete,
          workerId: workerId,
        ),
      ),
    );

    emit(const WorkerActionState());
  }

  Future<void> changeStatus({
    required String workerId,
    required WorkerStatus status,
  }) async {
    if (state.isBusy) return;
    final type = status == WorkerStatus.inactive
        ? WorkerActionType.suspend
        : WorkerActionType.unsuspend;

    emit(WorkerActionState(inFlight: type));
    _effects.add(WorkerActionStarted(type));

    final result = await _updateWorkerStatusUseCase(
      UpdateWorkerStatusParams(id: workerId, status: status),
    ).run();

    result.fold(
      (failure) =>
          _effects.add(WorkerActionFailed(type: type, failure: failure)),
      (worker) => _effects.add(
        WorkerActionSucceeded(
          type: type,
          workerId: workerId,
          updatedWorker: worker,
        ),
      ),
    );

    emit(const WorkerActionState());
  }
}
