import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/policies/branch_schedule_policy.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

/// A rejected add-slot attempt on the custom working-hours schedule —
/// enough context to render a localized inline error naming the day and
/// (when applicable) the conflicting slot. Mirrors organization_settings'
/// `SlotRejection`, sharing the same [SlotValidationReason] from
/// [BranchSchedulePolicy].
class ScheduleSlotRejection extends Equatable {
  const ScheduleSlotRejection({
    required this.reason,
    required this.dayId,
    required this.from,
    required this.to,
    this.conflict,
  });

  final SlotValidationReason reason;
  final String dayId;
  final String from;
  final String to;
  final BranchTimeSlotEntity? conflict;

  @override
  List<Object?> get props => [reason, dayId, from, to, conflict];
}

class AddBranchDraft extends Equatable {
  const AddBranchDraft({
    this.branchName = '',
    this.branchType = BranchType.mainBranch,
    this.phone = '',
    this.branchAddress,
    this.pickedPosition,
    this.locationPlaceId,
    this.selectedManager,
    this.scheduleMode = BranchScheduleMode.company,
    this.customSchedule = const [],
    this.companyHasWorkingHours = false,
    this.lastScheduleRejection,
    this.coverageRadiusKm,
    this.servingAreas = const [],
    this.selectedServices = const [],
    this.selectedWorkers = const [],
  });

  final String branchName;
  final BranchType branchType;
  final String phone;
  final String? branchAddress;
  final LatLng? pickedPosition;

  /// Google Places Autocomplete place ID for the branch location.
  final String? locationPlaceId;
  final BranchManagerEntity? selectedManager;
  final BranchScheduleMode scheduleMode;
  final List<BranchAvailabilityEntity> customSchedule;

  /// Whether the company (parent) schedule has at least one working slot,
  /// seeded from the setup fetch. In [BranchScheduleMode.company] the branch
  /// inherits the company schedule, so this gates Step 1 completion: a company
  /// with no hours set yet cannot be inherited into a usable branch.
  final bool companyHasWorkingHours;

  /// Most recent add-slot validation rejection for [customSchedule], or
  /// `null` when there's nothing to show. See [ScheduleSlotRejection].
  final ScheduleSlotRejection? lastScheduleRejection;
  final double? coverageRadiusKm;
  final List<ServingArea> servingAreas;
  final List<CatalogServiceSelection> selectedServices;
  final List<WorkerEntity> selectedWorkers;

  /// Whether the user has entered anything worth guarding with a
  /// discard-changes confirmation (Figma `Discard changes?` popover), relative
  /// to an empty draft. Equivalent to `hasChangesFrom(const AddBranchDraft())`.
  bool get hasChanges => hasChangesFrom(const AddBranchDraft());

  /// Whether this draft differs from [baseline] in any user-editable field.
  ///
  /// In create mode the baseline is an empty draft; in edit mode it is the
  /// draft seeded from the saved branch, so this drives the discard guard in
  /// both flows. [customSchedule] is excluded because it is auto-seeded from
  /// the company schedule without direct user input.
  bool hasChangesFrom(AddBranchDraft baseline) =>
      branchName.trim() != baseline.branchName.trim() ||
      branchType != baseline.branchType ||
      phone.trim() != baseline.phone.trim() ||
      branchAddress != baseline.branchAddress ||
      pickedPosition != baseline.pickedPosition ||
      selectedManager != baseline.selectedManager ||
      scheduleMode != baseline.scheduleMode ||
      coverageRadiusKm != baseline.coverageRadiusKm ||
      !listEquals(servingAreas, baseline.servingAreas) ||
      !listEquals(selectedServices, baseline.selectedServices) ||
      !listEquals(selectedWorkers, baseline.selectedWorkers);

  /// Manager is required: although the published Swagger spec lists
  /// `branchManagerId` as optional, `POST /api/v1/branches` rejects a null
  /// value at runtime (`400 branchManagerId must be a UUID`) — the actual
  /// backend contract requires it, so it gates Step 1 here too.
  bool get isStepOneComplete =>
      branchName.trim().isNotEmpty &&
      hasValidResolvedLocation &&
      UaePhoneValidator.isMobile(phone) &&
      selectedManager != null &&
      _isScheduleComplete;

