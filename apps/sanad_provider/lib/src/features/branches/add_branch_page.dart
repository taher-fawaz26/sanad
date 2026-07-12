import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/branches/widgets/app_location_field.dart';
import 'package:sanad_provider/src/features/branches/widgets/app_person_select_field.dart';

enum _ScheduleMode { company, custom }

/// Figma Add branch — Step 1 (`194:4056`).
class AddBranchPage extends StatefulWidget {
  /// Creates [AddBranchPage].
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  static const _branchTypes = ['Main branch', 'Secondary branch'];
  static const _managers = ['amr wagdy', 'sara ahmed', 'omar hassan'];
  static const _companySchedule = [
    ('Saturday', '9:00 AM – 6:00 PM'),
    ('Sunday', '9:00 AM – 6:00 PM'),
    ('Monday', '9:00 AM – 6:00 PM'),
  ];

  final _branchNameController = TextEditingController(text: 'Dubai Marina');
  final _phoneController = TextEditingController(text: '+971 4 123 4567');

  String? _branchType = _branchTypes.first;
  String? _location;
  String? _manager = _managers.first;
  _ScheduleMode _scheduleMode = _ScheduleMode.company;

  @override
  void dispose() {
    _branchNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBranchType() async {
    final selected = await _showOptionsSheet(
      title: 'branches.add_branch.branch_type'.tr(),
      options: _branchTypes,
      selected: _branchType,
    );
    if (selected != null) {
      setState(() => _branchType = selected);
    }
  }

  Future<void> _pickManager() async {
    final selected = await _showOptionsSheet(
      title: 'branches.add_branch.branch_manager'.tr(),
      options: _managers,
      selected: _manager,
    );
    if (selected != null) {
      setState(() => _manager = selected);
    }
  }

  Future<String?> _showOptionsSheet({
    required String title,
    required List<String> options,
    required String? selected,
  }) {
    return showAppBottomSheet<String>(
      context: context,
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, _) => const AppDivider(),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          return ListTile(
            title: Text(option),
            trailing: isSelected
                ? Icon(Icons.check, color: context.appColors.primary)
                : null,
            onTap: () => Navigator.of(context).pop(option),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: '',
              leading: AppCloseIcon(onTap: () => context.pop()),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppLargeNavBar(
                      title: 'branches.add_branch.title'.tr(),
                      caption: 'branches.add_branch.subtitle'.tr(),
                      useLargeTitleStyle: false,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: const AppWizardStepIndicator(
                        currentStep: 1,
                        totalSteps: 4,
                      ),
                    ),
                    AppSection(
                      title: 'branches.add_branch.section_main_info'.tr(),
                      size: AppSectionSize.compact,
                      tone: AppSectionTone.primary,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _branchNameController,
                            label: 'branches.add_branch.branch_name'.tr(),
                            hint: 'branches.add_branch.branch_name_hint'.tr(),
                          ),
                          SizedBox(height: AppSpacing.md),
                          AppSelectField(
                            label: 'branches.add_branch.branch_type'.tr(),
                            value: _branchType,
                            hint: 'branches.add_branch.branch_type_hint'.tr(),
                            onTap: _pickBranchType,
                          ),
                          SizedBox(height: AppSpacing.md),
                          AppLocationField(
                            label: 'branches.add_branch.location'.tr(),
                            value: _location,
                            hint: 'branches.add_branch.location_hint'.tr(),
                            actionLabel: 'branches.add_branch.location_set'
                                .tr(),
                            onActionTap: () {
                              setState(() {
                                _location = 'Marina Plaza, Tower 2';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const AppDivider(thickness: AppDividerThickness.thick),
                    AppSection(
                      title: 'branches.add_branch.section_contact'.tr(),
                      size: AppSectionSize.compact,
                      tone: AppSectionTone.primary,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          AppPhoneField(
                            label: 'branches.add_branch.branch_phone'.tr(),
                            controller: _phoneController,
                            hint: 'branches.add_branch.branch_phone_hint'.tr(),
                          ),
                          SizedBox(height: AppSpacing.md),
                          AppPersonSelectField(
                            label: 'branches.add_branch.branch_manager'.tr(),
                            value: _manager,
                            hint: 'branches.add_branch.branch_manager_hint'
                                .tr(),
                            avatar: AppAvatar(
                              initials: _managerInitials(_manager),
                              size: AppAvatarSize.small,
                              backgroundColor: const Color(0xFF5C6C75),
                            ),
                            onTap: _pickManager,
                          ),
                        ],
                      ),
                    ),
                    const AppDivider(thickness: AppDividerThickness.thick),
                    AppSection(
                      title: 'branches.add_branch.section_working_hours'.tr(),
                      size: AppSectionSize.compact,
                      tone: AppSectionTone.primary,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: AppRadioGroup<_ScheduleMode>(
                        value: _scheduleMode,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _scheduleMode = value);
                          }
                        },
                        options: [
                          AppRadioOption(
                            value: _ScheduleMode.company,
                            label: 'branches.add_branch.use_company_schedule'
                                .tr(),
                          ),
                          AppRadioOption(
                            value: _ScheduleMode.custom,
                            label: 'branches.add_branch.set_custom_schedule'
                                .tr(),
                          ),
                        ],
                      ),
                    ),
                    if (_scheduleMode == _ScheduleMode.company)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.md,
                        ),
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < _companySchedule.length;
                              i++
                            ) ...[
                              AppKeyValueCard(
                                title: _companySchedule[i].$1,
                                value: _companySchedule[i].$2,
                              ),
                              if (i < _companySchedule.length - 1)
                                SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: AppButton(
                label: 'branches.add_branch.next_button'.tr(),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _managerInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
