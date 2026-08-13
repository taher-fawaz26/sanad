import 'package:app_assets/app_assets.dart';
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
            name: 'Disabled',
            builder: (context) => const AppButton(
              label: 'Confirm',
              onPressed: null,
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
