import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';

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
class AddBranchLocationCubit extends Cubit<AddBranchLocationState> {
  AddBranchLocationCubit(this._locationService)
    : super(const AddBranchLocationState());

  final LocationService _locationService;

  /// Called once on flow entry (Step 1). Checks first; if merely denied
  /// (not yet asked, or previously dismissed without "don't ask again"),
  /// immediately triggers the native OS prompt so the user isn't asked for
  /// the first time only once they reach the coverage step.
  Future<void> ensureAccess() async {
    final status = await _locationService.checkPermission();
    if (status == LocationPermissionStatus.denied) {
      final requested = await _locationService.requestPermission();
      emit(AddBranchLocationState(status: requested));
      return;
    }
    emit(AddBranchLocationState(status: status));
  }

  /// Re-checks the OS state without prompting. Used on app resume (e.g.
  /// returning from Settings) — the source of truth is always a fresh OS
  /// read, never the outcome of the original request.
  Future<void> refresh() async {
    emit(AddBranchLocationState(status: await _locationService.checkPermission()));
  }

  /// Triggers the native prompt again (the in-flow "Allow location access"
  /// action). No-op UX-wise once permanently denied — the OS won't show a
  /// dialog — so the blocked screen's "Open Settings" action is the only
  /// recovery in that state.
  Future<void> requestAgain() async {
    emit(AddBranchLocationState(status: await _locationService.requestPermission()));
  }

  Future<void> openSettings() => _locationService.openAppSettings();
}
