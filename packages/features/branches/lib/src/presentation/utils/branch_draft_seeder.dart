import 'package:branches/src/data/models/person_initials.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/worker_status.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart' as workers;

/// Builds an [AddBranchDraft] from a loaded [BranchEntity] so the shared wizard
/// opens fully prefilled in edit mode.
///
/// Every field comes from the single GET `/branches/{id}` payload — no extra
/// lookups. Service/worker entities are reconstructed with the identifiers and
/// display names the payload provides (e.g. [ServiceEntity.category] is left
/// empty); the selection sheets re-hydrate full entities by id when opened, and
/// only ids are submitted on save.
abstract final class BranchDraftSeeder {
  static AddBranchDraft fromBranch(BranchEntity branch) {
    final position = (branch.lat != null && branch.lng != null)
        ? LatLng(branch.lat!, branch.lng!)
        : null;

    final city = branch.cityId != null
        ? CityEntity(
            id: branch.cityId!,
            nameEn: branch.city,
            nameAr: branch.cityNameAr ?? branch.city,
          )
        : null;

    final manager = branch.branchManagerId != null
        ? BranchManagerEntity(
            id: branch.branchManagerId!,
            fullName: branch.branchManagerName ?? '',
            initials: personInitials(branch.branchManagerName ?? ''),
          )
        : null;

    final isCustom = branch.availabilityMode == BranchAvailabilityMode.custom;

    return AddBranchDraft(
      branchName: branch.branchName,
      branchType: branch.branchType,
      selectedCity: city,
      phone: branch.branchPhone,
      branchAddress: branch.branchAddress,
      pickedPosition: position,
      selectedManager: manager,
      scheduleMode: isCustom
          ? BranchScheduleMode.custom
          : BranchScheduleMode.company,
      // The branch carries its own saved availability. When it runs on company
      // (core) hours the custom editor stays empty until the user opts in, at
      // which point it is seeded from the company schedule (as in create).
      customSchedule: branch.availability ?? const [],
      coverageRadiusKm: branch.radiusKm,
      servingAreas: branch.servingAreas,
      selectedServices: _services(branch),
      selectedWorkers: _workers(branch),
    );
  }

  static List<ServiceEntity> _services(BranchEntity branch) {
    final ids = branch.serviceIds ?? const [];
    final names = branch.serviceNames ?? const [];
    return [
      for (var i = 0; i < ids.length; i++)
        ServiceEntity(
          id: ids[i],
          name: i < names.length ? names[i] : '',
          category: '',
        ),
    ];
  }

  static List<workers.WorkerEntity> _workers(BranchEntity branch) =>
      branch.workers
          .map(
            (w) => workers.WorkerEntity(
              id: w.id,
              fullName: w.fullName,
              role: w.type.toApiString(),
              initials: w.initials,
              status: w.status == WorkerStatus.active
                  ? workers.WorkerStatus.active
                  : workers.WorkerStatus.inactive,
            ),
          )
          .toList();
}
