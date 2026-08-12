import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

class AddBranchDraftCubit extends Cubit<AddBranchDraft> {
  AddBranchDraftCubit({AddBranchDraft initial = const AddBranchDraft()})
    : _initial = initial,
      super(initial);

  /// Baseline the draft is compared against for change tracking. Empty in
  /// create mode; the branch-seeded draft in edit mode. Updated by [seed] when
  /// the branch is loaded lazily (id-only edit entry).
  AddBranchDraft _initial;

  /// The baseline used for the discard guard ([AddBranchDraft.hasChangesFrom]).
  AddBranchDraft get initial => _initial;

  /// Whether the current draft differs from its baseline.
  bool get hasChanges => state.hasChangesFrom(_initial);

  /// Replaces both the baseline and the current draft. Used when the branch is
  /// fetched lazily in edit mode (only the id was provided at entry).
  void seed(AddBranchDraft draft) {
    _initial = draft;
    emit(draft);
  }

  void updateBasicInfo({
    String? branchName,
    String? phone,
  }) {
    emit(
      state.copyWith(
        branchName: branchName,
        phone: phone,
      ),
    );
  }

  void updateCity(CityEntity city) {
    emit(state.copyWith(selectedCity: () => city));
  }

  void updateBranchType(BranchType type) {
    emit(state.copyWith(branchType: type));
  }

  void updateLocation({
    required String? address,
    required LatLng? position,
  }) {
    emit(
      state.copyWith(
        branchAddress: () => address,
        pickedPosition: () => position,
      ),
    );
  }

  void updateManager(BranchManagerEntity? manager) {
    emit(state.copyWith(selectedManager: () => manager));
  }

  void updateScheduleMode(BranchScheduleMode mode) {
    emit(state.copyWith(scheduleMode: mode));
  }

  void updateCustomSchedule(List<BranchAvailabilityEntity> schedule) {
    emit(state.copyWith(customSchedule: schedule));
  }

  void initializeCustomSchedule(List<BranchAvailabilityEntity> schedule) {
    if (state.customSchedule.isNotEmpty) return;
    emit(state.copyWith(customSchedule: schedule));
  }

  void updateCoverage({
    required String? address,
    required LatLng? position,
    required double? radiusKm,
    required List<ServingArea> servingAreas,
  }) {
    emit(
      state.copyWith(
        branchAddress: () => address,
        pickedPosition: () => position,
        coverageRadiusKm: () => radiusKm,
        servingAreas: servingAreas,
      ),
    );
  }

  void updateServices(List<CatalogServiceSelection> services) {
    emit(state.copyWith(selectedServices: services));
  }

  void removeService(CatalogServiceSelection service) {
    emit(
      state.copyWith(
        selectedServices: state.selectedServices
            .where((s) => s.id != service.id)
            .toList(),
      ),
    );
  }

  void updateWorkers(List<WorkerEntity> workers) {
    emit(state.copyWith(selectedWorkers: workers));
  }

  void removeWorker(WorkerEntity worker) {
    emit(
      state.copyWith(
        selectedWorkers: state.selectedWorkers
            .where((w) => w.id != worker.id)
            .toList(),
      ),
    );
  }
}
