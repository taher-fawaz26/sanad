import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';

part 'add_branch_location_event.dart';

/// UI-facing location-permission state for the Add Branch flow.
///
/// [status] is `null` until the first check completes, so callers can avoid
/// reacting to a not-yet-known state (e.g. before the flow has even
/// requested permission on entry).
class AddBranchLocationState extends Equatable {
  const AddBranchLocationState({this.status});

  final LocationPermissionStatus? status;

  bool get hasChecked => status != null;
  bool get isGranted => status == LocationPermissionStatus.granted;
  bool get isServiceDisabled =>
      status == LocationPermissionStatus.serviceDisabled;

  /// Blocked at the OS level — recoverable only through app/device settings.
  bool get isBlocked =>
      status == LocationPermissionStatus.permanentlyDenied || isServiceDisabled;

  @override
  List<Object?> get props => [status];
}

/// Single coordinator for the Add Branch flow's device-location permission.
///
/// Wraps [LocationService] (which already folds in the location-service/GPS
/// check) so the page never talks to the permission plugin directly and
/// there is exactly one place that requests/checks it for this flow.
class AddBranchLocationBloc
    extends Bloc<AddBranchLocationEvent, AddBranchLocationState> {
  AddBranchLocationBloc(this._locationService)
    : super(const AddBranchLocationState()) {
    on<AddBranchLocationEnsureAccessRequested>(
      _onEnsureAccess,
      transformer: droppable(),
    );
    on<AddBranchLocationRefreshed>(
      _onRefresh,
      transformer: droppable(),
    );
    on<AddBranchLocationRequestAgain>(
      _onRequestAgain,
      transformer: droppable(),
    );
  }

  final LocationService _locationService;

  // Imperative helpers — kept so existing call sites keep working. The
  // async ones dispatch a `droppable()`-guarded event that runs the actual
  // service call inside the handler.

  /// Called once on flow entry (Step 1). See handler for the ask-first
  /// vs immediate-request logic.
  Future<void> ensureAccess() async {
    add(const AddBranchLocationEnsureAccessRequested());
  }

  /// Re-checks the OS state without prompting. Used on app resume.
  Future<void> refresh() async {
    add(const AddBranchLocationRefreshed());
  }

  /// Triggers the native prompt again.
  Future<void> requestAgain() async {
    add(const AddBranchLocationRequestAgain());
  }

  /// Opens app settings — pure side effect on the OS, no state change.
  Future<void> openSettings() => _locationService.openAppSettings();

  Future<void> _onEnsureAccess(
    AddBranchLocationEnsureAccessRequested event,
    Emitter<AddBranchLocationState> emit,
  ) async {
    final status = await _locationService.checkPermission();
    if (status == LocationPermissionStatus.denied) {
      final requested = await _locationService.requestPermission();
      emit(AddBranchLocationState(status: requested));
      return;
    }
    emit(AddBranchLocationState(status: status));
  }

  Future<void> _onRefresh(
    AddBranchLocationRefreshed event,
    Emitter<AddBranchLocationState> emit,
  ) async {
    emit(
      AddBranchLocationState(status: await _locationService.checkPermission()),
    );
  }

  Future<void> _onRequestAgain(
    AddBranchLocationRequestAgain event,
    Emitter<AddBranchLocationState> emit,
  ) async {
    emit(
      AddBranchLocationState(
        status: await _locationService.requestPermission(),
      ),
    );
  }
}
