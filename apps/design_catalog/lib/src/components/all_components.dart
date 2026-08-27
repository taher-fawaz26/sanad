import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_catalog/src/components/motion_state_transition_demo.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:widgetbook/widgetbook.dart';

/// All design_system component catalog entries.
List<WidgetbookNode> buildCatalogDirectories() => [
  WidgetbookCategory(
    name: 'Buttons',
    children: [
      WidgetbookComponent(
        name: 'AppButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Primary',
            builder: (context) => const AppButton(
              label: 'Confirm',
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Secondary',
            builder: (context) => const AppButton(
              label: 'Confirm',
              variant: AppButtonVariant.secondary,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Outline',
            builder: (context) => const AppButton(
              label: 'Confirm',
              variant: AppButtonVariant.outline,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Transparent',
            builder: (context) => const AppButton(
              label: 'Confirm',
              variant: AppButtonVariant.transparent,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Warning',
            builder: (context) => const AppButton(
              label: 'Suspend',
              intent: AppButtonIntent.warning,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Destructive',
            builder: (context) => const AppButton(
              label: 'Delete',
              intent: AppButtonIntent.destructive,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Outline + Destructive',
            builder: (context) => const AppButton(
              label: 'Delete',
              variant: AppButtonVariant.outline,
              intent: AppButtonIntent.destructive,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Loading',
            builder: (context) => const AppButton(
              label: 'Confirm',
              isLoading: true,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Disabled',
            builder: (context) => const AppButton(
              label: 'Confirm',
              onPressed: null,
            ),
          ),
          WidgetbookUseCase(
            name: 'Small',
            builder: (context) => const AppButton(
              label: 'Confirm',
              size: AppButtonSize.small,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Large',
            builder: (context) => const AppButton(
              label: 'Confirm',
              size: AppButtonSize.large,
              onPressed: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Icon + label',
            builder: (context) => const AppButton(
              label: 'Confirm',
              icon: Icon(Icons.check),
              iconPosition: AppButtonIconPosition.left,
              onPressed: _noop,
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppIconButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => AppIconButton(
              icon: Icons.add,
              onTap: _noop,
              semanticLabel: 'Add',
            ),
          ),
          WidgetbookUseCase(
            name: 'Destructive',
            builder: (context) => AppIconButton(
              icon: Icons.delete_outline,
              size: AppIconButtonSize.large,
              intent: AppButtonIntent.destructive,
              onTap: _noop,
              semanticLabel: 'Delete',
            ),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Fields',
    children: [
      WidgetbookComponent(
        name: 'AppTextField',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppTextField(
              label: 'Email',
              hint: 'you@example.com',
            ),
          ),
          WidgetbookUseCase(
            name: 'Required',
            builder: (context) => const AppTextField(
              label: 'Email',
              hint: 'you@example.com',
              isRequired: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'Trailing Add pill',
            builder: (context) => AppTextField(
              label: 'Email Address',
              hint: 'Email Address',
              isRequired: true,
              readOnly: true,
              trailing: AppFieldOutlinePillTrailing(
                label: 'Add',
                onTap: () {},
              ),
            ),
          ),
          WidgetbookUseCase(
            name: 'Trailing Change link',
            builder: (context) => AppTextField(
              label: 'Email Address',
              hint: 'Email Address',
              readOnly: true,
              showVerifiedBadge: true,
              controller: TextEditingController(text: 'ops@sanad.ae'),
              trailing: AppFieldTextLinkTrailing(
                label: 'Change',
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppPhoneField',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppPhoneField(label: 'Phone'),
          ),
          WidgetbookUseCase(
            name: 'Required',
            builder: (context) => const AppPhoneField(
              label: 'Phone',
              isRequired: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'Verified + Change',
            builder: (context) => AppPhoneField(
              label: 'Phone Number',
              hint: 'Phone Number',
              isRequired: true,
              readOnly: true,
              showVerifiedBadge: true,
              controller: TextEditingController(text: '501234567'),
              trailing: AppFieldTextLinkTrailing(
                label: 'Change',
                onTap: () {},
              ),
            ),
          ),
          WidgetbookUseCase(
            name: 'Empty + Add',
            builder: (context) => AppPhoneField(
              label: 'Phone Number',
              hint: 'Phone Number',
              isRequired: true,
              readOnly: true,
              trailing: AppFieldOutlinePillTrailing(
                label: 'Add',
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppSearchField',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppSearchField(hint: 'Search'),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppSelectField',
        useCases: [
          WidgetbookUseCase(
            name: 'With value',
            builder: (context) => const AppSelectField(
              label: 'Country',
              value: 'UAE',
            ),
          ),
          WidgetbookUseCase(
            name: 'Required',
            builder: (context) => const AppSelectField(
              label: 'Country',
              value: 'UAE',
              isRequired: true,
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppCheckbox',
        useCases: [
          WidgetbookUseCase(
            name: 'Checked',
            builder: (context) => AppCheckbox(
              value: true,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppRadio',
        useCases: [
          WidgetbookUseCase(
            name: 'Selected',
            builder: (context) => AppRadio<bool>(
              value: true,
              groupValue: true,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppSwitch',
        useCases: [
          WidgetbookUseCase(
            name: 'On',
            builder: (context) => AppSwitch(
              value: true,
              onChanged: (_) {},
            ),
          ),
          WidgetbookUseCase(
            name: 'Loading',
            builder: (context) => AppSwitch(
              value: true,
              onChanged: (_) {},
              loading: true,
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppSlider',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => AppSlider(
              value: 0.5,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Cards & Layout',
    children: [
      WidgetbookComponent(
        name: 'AppEntityListItem',
        useCases: [
          WidgetbookUseCase(
            name: 'Branch (compact)',
            builder: (context) => AppEntityListItem(
              style: AppEntityListItemStyle.compact,
              title: 'Dubai Marina',
              caption: 'Main Branch',
              leading: AppAvatar(
                initials: 'D',
                backgroundColor: context.appColors.palettes.sky.shade400,
                showStatusDot: true,
              ),
              badge: const AppStatusBadge(
                label: 'Active',
                type: AppStatusBadgeType.success,
                size: AppStatusBadgeSize.compact,
              ),
              trailing: AppIconButton(
                icon: Icons.more_vert,
                onTap: _noop,
                semanticLabel: 'More actions',
              ),
              onTap: _noop,
            ),
          ),
          WidgetbookUseCase(
            name: 'Worker (standard)',
            builder: (context) => AppEntityListItem(
              style: AppEntityListItemStyle.standard,
              title: 'Mohamed Ali',
              caption: 'Worker',
              leading: AppAvatar(
                initials: 'M',
                backgroundColor: context.appColors.primary,
                showStatusDot: true,
              ),
              badge: const AppStatusBadge(
                label: 'Active',
                type: AppStatusBadgeType.success,
                size: AppStatusBadgeSize.dense,
                outlined: true,
              ),
              trailing: AppIconButton(
                icon: Icons.more_vert,
                onTap: _noop,
                semanticLabel: 'More actions',
              ),
              onTap: _noop,
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppKeyValueCard',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppKeyValueCard(
              title: 'Status',
              value: 'Active',
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppSection',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppSection(title: 'Section'),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppDivider',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppDivider(),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Navigation',
    children: [
      WidgetbookComponent(
        name: 'AppNavBar',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppNavBar(title: 'Page title'),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Badges & Chips',
    children: [
      WidgetbookComponent(
        name: 'AppChip',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppChip(label: 'Tag'),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppStatusBadge',
        useCases: [
          WidgetbookUseCase(
            name: 'Success',
            builder: (context) => const AppStatusBadge(
              label: 'Active',
              type: AppStatusBadgeType.success,
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppAvatar',
        useCases: [
          WidgetbookUseCase(
            name: 'Initials',
            builder: (context) => const AppAvatar(initials: 'TA'),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Feedback',
    children: [
      WidgetbookComponent(
        name: 'AppProgressBar',
        useCases: [
          WidgetbookUseCase(
            name: '50%',
            builder: (context) => const AppProgressBar(value: 0.5),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppSnackbar',
        useCases: [
          WidgetbookUseCase(
            name: 'Dark',
            builder: (context) => const AppSnackbar(title: 'Changes saved'),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppStepper',
        useCases: [
          WidgetbookUseCase(
            name: 'Value 2',
            builder: (context) => AppStepper(
              value: 2,
              onIncrement: _noop,
              onDecrement: _noop,
            ),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Shared UI',
    children: [
      WidgetbookComponent(
        name: 'AppEmptyState',
        useCases: [
          WidgetbookUseCase(
            name: 'Generic',
            builder: (context) => AppEmptyState(
              title: 'No items yet',
              description: 'Items will appear here',
              illustration: const AppEmptyStateImage(
                assetPath: AppImages.emptyState,
              ),
              actionLabel: 'Add item',
              onAction: _noop,
            ),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Motion',
    children: [
      WidgetbookComponent(
        name: 'AppMotionDuration / AppMotionCurve',
        useCases: [
          WidgetbookUseCase(
            name: 'Token reference',
            builder: (context) => const _MotionTokenReference(),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppLottie',
        useCases: [
          WidgetbookUseCase(
            name: 'loading (functional)',
            builder: (context) => AppLottie.loading(size: 64),
          ),
          WidgetbookUseCase(
            name: 'documentExtraction (functional)',
            builder: (context) => AppLottie.documentExtraction(size: 160),
          ),
          WidgetbookUseCase(
            name: 'notFound (decorative)',
            builder: (context) => AppLottie.notFound(size: 120),
          ),
          WidgetbookUseCase(
            name: 'forbidden (decorative)',
            builder: (context) => AppLottie.forbidden(size: 120),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppShimmer',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => const AppShimmer(
              child: ShimmerBox(width: 200, height: 24),
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppListEntrance',
        useCases: [
          WidgetbookUseCase(
            name: 'Staggered rows (revisit to replay)',
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppListEntrance(
                      key: ValueKey(i),
                      index: i,
                      child: AppKeyValueCard(
                        title: 'Row ${i + 1}',
                        value: 'Value',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppButtonFeedback',
        useCases: [
          WidgetbookUseCase(
            name: 'Tap-scale feedback',
            builder: (context) => const AppButtonFeedback(
              onTap: _noop,
              child: AppKeyValueCard(
                title: 'Tap me',
                value: 'Scales down while pressed',
              ),
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppStateTransition',
        useCases: [
          WidgetbookUseCase(
            name: 'loading -> success -> error',
            builder: (context) => const MotionStateTransitionDemo(),
          ),
        ],
      ),
    ],
  ),
  WidgetbookCategory(
    name: 'Icons',
    children: [
      WidgetbookComponent(
        name: 'AppCloseIcon',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => AppCloseIcon(onTap: _noop),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'AppNotificationIcon',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => AppNotificationIcon(onTap: _noop),
          ),
        ],
      ),
    ],
  ),
];

void _noop() {}

/// Read-only reference table for the app's motion tokens — lets a designer
/// or reviewer see the whole `AppMotionDuration`/`AppMotionCurve` vocabulary
/// (and its live-usage doc comments) in one place.
class _MotionTokenReference extends StatelessWidget {
  const _MotionTokenReference();

  static const Map<String, Duration> _durations = {
    'instant': AppMotionDuration.instant,
    'fast': AppMotionDuration.fast,
    'quick': AppMotionDuration.quick,
    'normal': AppMotionDuration.normal,
    'emphasis': AppMotionDuration.emphasis,
    'pageTransition': AppMotionDuration.pageTransition,
    'shimmer': AppMotionDuration.shimmer,
  };

  static const Map<String, Curve> _curves = {
    'standard': AppMotionCurve.standard,
    'decelerated': AppMotionCurve.decelerated,
    'accelerated': AppMotionCurve.accelerated,
    'emphasizedDecelerate': AppMotionCurve.emphasizedDecelerate,
    'emphasizedAccelerate': AppMotionCurve.emphasizedAccelerate,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AppMotionDuration', style: context.appTypography.titleSmall),
          for (final entry in _durations.entries)
            Text('${entry.key}: ${entry.value.inMilliseconds}ms'),
          SizedBox(height: AppSpacing.md),
          Text('AppMotionCurve', style: context.appTypography.titleSmall),
          for (final entry in _curves.entries) Text(entry.key),
        ],
      ),
    );
  }
}
