import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Structural shell only — a real My Life feature is a separate piece of
/// work. This page exists so the Home nav pill has somewhere to go; it holds
/// no business logic and no data source.
///
/// No `AppNavBar` of its own: as a branch of `AiHomeShell`, the header row
/// (avatar, nav pill, history) is the shell's chrome, not this page's.
class MyLifePage extends StatelessWidget {
  /// Creates the page.
  const MyLifePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    // Scrollable, not because this content is expected to be tall — because
    // it might be, at a large accessibility text scale or on a small device,
    // and `AppEmptyState`'s own `Column` does not scroll on its own.
    body: SingleChildScrollView(
      // Not `AppGenericEmptyState`: its illustration is a shuttered shop,
      // which says "this business is closed" on a page about the user's own
      // documents and services (A-16). No fitting asset exists in
      // `app_assets`, so a neutral glyph stands in until one does.
      child: AppEmptyState(
        illustration: Icon(
          Icons.folder_outlined,
          size: AppDimension.iconButtonLg,
          color: context.appColors.textMuted,
        ),
        title: 'my_life.empty_title'.tr(),
        description: 'my_life.empty_description'.tr(),
      ),
    ),
  );
}
