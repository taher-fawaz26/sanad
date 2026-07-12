import 'package:equatable/equatable.dart';

class BranchManagerEntity extends Equatable {
  const BranchManagerEntity({
    required this.id,
    required this.fullName,
    required this.initials,
  });

  final String id;
  final String fullName;
  final String initials;

  @override
  List<Object?> get props => [id, fullName, initials];
}
