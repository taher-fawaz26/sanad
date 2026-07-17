import 'package:branches/src/domain/entities/branch_availability_entity.dart';
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
    this.city = '',
    this.phone = '',
    this.branchAddress,
    this.pickedPosition,
    this.selectedManagerId,
    this.scheduleMode = BranchScheduleMode.company,
    this.customSchedule = const [],
    this.coverageRadiusKm,
    this.servingAreas = const [],
    this.selectedServices = const [],
    this.selectedWorkers = const [],
  });

  final String branchName;
  final BranchType branchType;
  final String city;
  final String phone;
  final String? branchAddress;
  final LatLng? pickedPosition;
  final String? selectedManagerId;
  final BranchScheduleMode scheduleMode;
  final List<BranchAvailabilityEntity> customSchedule;
  final double? coverageRadiusKm;
  final List<ServingArea> servingAreas;
  final List<ServiceEntity> selectedServices;
  final List<WorkerEntity> selectedWorkers;

  bool get isStepOneComplete =>
      branchName.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      branchAddress != null &&
      pickedPosition != null &&
      selectedManagerId != null;

  bool get isStepTwoComplete =>
      coverageRadiusKm != null &&
      branchAddress != null &&
      branchAddress!.isNotEmpty;

  bool get isStepThreeComplete => selectedServices.isNotEmpty;

  bool get isStepFourComplete => selectedWorkers.isNotEmpty;

  AddBranchDraft copyWith({
    String? branchName,
    BranchType? branchType,
    String? city,
    String? phone,
    String? Function()? branchAddress,
    LatLng? Function()? pickedPosition,
    String? Function()? selectedManagerId,
    BranchScheduleMode? scheduleMode,
    List<BranchAvailabilityEntity>? customSchedule,
    double? Function()? coverageRadiusKm,
    List<ServingArea>? servingAreas,
    List<ServiceEntity>? selectedServices,
    List<WorkerEntity>? selectedWorkers,
  }) =>
      AddBranchDraft(
        branchName: branchName ?? this.branchName,
        branchType: branchType ?? this.branchType,
        city: city ?? this.city,
        phone: phone ?? this.phone,
        branchAddress:
            branchAddress != null ? branchAddress() : this.branchAddress,
        pickedPosition:
            pickedPosition != null ? pickedPosition() : this.pickedPosition,
        selectedManagerId: selectedManagerId != null
            ? selectedManagerId()
            : this.selectedManagerId,
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
        city,
        phone,
        branchAddress,
        pickedPosition,
        selectedManagerId,
        scheduleMode,
        customSchedule,
        coverageRadiusKm,
        servingAreas,
        selectedServices,
        selectedWorkers,
      ];
}
