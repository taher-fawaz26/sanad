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
    final servingAreaPlaceIds = _servingAreaPlaceIds(draft);

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
      availabilityMode: _availabilityMode(isCustom),
      availability: schedule.isNotEmpty ? schedule : null,
      servingAreaPlaceIds: servingAreaPlaceIds.isNotEmpty
          ? servingAreaPlaceIds
          : null,
      serviceIds: _serviceIds(draft),
    );
  }

  /// Maps a fully-filled edit draft to a PATCH params object for [id]. Reuses
  /// the same schedule selection and serving-area/service/worker mapping as
  /// [toCreateParams]. In edit mode every step is prefilled and Save is gated
  /// on step completeness, so the required fields are guaranteed present.
  static UpdateBranchParams toUpdateParams(
    AddBranchDraft draft, {
    required String id,
    required List<BranchAvailabilityEntity> companySchedule,
  }) {
    if (draft.selectedWorkers.isEmpty) {
      throw ArgumentError(
        'At least one worker must be assigned before saving a branch.',
      );
    }

    final isCustom = draft.scheduleMode == BranchScheduleMode.custom;
    final schedule = isCustom ? draft.customSchedule : companySchedule;

    final city = draft.selectedCity!;
    final position = draft.pickedPosition!;
    final radiusKm = draft.coverageRadiusKm!;
    final servingAreaPlaceIds = _servingAreaPlaceIds(draft);

    return UpdateBranchParams(
      id: id,
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
      availabilityMode: _availabilityMode(isCustom),
      availability: schedule.isNotEmpty ? schedule : null,
      servingAreaPlaceIds: servingAreaPlaceIds.isNotEmpty
          ? servingAreaPlaceIds
          : null,
      serviceIds: _serviceIds(draft),
    );
  }

  static BranchAvailabilityMode _availabilityMode(bool isCustom) => isCustom
      ? BranchAvailabilityMode.custom
      : BranchAvailabilityMode.coreHours;

  // Serving areas are sourced from Google (auto areas within the radius and
  // manually-added areas), so their place_ids are real Google ids the backend
  // accepts. We still drop empty and synthetic, geocoder-derived ids
  // (coordinate keys like `latlng:25.07,55.13`) — those are local fallbacks,
  // not Google place_ids. See `ServingArea.placeId`.
  static List<String> _servingAreaPlaceIds(AddBranchDraft draft) => draft
      .servingAreas
      .map((a) => a.placeId)
      .where((id) => id.isNotEmpty && !id.startsWith('latlng:'))
      .toList(growable: false);

  static List<String>? _serviceIds(AddBranchDraft draft) =>
      draft.selectedServices.isNotEmpty
      ? draft.selectedServices.map((s) => s.id).toList(growable: false)
      : null;
}
