import 'package:equatable/equatable.dart';

/// Minimal branch reference used for the Add/Edit Member branch picker.
///
/// Kept intentionally separate from the `branches` package's `BranchEntity`
/// to avoid a circular package dependency (branches already depends on
/// workers for its worker-selection step).
class BranchOptionEntity extends Equatable {
  const BranchOptionEntity({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
