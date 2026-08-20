import 'package:app_assets/app_assets.dart';
import 'package:branches/branches.dart'
    show BranchScheduleFormatter, BranchTimeSlotEntity;
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/policies/working_hours_policy.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/cubit/edit_working_hours_cubit.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/working_hours_section.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Shows the working hours edit bottom sheet — Figma `3821:18452`.
///
/// Returns the updated schedule when the user taps Save, or `null` when
/// dismissed without saving.
Future<List<WorkingHoursEditEntry>?> showEditWorkingHoursBottomSheet({
  required BuildContext context,
  List<WorkingHoursEditEntry> initialEntries = const [],
}) {
  return SheetNavigator.push<List<WorkingHoursEditEntry>>(
    context,
    _EditWorkingHoursSheetBody(initialEntries: initialEntries),
  );
}

class _EditWorkingHoursSheetBody extends StatelessWidget {
  const _EditWorkingHoursSheetBody({required this.initialEntries});

  final List<WorkingHoursEditEntry> initialEntries;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditWorkingHoursCubit(initialEntries: initialEntries),
      child: const _EditWorkingHoursSheetView(),
    );
  }
}

Future<void> _openAddDaySheet(BuildContext context) async {
  // Do NOT filter out days that already have a slot — users need to be
  // able to add split shifts on the same day (SAN-568). Multiple entries
  // per day are collapsed back into WorkingHoursDayEntity.slots on save.
  final cubit = context.read<EditWorkingHoursCubit>();
  final result = await SheetNavigator.push<AppAddScheduleDayResult>(
    context,
    AppAddScheduleDaySheet(
      days: WorkingHoursDayIds.all
          .map(
            (day) => AppScheduleDayOption(
              id: day,
              label: BranchScheduleFormatter.localizedDay(day),
            ),
          )
          .toList(),
      dayLabel: 'branches.add_branch.day_label'.tr(),
      fromLabel: 'branches.add_branch.from_label'.tr(),
      toLabel: 'branches.add_branch.to_label'.tr(),
      confirmLabel: 'branches.add_branch.add_day_button'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      onPickDay: (context, days, selected, onDaySelected) {
        SheetNavigator.push<void>(
          context,
          AppActionList(
            items: days
                .map(
                  (day) => AppActionSheetItem(
                    label: day.label,
                    onTap: () => onDaySelected(day),
                  ),
                )
                .toList(),
          ),
          settings: SheetRouteSettings(
            title: 'branches.add_branch.day_label'.tr(),
            padChild: false,
          ),
        );
      },
    ),
    settings: SheetRouteSettings(
      title: 'branches.add_branch.add_custom_day_title'.tr(),
    ),
  );

  if (result == null || !context.mounted) return;
  // Cubit.add() consults WorkingHoursPolicy — the same source of truth used
  // at save time. On rejection the draft is left untouched and the sheet's
  // inline error surface renders a localized message next to the "Add a
  // Day" button, so the user sees the conflict immediately (SAN-573) rather
  // than only at Save.
  cubit.add(
    WorkingHoursEditEntry(dayId: result.day, from: result.from, to: result.to),
  );
}

/// Localized inline error for a rejected add-slot attempt, formatted from
/// [SlotRejection] and rendered under the "Add a Day" button.
String _rejectionMessage(BuildContext context, SlotRejection rejection) {
  switch (rejection.reason) {
    case SlotValidationReason.overlapsExisting:
      final conflict = rejection.conflict;
      if (conflict == null) {
        return 'settings.working_hours_invalid_times_error'.tr();
      }
      final locale = context.locale.toString();
      return 'settings.working_hours_overlap_error'.tr(
        namedArgs: {
          'day': BranchScheduleFormatter.localizedDay(rejection.dayId),
          'from': BranchScheduleFormatter.formatTime(
            conflict.from,
            locale: locale,
          ),
          'to': BranchScheduleFormatter.formatTime(
            conflict.to,
            locale: locale,
          ),
        },
      );
    case SlotValidationReason.endBeforeOrEqualStart:
    case SlotValidationReason.malformed:
      return 'settings.working_hours_invalid_times_error'.tr();
    case SlotValidationReason.valid:
      return '';
  }
}

class _EditWorkingHoursSheetView extends StatelessWidget {
  const _EditWorkingHoursSheetView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: 'settings.section_working_hours'.tr()),
          SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: ShapeDecoration(
              color: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: BlocBuilder<EditWorkingHoursCubit, EditWorkingHoursDraft>(
              builder: (context, draft) {
                final localeName = context.locale.toString();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.md,
                  children: [
                    for (final (index, entry) in draft.entries.indexed)
                      AppScheduleDayRow(
                        title: BranchScheduleFormatter.localizedDay(
                          entry.dayId,
                        ),
                        value: BranchScheduleFormatter.formatSlot(
                          BranchTimeSlotEntity(
                            from: entry.from,
                            to: entry.to,
                          ),
                          locale: localeName,
                        ),
                        onDelete: () => context
                            .read<EditWorkingHoursCubit>()
                            .removeAt(index),
                      ),
                    AppButtonPresets.outline(
                      label: 'settings.add_day'.tr(),
                      size: AppButtonSize.block,
                      icon: const Icon(Icons.add),
                      iconPosition: AppButtonIconPosition.center,
                      onPressed: () => _openAddDaySheet(context),
                    ),
                    if (draft.lastRejection != null)
                      _RejectionBanner(rejection: draft.lastRejection!),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'common.save'.tr(),
            onPressed: () => Navigator.of(context).pop(
              List<WorkingHoursEditEntry>.of(
                context.read<EditWorkingHoursCubit>().state.entries,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error surface for a rejected add-slot attempt. Shown below the
/// "Add a Day" button — replaces the previous save-time-only English error
/// (SAN-573).
class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({required this.rejection});

  final SlotRejection rejection;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    return Text(
      _rejectionMessage(context, rejection),
      style: typography.smallNormal.copyWith(color: colors.error),
      textAlign: TextAlign.start,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          AppSvgs.tools,
          width: AppDimension.iconMenu,
          height: AppDimension.iconMenu,
          colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: typography.title3.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
