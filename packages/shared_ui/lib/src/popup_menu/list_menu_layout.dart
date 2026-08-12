import 'package:flutter/material.dart';
import 'package:shared_ui/src/popup_menu/menu_config.dart';
import 'package:shared_ui/src/popup_menu/menu_item.dart';
import 'package:shared_ui/src/popup_menu/menu_layout.dart';
import 'package:shared_ui/src/popup_menu/popup_menu_overlay.dart';

/// Single-column [PopupMenu] layout.
class ListMenuLayout implements MenuLayout {
  /// Creates a list layout for [items].
  const ListMenuLayout({
    required this.config,
    required this.items,
    required this.onDismiss,
    required this.context,
    this.onClickMenu,
  });

  /// Shared menu configuration.
  final MenuConfig config;

  /// Entries rendered by this layout.
  final List<MenuItemProvider> items;

  /// Invoked to close the menu after a tap.
  final VoidCallback onDismiss;

  /// The context the menu was shown from.
  final BuildContext context;

  /// Invoked when an entry is tapped, before [onDismiss].
  final MenuClickCallback? onClickMenu;

  @override
  Widget build() {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              for (final item in items)
                GestureDetector(
                  onTap: () {
                    onDismiss();
                    onClickMenu?.call(item);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: config.itemHeight,
                    child: Row(
                      children: [
                        if (item.menuImage != null)
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: 10),
                            child: item.menuImage,
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 10,
                              end: 10,
                            ),
                            child: Text(
                              item.menuTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: item.menuTextStyle ?? config.textStyle,
                              textAlign: item.menuTextAlign,
                            ),
                          ),
                        ),

                        // arrow icon
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: config.highlightColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get height => config.itemHeight * items.length;

  @override
  double get width => config.itemWidth;
}
