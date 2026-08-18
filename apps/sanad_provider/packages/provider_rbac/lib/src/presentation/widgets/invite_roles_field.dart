import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/policies/role_assignment_policy.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';
import 'package:provider_rbac/src/presentation/widgets/select_roles_action_sheet.dart';
import 'package:workers/workers.dart';

/// Mandatory "Roles" field for the Add Member form.
///
/// Loads the role catalog directly via [getRolesUseCase] (no bloc — this is
/// a single picker, matching how `AppSelectSheet.loadItems` fetches its own
/// data elsewhere) and resolves the mandatory baseline role for [type]
/// through [RoleAssignmentPolicy]. The use case is injected rather than
/// pulled from the service locator internally, so this widget stays testable
/// with a fake without needing DI setup.
class InviteRolesField extends StatefulWidget {
  const InviteRolesField({
    required this.type,
    required this.onChanged,
    required this.getRolesUseCase,
    super.key,
    this.initialRoleIds = const [],
  });

  final WorkerType type;
  final ValueChanged<InviteRolesSelection> onChanged;
  final GetRolesUseCase getRolesUseCase;
  final List<String> initialRoleIds;

  @override
  State<InviteRolesField> createState() => _InviteRolesFieldState();
}

class _InviteRolesFieldState extends State<InviteRolesField> {
  RequestStatus _catalogStatus = RequestStatus.loading;
  List<RoleEntity> _catalog = const [];
  List<RoleEntity> _selected = const [];
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant InviteRolesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type &&
        _catalogStatus == RequestStatus.success) {
      // Deferred to a microtask: this fires from the parent's build pass
      // (the `type` dropdown changed), so calling `setState`/`onChanged`
      // synchronously here would reach back into a widget tree still mid
      // rebuild.
      Future.microtask(() {
        if (!mounted) return;
        final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
          widget.type,
          _selected,
          _catalog,
        );
        setState(() => _selected = normalized);
        _emit();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _catalogStatus = RequestStatus.loading;
      _failure = null;
    });

    final result = await widget.getRolesUseCase(const RolesQuery(limit: 100))
        .run();
    if (!mounted) return;

    result.match(
      (failure) {
        setState(() {
          _catalogStatus = RequestStatus.failure;
          _failure = failure;
        });
        widget.onChanged(
          const InviteRolesSelection(roleIds: [], isValid: false),
        );
      },
      (page) {
        final catalog = page.items;
        final restored = widget.initialRoleIds.isEmpty
            ? const <RoleEntity>[]
            : catalog
                  .where((role) => widget.initialRoleIds.contains(role.id))
                  .toList();
        final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
          widget.type,
          restored,
          catalog,
        );
        setState(() {
          _catalogStatus = RequestStatus.success;
          _catalog = catalog;
          _selected = normalized;
        });
        _emit();
      },
    );
  }

  void _emit() {
    final required = RoleAssignmentPolicy.requiredRoleFor(
      widget.type,
      _catalog,
    );
    widget.onChanged(
      InviteRolesSelection(
        roleIds: _selected.map((role) => role.id).toList(),
        isValid: required != null,
      ),
    );
  }

  Future<void> _openSheet() async {
    final required = RoleAssignmentPolicy.requiredRoleFor(
      widget.type,
      _catalog,
    );
    final result = await showSelectRolesActionSheet(
      context: context,
      loadItems: () async => _catalog,
      initialSelectedIds: _selected.map((role) => role.id).toSet(),
      mandatoryRoleId: required?.id,
    );
    if (result == null || !mounted) return;
    setState(() => _selected = result);
    _emit();
  }

  void _removeRole(RoleEntity role) {
    if (!RoleAssignmentPolicy.canRemove(role, widget.type)) return;
    setState(
      () => _selected = _selected.where((r) => r.id != role.id).toList(),
    );
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final required = RoleAssignmentPolicy.requiredRoleFor(
      widget.type,
      _catalog,
    );
    final isLoading = _catalogStatus == RequestStatus.loading;
    final hasFailed = _catalogStatus == RequestStatus.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField(
          label: 'workers.add_worker.roles_label'.tr(),
          hint: 'workers.add_worker.roles_hint'.tr(),
          isRequired: true,
          enabled: !isLoading && !hasFailed,
          onTap: _openSheet,
        ),
        if (isLoading) ...[
          SizedBox(height: AppSpacing.sm),
          const AppLoadingIndicator(),
        ],
        if (hasFailed) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            _failure?.localizedMessage() ?? '',
            style: context.appTypography.smallNormal.copyWith(
              color: context.appColors.error,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          AppButtonPresets.outline(
            label: 'common.retry'.tr(),
            onPressed: _load,
          ),
        ],
        if (_selected.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final role in _selected)
                RoleAssignmentPolicy.isMandatory(role, widget.type)
                    ? AppChip(
                        label: role.displayName,
                        selected: true,
                        tone: AppChipTone.softNeutral,
                        icon: const Icon(Icons.lock_outline, size: 14),
                        iconPosition: AppChipIconPosition.left,
                      )
                    : AppChip(
                        label: role.displayName,
                        selected: true,
                        tone: AppChipTone.softSuccess,
                        icon: const Icon(Icons.close, size: 14),
                        iconPosition: AppChipIconPosition.right,
                        onTap: () => _removeRole(role),
                      ),
            ],
          ),
        ],
        if (required != null) ...[
          SizedBox(height: AppSpacing.md),
          AppAlert(
            type: AppAlertType.warning,
            message: 'workers.add_worker.role_locked_hint'.tr(
              namedArgs: {'role': required.displayName},
            ),
          ),
        ],
      ],
    );
  }
}
