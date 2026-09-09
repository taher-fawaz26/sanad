import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notifications/notifications.dart';

/// Home header — dynamic greeting + notification bell. Figma `6755:25941`.
///
/// The greeting name comes from the authenticated session
/// ([SessionContextX.session]), never hardcoded. The bell opens the
/// notification inbox from `package:notifications`.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final name = context.session.displayName ?? context.session.businessName;

    return Row(
      children: [
        Expanded(
          child: Text(
            name == null || name.isEmpty
                ? 'home.greeting_generic'.tr()
                : 'home.greeting'.tr(namedArgs: {'name': name}),
            style: typography.regularNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        AppNotificationIcon(
          onTap: () => context.push(NotificationsRoutes.notifications),
        ),
      ],
    );
  }
}
