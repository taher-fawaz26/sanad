import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
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
            ],
          ),
          WidgetbookComponent(
            name: 'AppPhoneField',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => const AppPhoneField(label: 'Phone'),
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
            name: 'AppListCard',
            useCases: [
              WidgetbookUseCase(
                name: 'Default',
                builder: (context) => AppListCard(
                  title: 'Branch name',
                  caption: 'Dubai Marina',
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
          WidgetbookComponent(
            name: 'AppBottomNavBar',
            useCases: [
              WidgetbookUseCase(
                name: 'Two tabs',
                builder: (context) => AppBottomNavBar(
                  currentIndex: 0,
                  onTap: (_) {},
                  items: const [
                    AppBottomNavItem(
                      iconAsset: AppSvgs.navHome,
                      label: 'Home',
                    ),
                    AppBottomNavItem(
                      iconAsset: AppSvgs.navSettings,
                      label: 'Settings',
                    ),
                  ],
                ),
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
