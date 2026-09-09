import 'package:authorization/authorization.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_offer.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/bloc/detail/provider_request_detail_bloc.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/widgets/gated_contact_card.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/widgets/provider_offer_sheet.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/widgets/provider_reason_sheet.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/widgets/provider_request_formats.dart';
import 'package:sanad_provider/src/features/requests/src/routes/client_request_permissions.dart';
import 'package:shared_ui/shared_ui.dart';

/// One request in the provider view, with its own thread and every action.
class ProviderRequestDetailPage extends StatelessWidget {
  /// Creates the page.
  const ProviderRequestDetailPage({required this.buildBloc, super.key});

  /// Builds the detail bloc for this request.
  final ProviderRequestDetailBloc Function() buildBloc;

  @override
  Widget build(BuildContext context) => BlocProvider<ProviderRequestDetailBloc>(
    create: (_) => buildBloc()..add(const ProviderRequestDetailStarted()),
    child: const _DetailView(),
  );
}

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ProviderRequestDetailBloc>().add(
        const ProviderRequestDetailRefreshed(),
      );
    }
  }

  ProviderRequestDetailBloc get _bloc =>
      context.read<ProviderRequestDetailBloc>();

  Future<void> _sendOffer(ProviderRequest request) async {
    final result = await ProviderOfferSheet.show(
      context,
      title: 'provider_requests.offer_sheet_title'.tr(),
      description: 'provider_requests.offer_sheet_description'.tr(),
      branches: [
        if (request.branchId != null)
          OfferBranchOption(
            id: request.branchId!,
            name: request.branchName ?? request.branchId!,
          ),
      ],
      initial: request.preferredAt,
    );
    if (result == null || !mounted) return;
    _bloc.add(
      ProviderOfferCreated(
        branchId: result.branchId,
        proposedAt: result.proposedAt,
        note: result.note,
      ),
    );
  }

  Future<void> _counter(ProviderOffer offer) async {
    final result = await ProviderOfferSheet.show(
      context,
      title: 'provider_requests.counter'.tr(),
      description: 'client_requests.counter_sheet_description'.tr(),
      initial: offer.proposedAt,
    );
    if (result == null || !mounted) return;
    _bloc.add(
      ProviderCounterSent(
        offerId: offer.id,
        proposedAt: result.proposedAt,
        note: result.note,
      ),
    );
  }

  Future<void> _withdraw(ProviderOffer offer) async {
    // Withdrawing consumes a re-bid, so the warning is part of the action
    // rather than fine print somewhere else on the screen.
    final confirmed = await ProviderReasonSheet.confirm(
      context,
      title: 'provider_requests.withdraw'.tr(),
      description: 'provider_requests.withdraw_warning'.tr(),
      confirmLabel: 'provider_requests.withdraw'.tr(),
    );
    if (!confirmed || !mounted) return;
    _bloc.add(ProviderOfferWithdrawn(offer.id));
  }

  Future<void> _cancelBooking() async {
    final reason = await ProviderReasonSheet.show(
      context,
      title: 'provider_requests.cancel_sheet_title'.tr(),
      description: 'provider_requests.cancel_sheet_description'.tr(),
      confirmLabel: 'provider_requests.cancel_booking'.tr(),
    );
    if (reason == null || !mounted) return;
    _bloc.add(ProviderJobCancelled(reason));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProviderRequestDetailBloc, ProviderRequestDetailState>(
      listenWhen: (a, b) => a.mutationStatus != b.mutationStatus,
      listener: (context, state) {
        if (state.mutationStatus == RequestStatus.failure) {
          showAppErrorSnackbar(
            context: context,
            title:
                state.mutationFailure?.localizedSafeMessage() ??
                'provider_requests.error_title'.tr(),
          );
          _bloc.add(const ProviderRequestMutationAcknowledged());
        }
      },
      builder: (context, state) {
        final request = state.request;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppNavBar(
                  title: 'provider_requests.detail_title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: request == null
                      ? _EmptyOrError(state: state)
                      : AppRefreshIndicator(
                          onRefresh: () async => _bloc.add(
                            const ProviderRequestDetailRefreshed(),
                          ),
                          child: ListView(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            children: [
                              _Header(request: request),
                              SizedBox(height: AppSpacing.lg),
                              GatedContactCard(contact: request.contact),
                              SizedBox(height: AppSpacing.lg),
                              _MyThread(request: request),
                              SizedBox(height: AppSpacing.xl),
                              _Actions(
                                request: request,
                                isBusy: state.isMutating,
                                onSendOffer: () => _sendOffer(request),
                                onWithdraw: _withdraw,
                                onCounter: _counter,
                                onAcceptCounter: (id) =>
                                    _bloc.add(ProviderCounterAccepted(id)),
                                onDeclineCounter: (id) =>
                                    _bloc.add(ProviderCounterDeclined(id)),
                                onComplete: () =>
                                    _bloc.add(const ProviderJobCompleted()),
                                onCancel: _cancelBooking,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({required this.state});

  final ProviderRequestDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == RequestStatus.failure) {
      return AppGenericEmptyState(
        title: 'provider_requests.error_title'.tr(),
        description: state.loadFailure?.localizedSafeMessage() ?? '',
      );
    }
    return const Center(child: AppLoadingIndicator());
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.request});

  final ProviderRequest request;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final preferredAt = request.preferredAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(request.serviceName, style: typography.title3),
            ),
            SizedBox(width: AppSpacing.sm),
            AppChip(label: request.tab.labelKey.tr()),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          [
            if (request.areaName != null) request.areaName!,
            'provider_requests.distance_km'.tr(
              namedArgs: {'km': request.distanceKm.toStringAsFixed(1)},
            ),
          ].join(' · '),
          style: typography.bodySmall.copyWith(color: colors.slate600),
        ),
        if (preferredAt != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            formatProviderDateTime(context, preferredAt),
            style: typography.bodySmall,
          ),
        ],
        if (request.note != null && request.note!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(request.note!, style: typography.bodySmall),
        ],
        if (request.disputeReason != null) ...[
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.error50,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'provider_requests.dispute_notice_title'.tr(),
                  style: typography.titleSmall,
                ),
                SizedBox(height: AppSpacing.xs),
                // Shown verbatim — a dispute the provider cannot read is one
                // they cannot answer.
                Text(request.disputeReason!, style: typography.bodySmall),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MyThread extends StatelessWidget {
  const _MyThread({required this.request});

  final ProviderRequest request;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    if (request.myOffers.isEmpty) {
      return Text(
        'provider_requests.no_offer_yet'.tr(),
        style: typography.bodySmall.copyWith(color: colors.slate600),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'provider_requests.my_offer_title'.tr(),
          style: typography.titleSmall,
        ),
        SizedBox(height: AppSpacing.sm),
        // Only this provider's thread. Rival offers never reach the device.
        for (final offer in request.myOffers)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  offer.isMine
                      ? Icons.storefront_outlined
                      : Icons.person_outline,
                  size: 16,
                  color: colors.slate500,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatProviderDateTime(context, offer.proposedAt),
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
                Text(
                  _offerStatusKey(offer.status).tr(),
                  style: typography.labelSmall.copyWith(
                    color: colors.slate500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: AppSpacing.xs),
        Text(
          request.remainingRebids > 0
              ? 'provider_requests.remaining_rebids'.tr(
                  namedArgs: {'count': '${request.remainingRebids}'},
                )
              : 'provider_requests.no_rebids_left'.tr(),
          style: typography.labelSmall.copyWith(color: colors.slate500),
        ),
      ],
    );
  }

  /// `LOST` and `REJECTED` deliberately read differently: one means another
  /// provider won, the other that this offer was declined.
  static String _offerStatusKey(RequestOfferStatus status) => switch (status) {
    RequestOfferStatus.pending => 'requests.offer_status.pending',
    RequestOfferStatus.accepted => 'requests.offer_status.accepted',
    RequestOfferStatus.rejected => 'requests.offer_status.rejected',
    RequestOfferStatus.superseded => 'requests.offer_status.superseded',
    RequestOfferStatus.lost => 'requests.offer_status.lost',
    RequestOfferStatus.withdrawn => 'requests.offer_status.withdrawn',
    RequestOfferStatus.voided => 'requests.offer_status.voided',
    RequestOfferStatus.expired => 'requests.offer_status.expired',
    RequestOfferStatus.unknown => 'requests.status.unknown',
  };
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.request,
    required this.isBusy,
    required this.onSendOffer,
    required this.onWithdraw,
    required this.onCounter,
    required this.onAcceptCounter,
    required this.onDeclineCounter,
    required this.onComplete,
    required this.onCancel,
  });

  final ProviderRequest request;
  final bool isBusy;
  final VoidCallback onSendOffer;
  final void Function(ProviderOffer offer) onWithdraw;
  final void Function(ProviderOffer offer) onCounter;
  final ValueChanged<String> onAcceptCounter;
  final ValueChanged<String> onDeclineCounter;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final pending = request.pendingOffer;

    return Column(
      children: [
        // Write affordances are gated on the backend's own permission strings,
        // not on persona: a manager may view a workspace they cannot bid in.
        PermissionGate(
          permission: ClientRequestPermissions.offer,
          child: Column(
            children: [
              if (request.canSendOffer)
                AppButton(
                  label: 'provider_requests.send_offer'.tr(),
                  onPressed: isBusy ? null : onSendOffer,
                ),
              if (request.isAwaitingProvider && pending != null) ...[
                AppButton(
                  label: 'provider_requests.accept_counter'.tr(),
                  onPressed: isBusy ? null : () => onAcceptCounter(pending.id),
                ),
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'provider_requests.counter'.tr(),
                  onPressed: isBusy ? null : () => onCounter(pending),
                  variant: AppButtonVariant.outline,
                ),
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'provider_requests.decline_counter'.tr(),
                  onPressed: isBusy ? null : () => onDeclineCounter(pending.id),
                  variant: AppButtonVariant.transparent,
                  intent: AppButtonIntent.destructive,
                ),
              ],
              if (request.canWithdraw && pending != null) ...[
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'provider_requests.withdraw'.tr(),
                  onPressed: isBusy ? null : () => onWithdraw(pending),
                  variant: AppButtonVariant.outline,
                ),
              ],
            ],
          ),
        ),
        PermissionGate(
          permission: ClientRequestPermissions.complete,
          child: Column(
            children: [
              if (request.canComplete) ...[
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'provider_requests.complete'.tr(),
                  onPressed: isBusy ? null : onComplete,
                ),
              ],
              if (request.canCancelBooking) ...[
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'provider_requests.cancel_booking'.tr(),
                  onPressed: isBusy ? null : onCancel,
                  variant: AppButtonVariant.transparent,
                  intent: AppButtonIntent.destructive,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
