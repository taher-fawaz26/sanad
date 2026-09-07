part of 'add_branch_draft_bloc.dart';

/// Events dispatched via [AddBranchDraftBloc]'s imperative helper methods.
/// They are `_`-prefixed and library-private because widgets go through the
/// helper methods on the bloc, never construct events directly.
sealed class AddBranchDraftEvent extends Equatable {
  const AddBranchDraftEvent();

  @override
  List<Object?> get props => [];
}

final class _AddBranchBasicInfoChanged extends AddBranchDraftEvent {
  const _AddBranchBasicInfoChanged({this.branchName, this.phone});

  final String? branchName;
  final String? phone;

  @override
  List<Object?> get props => [branchName, phone];
}

final class _AddBranchTypeChanged extends AddBranchDraftEvent {
  const _AddBranchTypeChanged(this.type);

  final BranchType type;

  @override
  List<Object?> get props => [type];
}

final class _AddBranchLocationUpdated extends AddBranchDraftEvent {
  const _AddBranchLocationUpdated({
    required this.address,
    required this.position,
    this.placeId,
  });

  final String? address;
  final LatLng? position;
  final String? placeId;

  @override
  List<Object?> get props => [address, position, placeId];
}

final class _AddBranchManagerChanged extends AddBranchDraftEvent {
  const _AddBranchManagerChanged(this.manager);

  final BranchManagerEntity? manager;

  @override
  List<Object?> get props => [manager];
}

final class _AddBranchScheduleModeChanged extends AddBranchDraftEvent {
  const _AddBranchScheduleModeChanged(this.mode);

  final BranchScheduleMode mode;

  @override
  List<Object?> get props => [mode];
}

final class _AddBranchCustomScheduleUpdated extends AddBranchDraftEvent {
  const _AddBranchCustomScheduleUpdated(this.schedule);

  final List<BranchAvailabilityEntity> schedule;

  @override
  List<Object?> get props => [schedule];
}

final class _AddBranchScheduleInitialized extends AddBranchDraftEvent {
  const _AddBranchScheduleInitialized(this.schedule);

  final List<BranchAvailabilityEntity> schedule;

  @override
  List<Object?> get props => [schedule];
}

final class _AddBranchCompanyHasWorkingHoursSet extends AddBranchDraftEvent {
  const _AddBranchCompanyHasWorkingHoursSet({required this.hasHours});

  final bool hasHours;

  @override
  List<Object?> get props => [hasHours];
}

final class _AddBranchScheduleSlotApplied extends AddBranchDraftEvent {
  const _AddBranchScheduleSlotApplied({
    required this.dayId,
    required this.from,
    required this.to,
    required this.updatedDays,
    required this.validation,
  });

  final String dayId;
  final String from;
  final String to;
  final List<BranchAvailabilityEntity> updatedDays;
  final SlotValidation validation;

  @override
  List<Object?> get props => [dayId, from, to, updatedDays, validation];
}

final class _AddBranchScheduleSlotRemoved extends AddBranchDraftEvent {
  const _AddBranchScheduleSlotRemoved({
    required this.dayId,
    required this.slotIndex,
  });

  final String dayId;
  final int slotIndex;

  @override
  List<Object?> get props => [dayId, slotIndex];
}

final class _AddBranchScheduleRejectionDismissed extends AddBranchDraftEvent {
  const _AddBranchScheduleRejectionDismissed();
}

final class _AddBranchCoverageUpdated extends AddBranchDraftEvent {
  const _AddBranchCoverageUpdated({
    required this.address,
    required this.position,
    required this.radiusKm,
    required this.servingAreas,
    this.placeId,
  });

  final String? address;
  final LatLng? position;
  final double? radiusKm;
  final List<ServingArea> servingAreas;
  final String? placeId;

  @override
  List<Object?> get props => [
    address,
    position,
    radiusKm,
    servingAreas,
    placeId,
  ];
}

final class _AddBranchServicesChanged extends AddBranchDraftEvent {
  const _AddBranchServicesChanged(this.services);

  final List<CatalogServiceSelection> services;

  @override
  List<Object?> get props => [services];
}

final class _AddBranchServiceRemoved extends AddBranchDraftEvent {
  const _AddBranchServiceRemoved(this.service);

  final CatalogServiceSelection service;

  @override
  List<Object?> get props => [service];
}

final class _AddBranchWorkersChanged extends AddBranchDraftEvent {
  const _AddBranchWorkersChanged(this.workers);

  final List<WorkerEntity> workers;

  @override
  List<Object?> get props => [workers];
}

final class _AddBranchWorkerRemoved extends AddBranchDraftEvent {
  const _AddBranchWorkerRemoved(this.worker);

  final WorkerEntity worker;

  @override
  List<Object?> get props => [worker];
}
