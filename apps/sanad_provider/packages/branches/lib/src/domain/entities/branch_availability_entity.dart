import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:equatable/equatable.dart';

class BranchAvailabilityEntity extends Equatable {
  const BranchAvailabilityEntity({required this.day, required this.slots});

  final String day;
  final List<BranchTimeSlotEntity> slots;

  @override
  List<Object?> get props => [day, slots];
}
