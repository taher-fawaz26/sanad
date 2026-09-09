import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/request_offer.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/request_offer_thread.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_date_time_picker.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_status_badge.dart';

/// One provider's negotiation, with the actions available on it.
///
/// Whose turn it is comes from the pending offer's `actorType` — never from
/// the request status — so the accept/decline/counter row appears only while a
/// *provider* offer is pending.
class OfferThreadCard extends StatelessWidget {
  /// Creates the card.
  const OfferThreadCard({
    required this.thread,
    required this.onAccept,
    required this.onReject,
    required this.onCounter,
    super.key,
    this.isBusy = false,
    this.isHighlighted = false,
  });

  /// The thread to render.
  final RequestOfferThread thread;

  /// Accepts the pending provider offer.
  final ValueChanged<String> onAccept;

  /// Declines the pending provider offer.
  final ValueChanged<String> onReject;

  /// Opens the counter sheet for the pending provider offer.
  final void Function(RequestOffer offer) onCounter;

  /// Disables the actions while a mutation is in flight.
  final bool isBusy;

  /// Draws attention to this thread — used when a notification pointed at it.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final pending = thread.pendingOffer;

    return Container(
      margin: EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isHighlighted ? colors.primary : colors.slate200,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  thread.providerName,
                  style: typography.titleSmall,
                ),
              ),
              if (thread.isAwaitingClient)
                AppChip(label: 'client_requests.awaiting_you'.tr())
              else if (thread.isAwaitingProvider)
                AppChip(
                  label: 'client_requests.awaiting_provider'.tr(),
                  style: AppChipStyle.outline,
                ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            [
              thread.branchName,
              'client_requests.distance_km'.tr(
                namedArgs: {'km': thread.distanceKm.toStringAsFixed(1)},
              ),
              'client_requests.completed_jobs'.tr(
                namedArgs: {'count': '${thread.completedJobs}'},
              ),
            ].join(' · '),
            style: typography.bodySmall.copyWith(color: colors.slate600),
          ),
          SizedBox(height: AppSpacing.md),
          // Oldest first, as the contract orders them — the thread reads as a
          // conversation rather than a set of unrelated offers.
          for (final offer in thread.offers) _OfferRow(offer: offer),
          if (pending != null && pending.awaitsClient) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'client_requests.accept'.tr(),
                    onPressed: isBusy ? null : () => onAccept(pending.id),
                    size: AppButtonSize.small,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'client_requests.counter'.tr(),
                    onPressed: isBusy ? null : () => onCounter(pending),
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'client_requests.reject'.tr(),
              onPressed: isBusy ? null : () => onReject(pending.id),
              variant: AppButtonVariant.transparent,
              intent: AppButtonIntent.destructive,
              size: AppButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final RequestOffer offer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            offer.isFromClient
                ? Icons.person_outline
                : Icons.storefront_outlined,
            size: 16,
            color: colors.slate500,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'client_requests.proposed_for'.tr(
                    namedArgs: {
                      'time': formatRequestDateTime(context, offer.proposedAt),
                    },
                  ),
                  style: typography.bodySmall,
                ),
                if (offer.note != null && offer.note!.isNotEmpty)
                  Text(
                    offer.note!,
                    style: typography.labelSmall.copyWith(
                      color: colors.slate600,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            offer.status.labelKey.tr(),
            style: typography.labelSmall.copyWith(color: colors.slate500),
          ),
        ],
      ),
    );
  }
}
