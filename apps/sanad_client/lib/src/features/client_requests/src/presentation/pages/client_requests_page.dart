import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_request_card.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tabs.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tokens.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/reason_sheet.dart';
import 'package:sanad_client/src/features/client_requests/src/routes/client_request_routes.dart';
import 'package:sanad_client/src/ui/background/client_ambient_background.dart';
import 'package:shared_ui/shared_ui.dart';

/// The client's own requests — Figma `Requests - Active` (`8135:29516`).
///
/// Re-reads on every visit and on pull-to-refresh. That is deliberate rather
/// than lazy: the backend moves requests on timers — a submitted request
/// expires, a scheduled one starts, an awaiting-confirmation one completes —
/// so a list held from a previous visit is routinely stale, and mobile does not
/// subscribe to the notification stream.
class ClientRequestsPage extends StatelessWidget {
  /// Creates the page.
  const ClientRequestsPage({
    required this.buildBloc,
    super.key,
    this.showNavBar = true,
  });

  /// Builds the list bloc. Injected so the page stays testable.
  final ClientRequestsListBloc Function() buildBloc;

  /// Whether to draw the page's own title bar.
  ///
  /// False inside `AiHomeShell`, whose nav pill already names this
  /// destination; true for the pushed `/requests` route, which has no pill and
  /// would otherwise be untitled (C-08).
  final bool showNavBar;

  @override
  Widget build(BuildContext context) => BlocProvider<ClientRequestsListBloc>(
    create: (_) => buildBloc()..add(const ClientRequestsStarted()),
    child: _ClientRequestsView(showNavBar: showNavBar),
  );
}

class _ClientRequestsView extends StatelessWidget {
  const _ClientRequestsView({required this.showNavBar});

  final bool showNavBar;

  @override
  Widget build(BuildContext context) {
    // No create affordance, by product rule: a request is created by asking
    // the agent in AI Chat, never by filling in a form here. This screen is a
    // viewer and manager for requests that already exist.
    final body = Scaffold(
      // Transparent so the shared wash — the shell's, or this page's own —
      // is the only background. Left opaque, the Scaffold painted flat
      // near-white over the gradient and the screen lost its identity.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          // Keyed by the app's locale, which also *registers a dependency*
          // on `Localizations` — the reason both matter is that `.tr()` reads
          // a global singleton and subscribes to nothing, so a widget that
          // does not rebuild for some other reason keeps whichever language
          // it was first built in. Switching to Arabic left the three tab
          // pills reading "Active / Scheduled / Cancelled" under an otherwise
          // fully translated, fully mirrored screen. One dependency here
          // refreshes the whole screen's copy.
          key: ValueKey(Localizations.localeOf(context)),
          children: [
            // Suppressed inside the home shell, whose nav pill already names
            // this destination — two "Requests" titles stacked read as a
            // rendering mistake (C-08).
            if (showNavBar) AppNavBar(title: 'client_requests.title'.tr()),
            // Deliberately **not** `const`: a `const` widget's element is
            // reused verbatim when its parent rebuilds, which would defeat
            // the key above.
            _Tabs(),
            Expanded(child: _RequestsList()),
          ],
        ),
      ),
    );

    // The page paints the wash itself, in every host.
    //
    // The shell paints one too, but a branch's own page covers it: measured
    // on the device, the shell's gradient survives only behind the header
    // strip and the branch below renders flat white. `AiChatPage` and
    // `HistoryPage` already repaint it for the same reason. The two do not
    // seam, because Figma's gradient holds a flat `#F9F9FA` until 59% of its
    // run and both boxes are in that flat region where they meet.
    return ClientAmbientBackground(child: body);
  }
}

class _Tabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ClientRequestsListBloc, ClientRequestsListState>(
        buildWhen: (a, b) => a.tab != b.tab,
        builder: (context, state) => ClientRequestsTabs(
          selected: state.tab,
          // Applied server-side wherever the tab maps to one status;
          // filtering a loaded page would show an arbitrary subset of the
          // matches. See `ClientRequestsListBloc`.
          onSelected: (tab) => context.read<ClientRequestsListBloc>().add(
            ClientRequestsTabChanged(tab),
          ),
        ),
      );
}

