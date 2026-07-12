import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:shared_widgets/shared_widgets.dart';

enum _BranchFilter { all, maintenance, active }

enum _BranchStatus { active, maintenance }

class _BranchItem {
  const _BranchItem({
    required this.name,
    required this.subtitle,
    required this.initial,
    required this.avatarColor,
    required this.status,
  });

  final String name;
  final String subtitle;
  final String initial;
  final Color avatarColor;
  final _BranchStatus status;
}

/// Figma Branches screen (`73:2902`).
class ProviderBranchesPage extends StatefulWidget {
  const ProviderBranchesPage({super.key});

  @override
  State<ProviderBranchesPage> createState() => _ProviderBranchesPageState();
}

class _ProviderBranchesPageState extends State<ProviderBranchesPage> {
  static const _mockBranches = [
    _BranchItem(
      name: 'Dubai Marina',
      subtitle: 'Main Branch',
      initial: 'D',
      avatarColor: Color(0xFF5C6C75),
      status: _BranchStatus.active,
    ),
    _BranchItem(
      name: 'Abu Dhabi Central',
      subtitle: 'Main Branch',
      initial: 'A',
      avatarColor: Color(0xFFECA100),
      status: _BranchStatus.maintenance,
    ),
    _BranchItem(
      name: 'Sharjah Industrial',
      subtitle: 'Secondary Branch',
      initial: 'S',
      avatarColor: Color(0xFF26A68C),
      status: _BranchStatus.active,
    ),
  ];

  int _segmentIndex = 0;
  _BranchFilter _filter = _BranchFilter.all;
  String _searchQuery = '';

  List<_BranchItem> get _filteredBranches {
    return _mockBranches.where((branch) {
      final matchesSearch = branch.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesFilter = switch (_filter) {
        _BranchFilter.all => true,
        _BranchFilter.maintenance => branch.status == _BranchStatus.maintenance,
        _BranchFilter.active => branch.status == _BranchStatus.active,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTableRow(
              title: 'branches.company_name'.tr(),
              trailing: AppTableTrailing.icon,
              leading: AppTableLeading.avatar,
              // trailingText: 'branches.count_label'.tr(),
              leadingAvatar: const AppAvatar(
                initials: 'G',
                backgroundColor: Color(0xFF5C6C75),
                showStatusDot: true,
              ),
              trailingIcon: AppNotificationIcon(
                hasUnread: true,
                onTap: () {},
              ),
            ),
            AppSection(
              title: 'branches.title'.tr(),
              caption: 'branches.subtitle'.tr(),
              size: AppSectionSize.large,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: AppSegmentedControl(
                segments: [
                  'branches.tab_branches'.tr(),
                  'branches.tab_company_profile'.tr(),
                ],
                selectedIndex: _segmentIndex,
                onChanged: (index) => setState(() => _segmentIndex = index),
              ),
            ),

            Expanded(
              child: _segmentIndex == 0
                  ? _buildBranchesTab(context)
                  : _buildCompanyProfilePlaceholder(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyProfilePlaceholder(BuildContext context) {
    return Center(
      child: Text(
        'branches.company_profile_placeholder'.tr(),
        style: context.appTypography.regularNormal.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBranchesTab(BuildContext context) {
    final branches = _filteredBranches;

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        AppSection(
          title: 'branches.count_label'.tr(),
          size: AppSectionSize.compact,
          trailing: AppSectionTrailing.custom,
          trailingWidget: AppNotificationBadge(count: _mockBranches.length),
        ),
        SizedBox(height: AppSpacing.xs),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: AppButton(
            label: 'branches.add_button'.tr(),
            icon: const Icon(Icons.add_circle_outline),
            iconPosition: AppButtonIconPosition.center,
            onPressed: () => context.push(AppRoutes.addBranch),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: AppSearchField(
            hint: 'branches.search_hint'.tr(),
            showMicIcon: false,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'branches.filter_all'.tr(),
                  size: AppButtonSize.small,
                  type: _filter == _BranchFilter.all
                      ? AppButtonType.secondary
                      : AppButtonType.outline,
                  onPressed: () => setState(() => _filter = _BranchFilter.all),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'branches.filter_maintenance'.tr(),
                  size: AppButtonSize.small,
                  type: _filter == _BranchFilter.maintenance
                      ? AppButtonType.secondary
                      : AppButtonType.outline,
                  onPressed: () =>
                      setState(() => _filter = _BranchFilter.maintenance),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'branches.filter_active'.tr(),
                  size: AppButtonSize.small,
                  type: _filter == _BranchFilter.active
                      ? AppButtonType.secondary
                      : AppButtonType.outline,
                  onPressed: () =>
                      setState(() => _filter = _BranchFilter.active),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ...branches.map(
          (branch) => Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: AppListCard(
              title: branch.name,
              caption: branch.subtitle,
              leading: AppAvatar(
                initials: branch.initial,
                backgroundColor: branch.avatarColor,
                showStatusDot: true,
              ),
              badge: AppStatusBadge(
                label: branch.status == _BranchStatus.active
                    ? 'branches.status_active'.tr()
                    : 'branches.status_maintenance'.tr(),
                type: branch.status == _BranchStatus.active
                    ? AppStatusBadgeType.success
                    : AppStatusBadgeType.warning,
                size: AppStatusBadgeSize.compact,
              ),
              trailing: AppIconButton(
                icon: Icons.more_vert,
                size: AppIconButtonSize.small,
                iconColor: context.appColors.textPrimary,
                onTap: () {},
              ),
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}
