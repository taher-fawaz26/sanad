import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/presentation/models/step_one_data.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

/// Builds [CreateBranchParams] from the collected wizard data.
///
/// Coverage-area values ([branchAddress], [pickedPosition]) override the
/// step-one originals when the user refined them on the coverage screen.
CreateBranchParams buildCreateBranchParams({
  required StepOneData stepOne,
  String? branchAddress,
  LatLng? pickedPosition,
  double? coverageRadiusKm,
  List<ServingArea> servingAreas = const [],
  List<ServiceEntity> selectedServices = const [],
  List<WorkerEntity> selectedWorkers = const [],
}) {
  final address = branchAddress ?? stepOne.branchAddress ?? '';
  final position = pickedPosition ?? stepOne.pickedPosition;

  return CreateBranchParams(
    branchName: stepOne.branchName,
    branchAddress: address,
    city: stepOne.city,
    branchPhone: stepOne.phone,
    branchManagerId: stepOne.managerId,
    lat: position?.latitude,
    lng: position?.longitude,
    radiusKm: coverageRadiusKm,
    availabilityMode: stepOne.isCustomSchedule
        ? BranchAvailabilityMode.custom
        : BranchAvailabilityMode.coreHours,
    availability: stepOne.schedule,
    servingAreaPlaceIds: servingAreas.isNotEmpty
        ? servingAreas.map((a) => a.placeId).toList(growable: false)
        : null,
    serviceIds: selectedServices.isNotEmpty
        ? selectedServices.map((s) => s.id).toList(growable: false)
        : null,
    workerIds: selectedWorkers.isNotEmpty
        ? selectedWorkers.map((w) => w.id).toList(growable: false)
        : null,
  );
}
