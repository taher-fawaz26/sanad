import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/presentation/utils/branch_schedule_formatter.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Branch schedule row — delegates to [AppScheduleDayRow].
class BranchScheduleDayRow extends StatelessWidget {
  const BranchScheduleDayRow({
    required this.availability,
    super.key,
    this.onDelete,
  });

  final BranchAvailabilityEntity availability;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppScheduleDayRow(
      title: BranchScheduleFormatter.localizedDay(availability.day),
      value: BranchScheduleFormatter.formatAvailability(availability),
      onDelete: onDelete,
    );
  }
}
