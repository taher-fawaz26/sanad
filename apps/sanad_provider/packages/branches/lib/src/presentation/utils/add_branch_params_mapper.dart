import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
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

    final position = draft.pickedPosition!;
    final radiusKm = draft.coverageRadiusKm!;
    final servingAreaPlaceIds = _servingAreaPlaceIds(draft);

    return CreateBranchParams(
      branchName: draft.branchName.trim(),
      branchType: draft.branchType,
      branchAddress: draft.branchAddress ?? '',
      locationPlaceId: draft.locationPlaceId!,
      branchPhone: _normalizePhone(draft.phone),
      branchManagerId: draft.selectedManager?.id,
      lat: position.latitude,
      lng: position.longitude,
      radiusKm: radiusKm,
      workerIds: draft.selectedWorkers.map((w) => w.id).toList(growable: false),
      availabilityMode: _availabilityMode(isCustom),
      availability: schedule.isNotEmpty ? schedule : null,
      // Both are sent as-is, empty or not. `POST /branches` requires them
      // with at least one entry, so mapping an empty selection to `null` (as
      // this used to) only converted a wizard bug into a server `400` with a
      // less useful message. `AddBranchDraftState`'s step gates keep the
      // submit button disabled until both are populated.
      servingAreaPlaceIds: servingAreaPlaceIds,
      serviceIds: _serviceIds(draft),
    );
  }

  /// Branch phone is optional on the backend — normalize only when the user
  /// actually entered one, so an empty draft phone maps to an empty string
  /// instead of [UaePhoneValidator.normalize]'s bogus `+971` fallback.
  static String _normalizePhone(String phone) {
    final trimmed = phone.trim();
    return trimmed.isEmpty ? '' : UaePhoneValidator.normalize(trimmed);
  }

  static BranchAvailabilityMode _availabilityMode(bool isCustom) => isCustom
      ? BranchAvailabilityMode.custom
      : BranchAvailabilityMode.coreHours;

  // Serving areas are sourced from Google (auto areas within the radius and
  // manually-added areas), so their place_ids are real Google ids the backend
  // accepts. We still drop empty and synthetic, geocoder-derived ids
  // (coordinate keys like `latlng:25.07,55.13`) — those are local fallbacks,
  // not Google place_ids. See `ServingArea.placeId`. Auto and manually-added
  // areas can independently resolve to the same place_id (e.g. a manually
  // picked area also discovered by the grid), so dedup while preserving
  // first-seen order.
  static List<String> _servingAreaPlaceIds(AddBranchDraft draft) => draft
      .servingAreas
      .map((a) => a.placeId)
      .where((id) => id.isNotEmpty && !id.startsWith('latlng:'))
      .toSet()
      .toList(growable: false);

  static List<String> _serviceIds(AddBranchDraft draft) =>
      draft.selectedServices.map((s) => s.id).toList(growable: false);

  /// Builds a full-payload PATCH from the current [branch] state.
  ///
  /// Used by section-by-section Branch Details editing: apply a single
  /// section's change via [BranchEntity.copyWith] first, then pass the
  /// resulting entity here to reconstruct the complete update request so
  /// unrelated fields are never dropped or nulled out.
  ///
  /// `serviceIds` is still omitted, but for a different reason than before:
  /// `BranchEntity` does not carry the provider-service ids back (`services`
  /// returns `null`), so there is nothing to echo. Omitting the key leaves the
  /// server's own value untouched, which is the correct no-op. Sending an
  /// empty array instead would now be rejected outright.
  ///
  /// `servingAreaPlaceIds` is filtered for the same reason: an empty list from
  /// a branch whose areas failed to load must read as "no change", not as an
  /// attempt to clear them.
  ///
  /// [workerIds] overrides the branch's current team — needed because the
  /// worker-selection sheet returns `WorkerEntity` (from the `workers`
  /// package), which isn't the same shape as [BranchEntity.workers], so the
  /// Team section can't round-trip its edit through [BranchEntity.copyWith].
  static UpdateBranchParams fromBranch(
    BranchEntity branch, {
    List<String>? workerIds,
  }) {
    return UpdateBranchParams(
      id: branch.id,
      branchName: branch.branchName.trim(),
      branchAddress: branch.branchAddress,
      branchPhone: _normalizePhone(branch.branchPhone),
      branchType: branch.branchType,
      locationPlaceId: branch.locationPlaceId,
      branchManagerId: branch.branchManagerId,
      lat: branch.lat,
      lng: branch.lng,
      radiusKm: branch.radiusKm,
      googleMapsLink: branch.googleMapsLink,
      socialMediaLink: branch.socialMediaLink,
      availabilityMode: branch.availabilityMode,
      availability: branch.availability,
      servingAreaPlaceIds: (branch.servingAreaPlaceIds?.isEmpty ?? true)
          ? null
          : branch.servingAreaPlaceIds,
      workerIds:
          workerIds ?? branch.workers.map((w) => w.id).toList(growable: false),
    );
  }
}
