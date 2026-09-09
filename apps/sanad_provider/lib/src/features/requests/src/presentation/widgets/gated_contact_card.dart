import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/gated_contact.dart';

/// The client's contact details, or the reason they are not shown.
///
/// **Renders on [GatedContact.isUnlocked] and nothing else.** Not on the
/// request status, not on the offer status, not on "do the fields happen to be
/// populated". The server is the authority on whether this provider has earned
/// the client's phone number, and a second, local opinion about it is exactly
/// how that leaks.
///
/// The single `if` in [build] is the whole privacy boundary; keep it that way.
class GatedContactCard extends StatelessWidget {
  /// Creates the card.
  const GatedContactCard({required this.contact, super.key});

  /// The gated block from the provider-view payload.
  final GatedContact contact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    if (!contact.isUnlocked) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.slate50,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: colors.slate500),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'provider_requests.contact_locked_title'.tr(),
                    style: typography.titleSmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'provider_requests.contact_locked_description'.tr(),
              style: typography.bodySmall.copyWith(color: colors.slate600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'provider_requests.contact_title'.tr(),
          style: typography.titleSmall,
        ),
        SizedBox(height: AppSpacing.sm),
        if (contact.clientName != null)
          AppKeyValueCard(
            title: 'provider_requests.client_name'.tr(),
            value: contact.clientName!,
          ),
        if (contact.clientPhone != null)
          AppKeyValueCard(
            title: 'provider_requests.client_phone'.tr(),
            value: contact.clientPhone!,
            // A phone number is inherently LTR: without this its leading `+`
            // renders at the visual end under an RTL locale (SAN-770/771/775).
            isLtr: true,
          ),
        if (contact.addressLine != null)
          AppKeyValueCard(
            title: 'provider_requests.address'.tr(),
            value: contact.addressLine!,
          ),
      ],
    );
  }
}
