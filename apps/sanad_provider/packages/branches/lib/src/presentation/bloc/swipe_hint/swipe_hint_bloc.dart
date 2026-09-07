import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storage/storage.dart';

part 'swipe_hint_event.dart';
part 'swipe_hint_state.dart';

/// Owns the "have we already shown the branches-list swipe hint" bit,
/// backed by [HiveLocalStorage] under [StorageKeys.branchesSwipeHintSeen].
///
/// Replaces the `_hintSeen` nullable-as-loading-sentinel field on
/// `_BranchesTabState` (removes the widget's direct `sl<HiveLocalStorage>`
/// reads/writes and the `setState` after each async load/save).
class SwipeHintBloc extends Bloc<SwipeHintEvent, SwipeHintState> {
  SwipeHintBloc({required HiveLocalStorage storage})
    : _storage = storage,
      super(const SwipeHintState()) {
    on<SwipeHintLoadRequested>(_onLoad);
    on<SwipeHintMarkedSeen>(_onMarkSeen);
  }

  final HiveLocalStorage _storage;

  Future<void> _onLoad(
    SwipeHintLoadRequested event,
    Emitter<SwipeHintState> emit,
  ) async {
    final seen =
        await _storage.load(
              key: StorageKeys.branchesSwipeHintSeen,
              boxName: HiveBoxes.defaultBox,
            )
            as bool? ??
        false;
    emit(state.copyWith(loaded: true, seen: seen));
  }

  Future<void> _onMarkSeen(
    SwipeHintMarkedSeen event,
    Emitter<SwipeHintState> emit,
  ) async {
    emit(state.copyWith(seen: true, attempted: true));
    await _storage.save(
      key: StorageKeys.branchesSwipeHintSeen,
      value: true,
      boxName: HiveBoxes.defaultBox,
    );
  }
}
