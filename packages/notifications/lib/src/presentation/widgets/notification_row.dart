import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:notifications/src/domain/entities/app_notification.dart';

/// One inbox row.
///
/// [AppNotification.title] and [AppNotification.body] are rendered verbatim:
/// the backend writes them in the recipient's language at notification time, so
/// passing them through `.tr()` would look up a key that does not exist.
class NotificationRow extends StatelessWidget {
  const NotificationRow({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final isUnread = notification.isUnread;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppDimension.notificationCardLeadingSize,
              height: AppDimension.notificationCardLeadingSize,
              decoration: BoxDecoration(
                color: colors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none, color: colors.primary),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: isUnread
                        ? typography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : typography.bodyMedium,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.body,
                    style: typography.bodySmall.copyWith(
                      color: colors.slate600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    // Locale-aware: `DateFormat.yMMMd(locale)` renders Arabic
                    // month names and digits under an RTL locale rather than
                    // falling back to en_US.
                    DateFormat.yMMMd(
                      context.locale.toString(),
                    ).add_jm().format(notification.createdAt),
                    style: typography.labelSmall.copyWith(
                      color: colors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              SizedBox(width: AppSpacing.xs),
              Container(
                margin: EdgeInsetsDirectional.only(top: AppSpacing.xs),
                width: AppDimension.notificationCardUnreadDot,
                height: AppDimension.notificationCardUnreadDot,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