  /// True when Step 1 has produced a canonical, backend-valid branch location:
  /// a resolved Google Place ID together with coordinates and an address.
  ///
  /// This is the *saved branch location*, deliberately distinct from live
  /// device-location availability (permission / GPS services). Step 2
  /// (coverage + serving-area discovery) is configured entirely from this
  /// stored location — search / map tap / pin — and never acquires a fresh
  /// device position, so this, not live location-services state, is what
  /// gates the coverage step. Disabling device Location later does not
  /// invalidate an already-resolved branch location.
  bool get hasValidResolvedLocation =>
      locationPlaceId != null &&
      pickedPosition != null &&
      branchAddress != null &&
      branchAddress!.isNotEmpty;

  /// Working hours are mandatory. In company mode the branch inherits the
  /// company schedule, so it must actually have hours; in custom mode the
  /// user must have added at least one working slot.
  bool get _isScheduleComplete => switch (scheduleMode) {
    BranchScheduleMode.company => companyHasWorkingHours,
    BranchScheduleMode.custom => hasCustomWorkingHours,
  };

  /// True when the custom schedule has at least one day with at least one
  /// slot — a day entry stripped of all its slots does not count.
  bool get hasCustomWorkingHours =>
      customSchedule.any((day) => day.slots.isNotEmpty);

  bool get isStepTwoComplete =>
      coverageRadiusKm != null &&
      branchAddress != null &&
      branchAddress!.isNotEmpty;

  bool get isStepThreeComplete => selectedServices.isNotEmpty;

  bool get isStepFourComplete => selectedWorkers.isNotEmpty;

  AddBranchDraft copyWith({
    String? branchName,
    BranchType? branchType,
    String? phone,
    String? Function()? branchAddress,
    LatLng? Function()? pickedPosition,
    String? Function()? locationPlaceId,
    BranchManagerEntity? Function()? selectedManager,
    BranchScheduleMode? scheduleMode,
    List<BranchAvailabilityEntity>? customSchedule,
    bool? companyHasWorkingHours,
    ScheduleSlotRejection? Function()? lastScheduleRejection,
    double? Function()? coverageRadiusKm,
    List<ServingArea>? servingAreas,
    List<CatalogServiceSelection>? selectedServices,
    List<WorkerEntity>? selectedWorkers,
  }) => AddBranchDraft(
    branchName: branchName ?? this.branchName,
    branchType: branchType ?? this.branchType,
    phone: phone ?? this.phone,
    branchAddress: branchAddress != null ? branchAddress() : this.branchAddress,
    pickedPosition: pickedPosition != null
        ? pickedPosition()
        : this.pickedPosition,
    locationPlaceId: locationPlaceId != null
        ? locationPlaceId()
        : this.locationPlaceId,
    selectedManager: selectedManager != null
        ? selectedManager()
        : this.selectedManager,
    scheduleMode: scheduleMode ?? this.scheduleMode,
    customSchedule: customSchedule ?? this.customSchedule,
    companyHasWorkingHours:
        companyHasWorkingHours ?? this.companyHasWorkingHours,
    lastScheduleRejection: lastScheduleRejection != null
        ? lastScheduleRejection()
        : this.lastScheduleRejection,
    coverageRadiusKm: coverageRadiusKm != null
        ? coverageRadiusKm()
        : this.coverageRadiusKm,
    servingAreas: servingAreas ?? this.servingAreas,
    selectedServices: selectedServices ?? this.selectedServices,
    selectedWorkers: selectedWorkers ?? this.selectedWorkers,
  );

  @override
  List<Object?> get props => [
    branchName,
    branchType,
    phone,
    branchAddress,
    pickedPosition,
    locationPlaceId,
    selectedManager,
    scheduleMode,
    customSchedule,
    companyHasWorkingHours,
    lastScheduleRejection,
    coverageRadiusKm,
    servingAreas,
    selectedServices,
    selectedWorkers,
  ];
}
