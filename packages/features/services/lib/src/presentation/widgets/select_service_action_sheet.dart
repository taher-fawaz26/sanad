import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:services/src/domain/usecases/get_services_usecase.dart';

/// Result returned when the user confirms service selection.
class SelectServiceResult {
  const SelectServiceResult({required this.selectedServices});

  final List<ServiceEntity> selectedServices;
}

/// Figma `assign service` action sheet (`251:7195`).
///
/// Loads services from [GetServicesUseCase], supports multi-select with search,
/// and returns the confirmed selection.
Future<SelectServiceResult?> showSelectServiceActionSheet({
  required BuildContext context,
  Set<String> initialSelectedIds = const {},
}) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final brightness = Theme.of(context).brightness;
  final spec = ActionSheetTokens.resolve(
    colors: colors,
    typography: typography,
    brightness: brightness,
  );

  return showModalBottomSheet<SelectServiceResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: spec.barrierColor,
    builder: (context) => _SelectServiceActionSheet(
      initialSelectedIds: initialSelectedIds,
    ),
  );
}

class _SelectServiceActionSheet extends StatefulWidget {
  const _SelectServiceActionSheet({required this.initialSelectedIds});

  final Set<String> initialSelectedIds;

  @override
  State<_SelectServiceActionSheet> createState() =>
      _SelectServiceActionSheetState();
}

class _SelectServiceActionSheetState extends State<_SelectServiceActionSheet> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};

  List<ServiceEntity> _services = const [];
  String _query = '';
  bool _isLoading = true;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await sl<GetServicesUseCase>()(const NoParams()).run();

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _failure = failure;
      }),
      (services) => setState(() {
        _isLoading = false;
        _services = services;
      }),
    );
  }

  List<ServiceEntity> get _filteredServices {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _services;
    return _services
        .where(
          (service) =>
              service.name.toLowerCase().contains(query) ||
              service.category.toLowerCase().contains(query),
        )
        .toList();
  }

  void _toggleService(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    final selected = _services
        .where((service) => _selectedIds.contains(service.id))
        .toList();
    Navigator.of(context).pop(SelectServiceResult(selectedServices: selected));
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

    return AppActionSheet(
      title: 'services.select_service.title'.tr(),
      showCancel: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: AppSearchField(
              controller: _searchController,
              hint: 'services.select_service.search_hint'.tr(),
              showMicIcon: false,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _buildListBody(),
          ),
        ],
      ),
      footer: AppButton(
        label: 'services.select_service.confirm'.tr(),
        onPressed: _selectedIds.isEmpty ? null : _confirm,
      ),
    );
  }

  Widget _buildListBody() {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_failure != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _failure!.message,
                textAlign: TextAlign.center,
                style: context.appTypography.regularNormal.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              AppButtonPresets.outline(
                label: 'services.select_service.retry'.tr(),
                onPressed: _loadServices,
              ),
            ],
          ),
        ),
      );
    }

    final services = _filteredServices;
    if (services.isEmpty) {
      return Center(
        child: Text(
          'services.select_service.empty'.tr(),
          style: context.appTypography.regularNormal.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: services.length,
      separatorBuilder: (_, __) => const AppDivider(),
      itemBuilder: (context, index) {
        final service = services[index];
        final isSelected = _selectedIds.contains(service.id);

        return AppTableRow(
          title: service.name,
          trailing: AppTableTrailing.icon,
          trailingIcon: AppCheckbox(
            value: isSelected,
            onChanged: (_) => _toggleService(service.id),
          ),
          onTap: () => _toggleService(service.id),
        );
      },
    );
  }
}
