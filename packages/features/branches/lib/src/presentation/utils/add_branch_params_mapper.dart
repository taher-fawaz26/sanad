import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';

abstract final class AddBranchParamsMapper {
  static CreateBranchParams toCreateParams(
    AddBranchDraft draft, {
    required List<BranchAvailabilityEntity> companySchedule,
  }) {
    final isCustom = draft.scheduleMode == BranchScheduleMode.custom;
    final schedule = isCustom ? draft.customSchedule : companySchedule;

    return CreateBranchParams(
      branchName: draft.branchName.trim(),
      branchType: draft.branchType,
      branchAddress: draft.branchAddress ?? '',
      city: draft.city.trim(),
      branchPhone: draft.phone.trim(),
      branchManagerId: draft.selectedManagerId,
      lat: draft.pickedPosition?.latitude,
      lng: draft.pickedPosition?.longitude,
      radiusKm: draft.coverageRadiusKm,
      availabilityMode: isCustom
          ? BranchAvailabilityMode.custom
          : BranchAvailabilityMode.coreHours,
      availability: schedule.isNotEmpty ? schedule : null,
      servingAreaPlaceIds: draft.servingAreas.isNotEmpty
          ? draft.servingAreas
                .map((a) => a.placeId)
                .toList(growable: false)
          : null,
      serviceIds: draft.selectedServices.isNotEmpty
          ? draft.selectedServices
                .map((s) => s.id)
                .toList(growable: false)
          : null,
      workerIds: draft.selectedWorkers.isNotEmpty
          ? draft.selectedWorkers
                .map((w) => w.id)
                .toList(growable: false)
          : null,
    );
  }
}
