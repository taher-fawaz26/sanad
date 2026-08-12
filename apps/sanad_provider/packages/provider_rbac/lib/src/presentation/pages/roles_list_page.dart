import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider_rbac/src/presentation/widgets/roles_content.dart';

/// Standalone "Roles" screen (route `/roles-permissions`) — a nav-bar wrapper
/// around the shared [RolesContent] pane, kept for deep-links and as the
/// parent of the add / edit / details sub-routes.
///
/// In the normal flow the roles pane is shown *inline* as the third tab of the
/// Workers screen (Team / Invitations / Roles) via [RolesContent], so users no
/// longer navigate to a separate screen to switch tabs.
class RolesListPage extends StatelessWidget {
  const RolesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: 'provider_rbac.title'.tr(),
              showBackButton: true,
              onLeadingTap: () => context.pop(),
              trailing: AppNotificationIcon(onTap: () {}),
              trailingAction: AppNavBarTrailingAction.icon,
            ),
            const Expanded(child: RolesContent()),
          ],
        ),
      ),
    );
  }
}
