import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/presentation/utils/worker_type_localization.dart';

/// Status + Type filter row for the Team list.
///
/// Both are real, documented server-side params on `GET /workers`
/// (`status`: `active`/`inactive`, `type`: `worker`/`manager` — confirmed
/// against the live API contract) — unlike Services' category filter, there
/// is no client-side fallback here.
///
/// Reuses the shared `AppFilterField` trigger cell (see
/// `packages/shared_ui/lib/src/widgets/app_filter_field.dart`) so this row
/// matches Services' filter row visually — same cell style, spacing, and
/// "opens a single-select sheet" interaction — without either feature
/// knowing about the other's filter values.
class WorkersFilterBar extends StatelessWidget {
  const WorkersFilterBar({
    required this.statusFilter,
    required this.typeFilter,
    required this.onStatusTap,
    required this.onTypeTap,
    super.key,
  });

  final WorkerStatus? statusFilter;
  final WorkerType? typeFilter;
  final VoidCallback onStatusTap;
  final VoidCallback onTypeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppFilterField<WorkerStatus>(
            placeholder: 'workers.filters.status'.tr(),
            options: [
              AppFilterOption(
                value: WorkerStatus.active,
                label: 'workers.filters.active'.tr(),
              ),
              AppFilterOption(
                value: WorkerStatus.inactive,
                label: 'workers.filters.inactive'.tr(),
              ),
            ],
            selectedValue: statusFilter,
            onTap: onStatusTap,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppFilterField<WorkerType>(
            placeholder: 'workers.filters.type'.tr(),
            options: [
              AppFilterOption(
                value: WorkerType.worker,
                label: WorkerType.worker.localizedLabel(),
              ),
              AppFilterOption(
                value: WorkerType.manager,
                label: WorkerType.manager.localizedLabel(),
              ),
            ],
            selectedValue: typeFilter,
            onTap: onTypeTap,
          ),
        ),
      ],
    );
  }
}
