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
  AddBranchDraftCubit() : super(const AddBranchDraft());

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

  void updateServices(List<ServiceEntity> services) {
    emit(state.copyWith(selectedServices: services));
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

  void removeService(ServiceEntity service) {
    emit(
      state.copyWith(
        selectedServices: state.selectedServices
            .where((s) => s.id != service.id)
            .toList(),
      ),
    );
  }
}
