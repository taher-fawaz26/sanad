import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

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
  final double? coverageRadiusKm;
  final List<ServingArea> servingAreas;
  final List<ServiceEntity> selectedServices;
  final List<WorkerEntity> selectedWorkers;

  bool get isStepOneComplete =>
      branchName.trim().isNotEmpty &&
      selectedCity != null &&
      phone.trim().isNotEmpty &&
      branchAddress != null &&
      pickedPosition != null &&
      selectedManager != null;

  bool get isStepTwoComplete =>
      coverageRadiusKm != null &&
      branchAddress != null &&
      branchAddress!.isNotEmpty;

  bool get isStepThreeComplete => selectedServices.isNotEmpty;

  bool get isStepFourComplete => selectedWorkers.isNotEmpty;

  /// True when the user has entered any wizard data.
  bool get isDirty => this != const AddBranchDraft();

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
    double? Function()? coverageRadiusKm,
    List<ServingArea>? servingAreas,
    List<ServiceEntity>? selectedServices,
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
    coverageRadiusKm,
    servingAreas,
    selectedServices,
    selectedWorkers,
  ];
}
