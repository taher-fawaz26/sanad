import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/request_offer.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_request_detail/client_request_detail_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/counter_offer_sheet.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/offer_thread_card.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/reason_sheet.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_date_time_picker.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_status_badge.dart';
import 'package:shared_ui/shared_ui.dart';

/// One request, its matched providers, and its negotiation threads.
///
/// Re-reads whenever the screen is revisited, pulled, or resumed. That is not
/// belt-and-braces: `SUBMITTED → EXPIRED`, `SCHEDULED → IN_PROGRESS` and
/// `AWAITING_CONFIRMATION → COMPLETED` all happen on server timers with no user
/// action, and mobile does not hold the notification stream open. The server is
/// the only authority on what state this request is in.
class ClientRequestDetailPage extends StatelessWidget {
  /// Creates the page.
  const ClientRequestDetailPage({
    required this.buildBloc,
    super.key,
    this.focusOfferId,
  });

  /// Builds the detail bloc for this request.
  final ClientRequestDetailBloc Function() buildBloc;

  /// The offer thread to draw attention to.
  ///
  /// Set when a `REQUEST_OFFER` notification opened this screen — an offer
  /// lives inside its request, so the notification lands here rather than on a
  /// standalone offer page.
  final String? focusOfferId;

  @override
  Widget build(BuildContext context) => BlocProvider<ClientRequestDetailBloc>(
    create: (_) => buildBloc()..add(const ClientRequestDetailStarted()),
    child: _DetailView(focusOfferId: focusOfferId),
  );
}

class _DetailView extends StatefulWidget {
  const _DetailView({this.focusOfferId});

  final String? focusOfferId;

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
    // Coming back from the background is exactly when a timer-driven
    // transition is most likely to have happened while nobody was watching.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ClientRequestDetailBloc>().add(
        const ClientRequestDetailRefreshed(),
      );
    }
  }

  ClientRequestDetailBloc get _bloc => context.read<ClientRequestDetailBloc>();

  Future<void> _cancel() async {
    final reason = await ReasonSheet.show(
      context,
      title: 'client_requests.cancel_sheet_title'.tr(),
      description: 'client_requests.cancel_sheet_description'.tr(),
      confirmLabel: 'client_requests.cancel_request'.tr(),
      isDestructive: true,
    );
    if (reason == null || !mounted) return;
    _bloc.add(ClientRequestCancelled(reason));
  }

  Future<void> _dispute() async {
    final reason = await ReasonSheet.show(
      context,
      title: 'client_requests.dispute_sheet_title'.tr(),
      description: 'client_requests.dispute_sheet_description'.tr(),
      confirmLabel: 'client_requests.dispute'.tr(),
      isDestructive: true,
    );
    if (reason == null || !mounted) return;
    _bloc.add(ClientRequestDisputed(reason));
  }

  Future<void> _counter(RequestOffer offer) async {
    final result = await CounterOfferSheet.show(
      context,
      initial: offer.proposedAt,
    );
    if (result == null || !mounted) return;
    _bloc.add(
      ClientRequestOfferCountered(
        offerId: offer.id,
        proposedAt: result.proposedAt,
        note: result.note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientRequestDetailBloc, ClientRequestDetailState>(
      listenWhen: (a, b) => a.mutationStatus != b.mutationStatus,
      listener: (context, state) {
        if (state.mutationStatus == RequestStatus.failure) {
          showAppErrorSnackbar(
            context: context,
            title:
                state.mutationFailure?.localizedSafeMessage() ??
                'client_requests.error_title'.tr(),
          );
          _bloc.add(const ClientRequestMutationAcknowledged());
        }
      },
      builder: (context, state) {
        final request = state.request;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppNavBar(
                  title: 'client_requests.detail_title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: request == null
                      ? _EmptyOrError(state: state)
                      : AppRefreshIndicator(
                          onRefresh: () async => _bloc.add(
                            const ClientRequestDetailRefreshed(),
                          ),
                          child: ListView(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            children: [
                              _Header(request: request),
                              SizedBox(height: AppSpacing.lg),
                              _MatchedBranches(request: request),
                              SizedBox(height: AppSpacing.lg),
                              _Threads(
                                request: request,
                                isBusy: state.isMutating,
                                focusOfferId: widget.focusOfferId,
                                onAccept: (id) =>
                                    _bloc.add(ClientRequestOfferAccepted(id)),
                                onReject: (id) =>
                                    _bloc.add(ClientRequestOfferRejected(id)),
                                onCounter: _counter,
                              ),
                              SizedBox(height: AppSpacing.xl),
                              _Actions(
                                request: request,
                                isBusy: state.isMutating,
                                onCancel: _cancel,
                                onDispute: _dispute,
                                onConfirm: () =>
                                    _bloc.add(const ClientRequestConfirmed()),
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

  final ClientRequestDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == RequestStatus.failure) {
      return AppGenericEmptyState(
        title: 'client_requests.error_title'.tr(),
        description: state.loadFailure?.localizedSafeMessage() ?? '',
      );
    }
    return const Center(child: AppLoadingIndicator());
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.request});

  final ClientRequest request;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final preferredAt = request.preferredAt;
    final scheduledAt = request.scheduledAt;
    final expiresAt = request.expiresAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.serviceName ??
                    // Names itself rather than borrowing the service
                    // picker's "Choose a service" placeholder — there is no
                    // picker to choose with any more, so that read as an
                    // instruction the user cannot follow. Same fallback the
                    // list row uses.
                    'client_requests.untitled_draft'.tr(),
                style: typography.title3,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            RequestStatusBadge(status: request.status),
          ],
        ),
        if (request.addressLine != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            request.addressLine!,
            style: typography.bodySmall.copyWith(color: colors.slate600),
          ),
        ],
        if (preferredAt != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            formatRequestDateTime(context, preferredAt),
            style: typography.bodySmall,
          ),
        ],
        if (scheduledAt != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            'client_requests.scheduled_for'.tr(
              namedArgs: {
                'time': formatRequestDateTime(context, scheduledAt),
              },
            ),
            style: typography.bodySmall.copyWith(color: colors.slate600),
          ),
        ],
        // Set by the server at submit time — never computed on the device.
        if (expiresAt != null && request.status.isDraft == false) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            'client_requests.expires_at'.tr(
              namedArgs: {'time': formatRequestDateTime(context, expiresAt)},
            ),
            style: typography.labelSmall.copyWith(color: colors.slate500),
          ),
        ],
        if (request.note != null && request.note!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(request.note!, style: typography.bodySmall),
        ],
      ],
    );
  }
}

