import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/features/history/src/data/mock_conversation_history_source.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_source.dart';
import 'package:sanad_client/src/features/history/src/domain/filter_conversation_history.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_tokens.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_card.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_nav_bar.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_placeholder.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_search_field.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_start_button.dart';
import 'package:sanad_client/src/ui/background/client_ambient_background.dart';

/// Conversation History — Figma `8120:2918` (with conversations) and
/// `8124:3867` (without).
///
/// **One screen, two renderings.** Which one appears is decided by the data
/// and nothing else: an empty collection is the empty state. There is no
/// second route, no flag on this widget, and no branch anywhere above it —
/// which is what makes the real repository a drop-in later, since "the user
/// has no history" is simply what it will return.
///
/// Reached by push from the Home header, on top of `AiHomeShell` rather than
/// inside one of its branches, so it covers the whole shell — including the
/// persistent header, which is why this page draws navigation of its own.
/// It repaints `ClientAmbientBackground` for the same reason `AiChatPage`
/// does: a pushed route gets its own opaque page, so without the wash here the
/// screen would render flat white and lose the green Figma puts along the
/// bottom.
///
/// No bloc. The screen loads a list once and filters it in memory; there is
/// no async lifecycle to model, no mutation to guard and no failure to
/// surface. When the history endpoint lands, whether that arrives as a bloc
/// is a question about *that* work — everything this widget touches is behind
/// [ConversationHistorySource].
class HistoryPage extends StatefulWidget {
  /// Creates the page.
  const HistoryPage({
    this.source = const MockConversationHistorySource(),
    this.onConversationSelected,
    super.key,
  });

  /// Where the entries come from. Defaults to the local mock fixtures; the
  /// dev route passes one configured from `?state=`.
  final ConversationHistorySource source;

  /// Called when a conversation is tapped.
  ///
  /// The interaction boundary for work that does not exist yet: nothing in
  /// the app can open a *stored* conversation — the chat route starts a fresh
  /// one and the AI transport has no conversation id — so there is no route
  /// to send this to, and inventing one would mean guessing the contract the
  /// backend has not defined. Left `null` on the dev route, so a tap is inert
  /// rather than misleading.
  final ValueChanged<ConversationHistoryEntry>? onConversationSelected;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// Loaded once, in `initState`: the source is a local list today, and
  /// re-reading it per build would be work for nothing.
  late final List<ConversationHistoryEntry> _entries;

  late final TextEditingController _searchController;

  /// The live query, as a notifier rather than `setState` state.
  ///
  /// A keystroke has to rebuild the results and nothing else. Held in
  /// `State`, every character would also rebuild the background, the nav bar
  /// and the search field itself — the field would rebuild *from* its own
  /// `onChanged`, which is exactly the churn a list of cards should not pay
  /// for.
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _entries = widget.source.load();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Figma draws the search field only alongside a populated list: the empty
    // state (`8124:3867`) has nothing to search, and offering a box that can
    // only ever return nothing is worse than not offering one.
    final hasHistory = _entries.isNotEmpty;

    return Scaffold(
      // Transparent so the wash below is the page's only background — the
      // same arrangement `AiHomeShell` and `AiChatPage` use.
      backgroundColor: Colors.transparent,
      body: ClientAmbientBackground(
        // `bottom: false`: the list and the bottom bar apply the bottom inset
        // themselves, so the wash still runs to the physical edge as Figma
        // draws it.
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Figma's `header-group` gap between the status bar and the nav
              // row, and again between the nav row and the content.
              SizedBox(height: AppSpacing.md),
              ConversationHistoryNavBar(onBack: () => context.pop()),
              SizedBox(height: AppSpacing.md),
              if (hasHistory)
                Padding(
                  // Figma `8102:35059`: `px-[20px] py-[8px]`.
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: ConversationHistorySearchField(
                    controller: _searchController,
                    onChanged: (value) => _query.value = value,
                  ),
                ),
              Expanded(
                child: hasHistory
                    ? ValueListenableBuilder<String>(
                        valueListenable: _query,
                        builder: (context, query, _) =>
                            _buildResults(context, query),
                      )
                    : _EmptyHistory(onStart: () => _startConversation(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The populated state's body: the matching cards, or the same empty
  /// composition with search-specific copy when a query matches none.
  Widget _buildResults(BuildContext context, String query) {
    final matches = filterConversationHistory(_entries, query);

    if (matches.isEmpty) {
      return _CentredPlaceholder(
        child: ConversationHistoryPlaceholder(
          title: 'history.no_results_title'.tr(),
          description: 'history.no_results_description'.tr(),
        ),
      );
    }

    return ListView.separated(
      // Figma `8102:35063`: `px-[20px] py-[12px]`, plus the bottom inset the
      // `SafeArea` above deliberately left to the scrollable.
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md + MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: matches.length,
      // Figma `gap-[12px]` between cards.
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final entry = matches[index];
        return ConversationHistoryCard(
          // Keyed by conversation, not by index, so filtering the list
          // re-parents the surviving cards instead of rebuilding every row
          // into a different entry's slot.
          key: ValueKey(entry.id),
          entry: entry,
          onTap: () => widget.onConversationSelected?.call(entry),
        );
      },
    );
  }

  /// Figma's CTA target: the AI chat conversation entry point.
  ///
  /// `go`, not `push`: this is the *existing* chat route, and History is a
  /// pushed excursion on top of the shell that owns it. Pushing would stack a
  /// second chat above the one already there and leave "back" returning to an
  /// empty history the user has just left.
  void _startConversation(BuildContext context) =>
      context.go(AiChatRoutes.chat);
}

/// Figma `8124:3867` — the illustration and copy, with the CTA pinned to the
/// bottom bar beneath it.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: _CentredPlaceholder(
          child: ConversationHistoryPlaceholder(
            title: 'history.empty_title'.tr(),
            description: 'history.empty_description'.tr(),
          ),
        ),
      ),
      Padding(
        // Figma `bottom-bar` (`8124:3953`): `px-[24px] pt-[12px] pb-[8px]`,
        // above the home indicator the inset stands in for.
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.sm + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: ConversationHistoryStartButton(
          label: 'history.start_conversation'.tr(),
          onPressed: onStart,
        ),
      ),
    ],
  );
}

/// Centres [child] in the space available, and lets it scroll when there is
/// not enough of it.
///
/// `SliverFillRemaining` rather than a `Center`: a `Center` inside a scroll
/// view gets no extra height to centre within, and a bare `Center` cannot
/// scroll — which at a large accessibility text scale means a clipped
/// illustration and unreachable copy.
class _CentredPlaceholder extends StatelessWidget {
  const _CentredPlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        // Figma `8124:3831`: `px-[24px] pt-[72px] pb-[56px]`.
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.xxl,
          responsiveDimension(ConversationHistoryTokens.emptyPaddingTop),
          AppSpacing.xxl,
          responsiveDimension(ConversationHistoryTokens.emptyPaddingBottom),
        ),
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: child),
        ),
      ),
    ],
  );
}
