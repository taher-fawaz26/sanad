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
    this.selectedCity,
    this.phone = '',
    this.branchAddress,
    this.pickedPosition,
    this.selectedManager,
    this.scheduleMode = BranchScheduleMode.company,
    this.customSchedule = const [],
    this.lastScheduleRejection,
    this.coverageRadiusKm,
    this.servingAreas = const [],
    this.selectedServices = const [],
    this.selectedWorkers = const [],
  });

  final String branchName;
  final BranchType branchType;
  final CityEntity? selectedCity;
  final String phone;
  final String? branchAddress;
  final LatLng? pickedPosition;
  final BranchManagerEntity? selectedManager;
  final BranchScheduleMode scheduleMode;
  final List<BranchAvailabilityEntity> customSchedule;

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
      selectedCity != baseline.selectedCity ||
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
      selectedCity != null &&
      branchAddress != null &&
      pickedPosition != null &&
      UaePhoneValidator.isMobile(phone) &&
      selectedManager != null &&
      _isScheduleComplete;

  bool get _isScheduleComplete =>
      scheduleMode == BranchScheduleMode.company ||
      customSchedule.isNotEmpty;

  bool get isStepTwoComplete =>
      coverageRadiusKm != null &&
      branchAddress != null &&
      branchAddress!.isNotEmpty;

  bool get isStepThreeComplete => selectedServices.isNotEmpty;

  bool get isStepFourComplete => selectedWorkers.isNotEmpty;

  AddBranchDraft copyWith({
    String? branchName,
    BranchType? branchType,
    CityEntity? Function()? selectedCity,
    String? phone,
    String? Function()? branchAddress,
    LatLng? Function()? pickedPosition,
    BranchManagerEntity? Function()? selectedManager,
    BranchScheduleMode? scheduleMode,
    List<BranchAvailabilityEntity>? customSchedule,
    ScheduleSlotRejection? Function()? lastScheduleRejection,
    double? Function()? coverageRadiusKm,
    List<ServingArea>? servingAreas,
    List<CatalogServiceSelection>? selectedServices,
    List<WorkerEntity>? selectedWorkers,
  }) => AddBranchDraft(
    branchName: branchName ?? this.branchName,
    branchType: branchType ?? this.branchType,
    selectedCity: selectedCity != null ? selectedCity() : this.selectedCity,
    phone: phone ?? this.phone,
    branchAddress: branchAddress != null ? branchAddress() : this.branchAddress,
    pickedPosition: pickedPosition != null
        ? pickedPosition()
        : this.pickedPosition,
    selectedManager: selectedManager != null
        ? selectedManager()
        : this.selectedManager,
    scheduleMode: scheduleMode ?? this.scheduleMode,
    customSchedule: customSchedule ?? this.customSchedule,
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
    selectedCity,
    phone,
    branchAddress,
    pickedPosition,
    selectedManager,
    scheduleMode,
    customSchedule,
    lastScheduleRejection,
    coverageRadiusKm,
    servingAreas,
    selectedServices,
    selectedWorkers,
  ];
}
