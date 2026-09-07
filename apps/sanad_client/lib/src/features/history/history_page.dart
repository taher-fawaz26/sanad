import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

/// Structural shell only — a real chat-history feature (listing and
/// resuming past conversations) is a separate piece of work. This page exists
/// so the Home header's History button has somewhere to go.
///
/// Unlike the nav-pill destinations, this is a normal pushed page — reaching
/// it does not leave the Sanad/Requests/My Life branch set, so it gets its
/// own back-navigable `AppNavBar` rather than relying on shell chrome.
class HistoryPage extends StatelessWidget {
  /// Creates the page.
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppNavBar(
      title: 'history.title'.tr(),
      showBackButton: true,
      onLeadingTap: () => context.pop(),
    ),
    // Scrollable, not because this content is expected to be tall — because
    // it might be, at a large accessibility text scale or on a small device,
    // and `AppEmptyState`'s own `Column` does not scroll on its own.
    body: SingleChildScrollView(
      child: AppGenericEmptyState(
        title: 'history.empty_title'.tr(),
        description: 'history.empty_description'.tr(),
      ),
    ),
  );
}
