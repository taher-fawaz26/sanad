import 'package:equatable/equatable.dart';

class BranchTimeSlotEntity extends Equatable {
  const BranchTimeSlotEntity({required this.from, required this.to});

  final String from;
  final String to;

  @override
  List<Object?> get props => [from, to];
}