class _RequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ClientRequestsListBloc>();
    final shell = StatefulNavigationShell.maybeOf(context);

    return MutationListener<ClientRequestsListBloc, ClientRequestsListState>(
      status: (state) => state.mutation,
      title: (context) => 'client_requests.cancelling_title'.tr(),
      onFailure: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          showAppErrorSnackbar(
            context: context,
            title: failure.localizedSafeMessage(),
          );
        }
        context.read<ClientRequestsListBloc>().add(
          const ClientRequestsMutationAcknowledged(),
        );
      },
      onSuccess: (context, state) => context.read<ClientRequestsListBloc>().add(
        const ClientRequestsMutationAcknowledged(),
      ),
      child: BlocBuilder<ClientRequestsListBloc, ClientRequestsListState>(
        builder: (context, state) {
          final attentionCount = state.needingAttention.length;

          return AppRefreshIndicator(
            onRefresh: () async => bloc.add(const ClientRequestsRefreshed()),
            child: SanadPagedList<ClientRequest>(
              state: toPagingState(state.data),
              fetchNextPage: () =>
                  bloc.add(const ClientRequestsNextPageRequested()),
              // Figma `ScrollBody` (`8385:4385`): 20 horizontal, 12 above the
              // first heading, 20 below the last card.
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              itemBuilder: (context, request, index) => AppListEntrance(
                key: ValueKey(request.id),
                index: index,
                child: _SectionedCard(
                  request: request,
                  // The two headings are positions in one list rather than
                  // two lists: `SanadPagedList` appends pages to a single
                  // sliver, and splitting it in two would need two
                  // paginators over one cursor.
                  heading: switch (index) {
                    0 when attentionCount > 0 => _Heading(
                      label: 'client_requests.section_attention'.tr(),
                      count: attentionCount,
                    ),
                    0 => _Heading(label: state.tab.sectionKey.tr()),
                    _ when index == attentionCount => _Heading(
                      label: state.tab.sectionKey.tr(),
                    ),
                    _ => null,
                  },
                  onTap: () async {
                    await context.push<void>(
                      ClientRequestRoutes.detail(request.id),
                    );
                    // The detail screen can cancel, confirm or dispute the
                    // request, and a timer can move it while it is open.
                    if (context.mounted) {
                      bloc.add(const ClientRequestsRefreshed());
                    }
                  },
                  onCancel: () => _cancel(context, request),
                  // Only reachable from inside the shell, whose first branch
                  // *is* the chat. A pushed `/requests` (a notification tap)
                  // has no chat branch to switch to, so the control is
                  // absent rather than dead.
                  onOpenChat: shell == null ? null : () => shell.goBranch(0),
                  onRebook: shell == null ? null : () => shell.goBranch(0),
                ),
              ),
              separatorBuilder: (_, _) => SizedBox(height: AppSpacing.lg),
              firstPageErrorIndicatorBuilder: (context) => AppGenericEmptyState(
                title: 'client_requests.error_title'.tr(),
                description:
                    state.data.firstPageError?.localizedSafeMessage() ?? '',
              ),
              newPageErrorIndicatorBuilder: (context) => Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: AppButton(
                    label: 'client_requests.retry'.tr(),
                    onPressed: () =>
                        bloc.add(const ClientRequestsNextPageRequested()),
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                  ),
                ),
              ),
              noItemsFoundIndicatorBuilder: (context) => AppGenericEmptyState(
                title: 'client_requests.empty_title'.tr(),
                description: 'client_requests.empty_description'.tr(),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancel(BuildContext context, ClientRequest request) async {
    final bloc = context.read<ClientRequestsListBloc>();
    // The same sheet the detail screen uses — the backend requires a reason of
    // 3–1000 characters and shows it to the provider verbatim, so there is no
    // shortcut version of this from the list.
    final reason = await ReasonSheet.show(
      context,
      title: 'client_requests.cancel_sheet_title'.tr(),
      description: 'client_requests.cancel_sheet_description'.tr(),
      confirmLabel: 'client_requests.cancel_request'.tr(),
      isDestructive: true,
    );
    if (reason == null) return;
    bloc.add(ClientRequestCancelRequested(id: request.id, reason: reason));
  }
}

/// A card, optionally under the heading that opens its section.
class _SectionedCard extends StatelessWidget {
  const _SectionedCard({
    required this.request,
    required this.heading,
    required this.onTap,
    required this.onCancel,
    required this.onOpenChat,
    required this.onRebook,
  });

  final ClientRequest request;
  final Widget? heading;
  final VoidCallback onTap;
  final VoidCallback onCancel;
  final VoidCallback? onOpenChat;
  final VoidCallback? onRebook;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (heading != null) ...[
        heading!,
        // Figma leaves 16 between a heading and the card under it
        // (`8385:4386` → `8385:4391`).
        SizedBox(height: AppSpacing.lg),
      ],
      ClientRequestCard(
        request: request,
        onTap: onTap,
        onCancel: onCancel,
        onOpenChat: onOpenChat,
        onRebook: onRebook,
      ),
    ],
  );
}

/// A section heading, with the red count Figma puts beside "Needs your
/// attention" (`8385:4389`).
class _Heading extends StatelessWidget {
  const _Heading({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.smallNormal.copyWith(
              fontSize: 15.rfs,
              fontWeight: FontWeight.w600,
              color: ClientRequestsTokens.sectionTitle,
            ),
          ),
        ),
        if (count != null) ...[
          SizedBox(width: AppSpacing.sm),
          Container(
            // Figma `Badge` (`8385:4389`): px-6 py-2, radius 10.
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ClientRequestsTokens.attentionBadgePadding,
              vertical: ClientRequestsTokens.attentionBadgePaddingY,
            ),
            decoration: BoxDecoration(
              color: ClientRequestsTokens.attentionBadgeFill,
              borderRadius: BorderRadius.circular(
                ClientRequestsTokens.attentionBadgeRadius,
              ),
            ),
            child: Text(
              '$count',
              style: typography.tinyNormal.copyWith(
                fontSize: 11.rfs,
                fontWeight: FontWeight.w700,
                color: ClientRequestsTokens.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
