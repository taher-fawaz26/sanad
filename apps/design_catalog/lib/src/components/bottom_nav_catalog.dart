import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';


/// Widgetbook entries for [AppBottomNavBar].
List<WidgetbookNode> buildBottomNavCatalogEntries() => [
      WidgetbookComponent(
        name: 'AppBottomNavBar',
        useCases: [
          WidgetbookUseCase(
            name: 'Light — Home selected',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 0,
              centerSelected: false,
            ),
          ),
          WidgetbookUseCase(
            name: 'Light — Service selected',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 1,
              centerSelected: false,
            ),
          ),
          WidgetbookUseCase(
            name: 'Light — Messages selected',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 3,
              centerSelected: false,
            ),
          ),
          WidgetbookUseCase(
            name: 'Light — Settings selected',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 4,
              centerSelected: false,
            ),
          ),
          WidgetbookUseCase(
            name: 'Center action — selected',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 0,
              centerSelected: true,
            ),
          ),
          WidgetbookUseCase(
            name: 'Center action — disabled',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 0,
              centerEnabled: false,
            ),
          ),
          WidgetbookUseCase(
            name: 'Disabled side tab',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 0,
              disabledTabIndex: 1,
            ),
          ),
          WidgetbookUseCase(
            name: 'Arabic — long labels (RTL)',
            builder: (context) => const BottomNavCatalogDemo(
              currentIndex: 0,
              textDirection: TextDirection.rtl,
              items: _arabicItems,
            ),
          ),
        ],
      ),
    ];

const _defaultItems = [
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.home,
    label: 'Home',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.service,
    label: 'Service',
  ),
  // Index 2 is reserved for center action
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.messages,
    label: 'Messages',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.settings,
    label: 'Settings',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.home, // Using home icon as 5th placeholder
    label: 'More',
  ),
];

const _arabicItems = [
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.home,
    label: 'الرئيسية',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.service,
    label: 'الخدمات',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.messages,
    label: 'الرسائل',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.settings,
    label: 'الإعدادات',
  ),
  AppBottomNavItem(
    iconAsset: AppNavigationIcons.home,
    label: 'المزيد',
  ),
];

/// Interactive bottom-nav preview for the design catalog.
class BottomNavCatalogDemo extends StatefulWidget {
  /// Creates a catalog demo for [AppBottomNavBar].
  const BottomNavCatalogDemo({
    required this.currentIndex,
    this.centerSelected = false,
    this.centerEnabled = true,
    this.disabledTabIndex,
    this.textDirection,
    this.items = _defaultItems,
    super.key,
  });

  /// Initially selected side-tab index (0-4).
  final int currentIndex;

  /// Whether the center FAB uses the active fill color.
  final bool centerSelected;

  /// Whether the center FAB accepts taps.
  final bool centerEnabled;

  /// When set, the tab at this index is rendered disabled.
  final int? disabledTabIndex;

  /// Overrides layout direction (e.g. [TextDirection.rtl] for Arabic).
  final TextDirection? textDirection;

  /// Side tabs to render (must be exactly 5 items).
  final List<AppBottomNavItem> items;

  @override
  State<BottomNavCatalogDemo> createState() => _BottomNavCatalogDemoState();
}

class _BottomNavCatalogDemoState extends State<BottomNavCatalogDemo> {
  late final _controller = createAppBottomNavController();

  late int _selectedIndex = widget.currentIndex;

  @override
  void didUpdateWidget(covariant BottomNavCatalogDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectedIndex = widget.currentIndex;
    }
  }

  List<AppBottomNavItem> get _items {
    if (widget.disabledTabIndex == null) {
      return widget.items;
    }
    return [
      for (var i = 0; i < widget.items.length; i++)
        if (i == widget.disabledTabIndex)
          AppBottomNavItem(
            iconAsset: widget.items[i].iconAsset,
            label: widget.items[i].label,
            enabled: false,
          )
        else
          widget.items[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bar = AppBottomNavBar(
      controller: _controller,
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      centerAction: AppBottomNavCenterAction(
        iconAsset: AppNavigationIcons.centerAction,
        semanticLabel: 'Create',
        selected: widget.centerSelected,
        enabled: widget.centerEnabled,
        onTap: widget.centerEnabled ? _noop : null,
      ),
      items: _items,
    );

    return Directionality(
      textDirection: widget.textDirection ?? TextDirection.ltr,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Page content'),
              const SizedBox(height: 16),
              Text(
                'Selected: $_selectedIndex',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        bottomNavigationBar: bar,
      ),
    );
  }
}

void _noop() {}
