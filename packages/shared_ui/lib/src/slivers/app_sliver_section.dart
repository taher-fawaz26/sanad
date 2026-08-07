import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// [AppSection] wrapped for direct use inside a [CustomScrollView]'s
/// `slivers` list.
class AppSliverSection extends StatelessWidget {
  const AppSliverSection({
    required this.title,
    super.key,
    this.caption,
    this.size = AppSectionSize.large,
    this.tone = AppSectionTone.normal,
    this.trailing = AppSectionTrailing.none,
    this.trailingIcon,
    this.trailingButtonLabel,
    this.trailingWidget,
    this.onTrailingTap,
    this.padding,
  });

  final String title;
  final String? caption;
  final AppSectionSize size;
  final AppSectionTone tone;
  final AppSectionTrailing trailing;
  final Widget? trailingIcon;
  final String? trailingButtonLabel;
  final Widget? trailingWidget;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AppSection(
        title: title,
        caption: caption,
        size: size,
        tone: tone,
        trailing: trailing,
        trailingIcon: trailingIcon,
        trailingButtonLabel: trailingButtonLabel,
        trailingWidget: trailingWidget,
        onTrailingTap: onTrailingTap,
        padding: padding,
      ),
    );
  }
}