class _MatchedBranches extends StatelessWidget {
  const _MatchedBranches({required this.request});

  final ClientRequest request;

  @override
  Widget build(BuildContext context) {
    if (request.matchedBranches.isEmpty) return const SizedBox.shrink();
    final typography = context.appTypography;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'client_requests.matched_branches_title'.tr(),
          style: typography.titleSmall,
        ),
        SizedBox(height: AppSpacing.sm),
        for (final branch in request.matchedBranches)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
            child: Text(
              '${branch.providerName} · ${branch.branchName} · '
              '${_distance(branch.distanceKm)}',
              style: typography.bodySmall.copyWith(color: colors.slate600),
            ),
          ),
      ],
    );
  }
}

String _distance(double km) => 'client_requests.distance_km'.tr(
  namedArgs: {'km': km.toStringAsFixed(1)},
);

class _Threads extends StatelessWidget {
  const _Threads({
    required this.request,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
    required this.onCounter,
    this.focusOfferId,
  });

  final ClientRequest request;
  final bool isBusy;
  final String? focusOfferId;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;
  final void Function(RequestOffer offer) onCounter;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    if (request.threads.isEmpty) {
      // Branch on the request's own status, not on "there are no threads"
      // (C-03). A draft has never been submitted, so telling its owner that
      // "matching providers have been notified" is simply false — and
      // alarming, because it says their unfinished request was broadcast to
      // businesses. `threads.isEmpty` is true for both cases and can tell
      // them apart only by accident.
      if (request.status.isDraft) {
        return AppGenericEmptyState(
          title: 'client_requests.draft_not_submitted_title'.tr(),
          description: 'client_requests.draft_not_submitted_description'.tr(),
        );
      }
      return AppGenericEmptyState(
        title: 'client_requests.no_offers_title'.tr(),
        description: 'client_requests.no_offers_description'.tr(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('client_requests.offers_title'.tr(), style: typography.titleSmall),
        SizedBox(height: AppSpacing.sm),
        for (final thread in request.threads)
          OfferThreadCard(
            thread: thread,
            isBusy: isBusy,
            // A notification can point at any offer in the thread, including
            // one that has since been superseded.
            isHighlighted:
                focusOfferId != null &&
                thread.offers.any((offer) => offer.id == focusOfferId),
            onAccept: onAccept,
            onReject: onReject,
            onCounter: onCounter,
          ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.request,
    required this.isBusy,
    required this.onCancel,
    required this.onDispute,
    required this.onConfirm,
  });

  final ClientRequest request;
  final bool isBusy;
  final VoidCallback onCancel;
  final VoidCallback onDispute;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (request.canConfirmOrDispute) ...[
        AppButton(
          label: 'client_requests.confirm'.tr(),
          onPressed: isBusy ? null : onConfirm,
        ),
        SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'client_requests.dispute'.tr(),
          onPressed: isBusy ? null : onDispute,
          variant: AppButtonVariant.outline,
          intent: AppButtonIntent.destructive,
        ),
        SizedBox(height: AppSpacing.sm),
      ],
      if (request.canCancel)
        AppButton(
          label: 'client_requests.cancel_request'.tr(),
          onPressed: isBusy ? null : onCancel,
          variant: AppButtonVariant.transparent,
          intent: AppButtonIntent.destructive,
        ),
    ],
  );
}
