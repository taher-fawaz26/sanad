import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:maps/maps.dart';

/// Immutable snapshot of step-1 form values, collected before advancing to
/// step 2.  Used by the submit helper to build [CreateBranchParams].
class StepOneData {
  const StepOneData({
    required this.branchName,
    required this.city,
    required this.phone,
    required this.branchAddress,
    required this.pickedPosition,
    required this.managerId,
    required this.isCustomSchedule,
    required this.schedule,
  });

  final String branchName;
  final String city;
  final String phone;
  final String? branchAddress;
  final LatLng? pickedPosition;
  final String? managerId;
  final bool isCustomSchedule;
  final List<BranchAvailabilityEntity> schedule;
}
