import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Structural shell only — a real Requests feature is a separate piece of
/// work. This page exists so the Home nav pill has somewhere to go; it holds
/// no business logic and no data source.
///
/// No `AppNavBar` of its own: as a branch of `AiHomeShell`, the header row
/// (avatar, nav pill, history) is the shell's chrome, not this page's.
class RequestsPage extends StatelessWidget {
  /// Creates the page.
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    // Scrollable, not because this content is expected to be tall — because
    // it might be, at a large accessibility text scale or on a small device,
    // and `AppEmptyState`'s own `Column` does not scroll on its own.
    body: SingleChildScrollView(
      child: AppGenericEmptyState(
        title: 'requests.empty_title'.tr(),
        description: 'requests.empty_description'.tr(),
      ),
    ),
  );
}
