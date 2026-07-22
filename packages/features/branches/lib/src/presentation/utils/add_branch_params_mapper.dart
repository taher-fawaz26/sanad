import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:core/core.dart';

abstract final class AddBranchParamsMapper {
  static CreateBranchParams toCreateParams(
    AddBranchDraft draft, {
    required List<BranchAvailabilityEntity> companySchedule,
  }) {
    if (draft.selectedWorkers.isEmpty) {
      throw ArgumentError(
        'At least one worker must be assigned before submitting a branch.',
      );
    }

    final isCustom = draft.scheduleMode == BranchScheduleMode.custom;
    final schedule = isCustom ? draft.customSchedule : companySchedule;

    final city = draft.selectedCity!;
    final position = draft.pickedPosition!;
    final radiusKm = draft.coverageRadiusKm!;

    // The backend validates every serving-area place_id against its own areas
    // catalogue and 400s the whole branch on any unknown id. Synthetic,
    // geocoder-derived ids (coordinate keys like `latlng:25.07,55.13`) are not
    // catalogue entries, so we never send them — only real catalogue place_ids
    // reach the API. See `ServingArea.placeId`.
    final servingAreaPlaceIds = draft.servingAreas
        .map((a) => a.placeId)
        .where((id) => id.isNotEmpty && !id.startsWith('latlng:'))
        .toList(growable: false);

    return CreateBranchParams(
      branchName: draft.branchName.trim(),
      branchType: draft.branchType,
      branchAddress: draft.branchAddress ?? '',
      cityId: city.id,
      branchPhone: UaePhoneValidator.normalize(draft.phone),
      branchManagerId: draft.selectedManager!.id,
      lat: position.latitude,
      lng: position.longitude,
      radiusKm: radiusKm,
      workerIds: draft.selectedWorkers.map((w) => w.id).toList(growable: false),
      availabilityMode: isCustom
          ? BranchAvailabilityMode.custom
          : BranchAvailabilityMode.coreHours,
      availability: schedule.isNotEmpty ? schedule : null,
      servingAreaPlaceIds: servingAreaPlaceIds.isNotEmpty
          ? servingAreaPlaceIds
          : null,
      serviceIds: draft.selectedServices.isNotEmpty
          ? draft.selectedServices.map((s) => s.id).toList(growable: false)
          : null,
    );
  }
}
