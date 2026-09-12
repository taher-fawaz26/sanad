import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/default_ai_chat_suggestions.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_connectivity_service.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_interaction_sink.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/chat_context_cubit.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_chat_bubble.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_transport_banner.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_context_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_context_layer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_layout.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_chat_suggestions.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_hero_visual.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/ui/background/client_ambient_background.dart';

/// The chat surface: conversation, contextual layer and composer.
class AiChatPage extends StatefulWidget {
  /// Creates the chat page.
  const AiChatPage({super.key, this.mockConnectivity, this.onRestart});

  /// Clears the conversation and the journey, back to the opening state.
  ///
  /// Non-null only against the local transport: there is nothing to restart on
  /// a live one, and an affordance that appeared there would be a button that
  /// silently drops a real conversation. Implemented by the screen rather than
  /// here, because a full reset means rebuilding the bloc and the transport —
  /// neither of which this page owns.
  final VoidCallback? onRestart;

  /// Present only against the local transport: lets a debug build flip the
  /// device's apparent connectivity, which is the only way to reach the bloc's
  /// offline queueing path without a real radio. See [MockConnectivityService].
  final MockConnectivityService? mockConnectivity;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  AiUiEnvironment? _environment;

  /// Lets the page ask the contextual layer to move. The layer owns its own
  /// extent; this is only a request channel, and nothing about *whether there
  /// is content* travels through it.
  final AiChatContextController _contextController = AiChatContextController();

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Built once, not per frame: AiUiHost compares environments to decide
    // whether to notify, and a fresh instance every build would invalidate
    // every surface beneath it.
    _environment ??= _buildEnvironment(context.read<AiChatBloc>());
  }

  AiUiEnvironment _buildEnvironment(AiChatBloc bloc) => AiUiEnvironment(
    registry: defaultRendererRegistry(
      // Developers see which component the agent asked for; users never do.
      showUnsupportedMarker: !kReleaseMode,
    ),
    actions: buildAiChatActionRegistry(
      onSendMessage: (text) => bloc.add(AiChatMessageSubmitted(text)),
      // One capability set, always the app's own. The agent's
      // `request_image_upload` reaches the composer's real picker, its
      // `request_location_share` reaches the real map, and its
      // `request_permission` reaches the real platform dialog — whether the
      // reply that asked came from the backend or from the local journey.
      // There is deliberately no mock-only capability class: a photo step that
      // went through a fixture sheet would be the one step of the journey that
      // proved nothing.
      capabilities: const ComposerAiChatCapabilities(),
      // A capability outcome — a granted camera, a refused location — becomes
      // an answer the agent hears, instead of ending in a snackbar it never
      // learns about.
      interactions: AiChatBlocInteractionSink(bloc),
      // So a cancelled location sheet re-enables the card that opened it.
      ledger: bloc.ledger,
    ),
    diagnostics: const LoggingAiUiDiagnosticsSink(),
    interactions: AiChatBlocInteractionSink(bloc),
    // The bloc's, not a fresh one: a card's answered state has to survive
    // scrolling out of the list and back, and a failed send has to be able to
    // re-enable the card it came from.
    ledger: bloc.ledger,
    strings: AiUiStrings(
      metresSuffix: 'ai_chat.unit_metres'.tr(),
      kilometresSuffix: 'ai_chat.unit_kilometres'.tr(),
      unsupportedContent: 'ai_chat.unsupported_content'.tr(),
      // Names a *client* capability — which maps app the tap reaches — so the
      // agent does not author it.
      openInMaps: 'ai_chat.open_in_maps'.tr(),
      ratingOutOfFive: 'ai_chat.rating_out_of_five'.tr(),
      distanceLabel: 'ai_chat.distance_label'.tr(),
      // Client affordances, not agent copy: the verification mark's meaning,
      // the disclosure control's label and the word after a star count are all
      // decisions the renderer makes, so the words come from here.
      verifiedLabel: 'ai_chat.verified_label'.tr(),
      showMoreLabel: 'ai_chat.show_more'.tr(),
      showLessLabel: 'ai_chat.show_less'.tr(),
      ratingStarsLabel: 'ai_chat.rating_stars'.tr(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final environment = _environment;
    if (environment == null) return const SizedBox.shrink();

    // No app bar and no header here: as a branch of `AiHomeShell`, the
    // profile/nav-pill/history row is the shell's persistent chrome, built
    // once above every branch rather than duplicated into this one.
    //
    // The background is split across two owners, by what each half needs to
    // know. The *static* wash is `AiHomeShell`'s, because it has to span the
    // header this page starts below. The *animated* landing glow is this
    // page's, because only it depends on whether a conversation has started —
    // and `AiChatBloc`, which answers that, is scoped to this branch rather
    // than the shell.
    //
    // Both animated layers are `IgnorePointer`-wrapped and read one boolean
    // of Bloc state apiece, so neither a streaming token nor a composer tick
    // reaches them.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Layer 0: the same static wash the shell paints.
          //
          // A second instance, not a mistake: go_router gives every shell
          // branch its own opaque page, so the shell's wash stops dead at the
          // header and the branch below it renders flat white — which is why
          // the conversation had no green at all. The two do not seam,
          // because Figma's gradient holds a flat `#F9F9FA` until 59% of its
          // run, and both boxes are in that flat region where they meet.
          const Positioned.fill(
            child: ClientAmbientBackground(child: SizedBox()),
          ),
          // Layer 1: the landing state's drifting glow, over the wash and
          // under everything else. Only the landing state animates — see
          // `_LandingAmbience`.
          const Positioned.fill(child: _LandingAmbience()),
          // Layer 2: the conversation itself.
          AiUiHost(
            environment: environment,
            child: BlocListener<AiChatBloc, AiChatState>(
              // Transport and agent failures are transient, not part of the
              // conversation: a snackbar says so without leaving a
              // permanent error bubble in the history the user then has to
              // scroll past.
              // Compares the failure's *id*, not its text. Two identical
              // failures in a row carry different ids, so the second one
              // still reads as a change and still reaches the user — keying
              // this off the message left every repeat silent (A-03).
              listenWhen: (previous, current) =>
                  previous.failure?.id != current.failure?.id &&
                  current.failure != null,
              listener: (context, state) => showAppErrorSnackbar(
                context: context,
                title: _resolveFailureText(state.failure!.message),
              ),
              child: BlocListener<AiComposerBloc, AiComposerState>(
                // The composer's own failures — a refused permission, a
                // file that is too large — are transient and belong in a
                // snackbar. The notice carries a fresh id per occurrence,
                // so two identical failures in a row both surface.
                listenWhen: (previous, current) =>
                    previous.notice != current.notice && current.notice != null,
                listener: _onComposerNotice,
                // Three layers, one layout pass, and the z-order the
                // contextual layer depends on: the conversation fills the
                // space above the composer, the layer is painted *between* the
                // two, and the composer is painted last so it stays above the
                // layer — and stays interactive — at every extent. A `Column`
                // could not paint anything between its own children; a `Stack`
                // could not know how tall the composer is. See `AiChatLayout`.
                child: AiChatLayout(
                  conversation: Column(
                    children: [
                      // Above the transcript, not inside it: the connection is
                      // a property of the whole conversation rather than of
                      // one turn, and a banner that scrolled away with the
                      // messages would stop answering "why is nothing
                      // sending?".
                      const _TransportBanner(),
                      // One slot, two compositions. The hero and the
                      // transcript are alternatives, never neighbours, so they
                      // share the same flexible region rather than the hero
                      // floating over the conversation in a `Stack`.
                      //
                      // That also fixes the hero and the suggestions colliding
                      // when the keyboard opens: as a `Stack` overlay the hero
                      // was positioned against the whole body and simply
                      // overlapped whatever the shrinking `Column` pushed up
                      // into it. Sharing the slot means the keyboard takes its
                      // space out of the hero, which is the part that can
                      // afford to give it.
                      const Expanded(child: _ConversationOrHero()),
                      // In the conversation slot rather than the composer's,
                      // so the context layer covers it as it rises. Anything
                      // in the composer slot is painted above the layer at
                      // every extent — which is right for the composer and
                      // wrong for a control that is not part of it.
                      if (widget.onRestart != null)
                        _RestartControl(onRestart: widget.onRestart!),
                    ],
                  ),
                  // Reads `ChatContextCubit` and nothing else, and is absent
                  // entirely when there is nothing to offer. Dragging it moves
                  // an `AnimationController` inside the layer — no bloc state
                  // changes, so the transcript above never rebuilds.
                  context: _ContextLayer(controller: _contextController),
                  composer: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Suggestions(onSelected: (text) => _send(context, text)),
                      AiComposer(
                        onSend: (text) => _send(context, text),
                        onVoice: () => _openVoice(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onComposerNotice(BuildContext context, AiComposerState state) {
    final notice = state.notice!;
    // Not everything the composer says is a failure, so the tone decides
    // which snackbar renders it: guidance must not arrive in the error
    // snackbar's red and tell the user they broke something.
    switch (notice.tone) {
      case AiNoticeTone.error:
        showAppErrorSnackbar(context: context, title: notice.messageKey.tr());
      case AiNoticeTone.info:
        showAppSnackbar(
          context: context,
          title: notice.messageKey.tr(),
          duration: const Duration(seconds: 2),
        );
    }
    context.read<AiComposerBloc>().add(const AiComposerNoticeDismissed());
  }

  /// Sends the turn, then clears the composer.
  ///
  /// The page is where the two blocs meet: the composer owns the attachments,
  /// the conversation owns the message. Neither reaches into the other — this
  /// is the composition root's job, which is why it lives here and not in a
  /// leaf widget.
  ///
  /// Only `ready` attachments travel, so the submit handler never waits on
  /// preparation — it runs under `droppable()`, and a wider await window there
  /// would silently swallow the user's next tap.
  /// Opens the live-voice route.
  ///
  /// A push, so this screen — and with it the conversation, its blocs and its
  /// event source — stays alive underneath. Coming back returns to the same
  /// conversation rather than starting a second one.
  ///
  /// Nothing is released on the way out. The composer owns no audio at all any
  /// more — its microphone capability is speech recognition, and the live-voice
  /// button is not on screen while that is running — so there is no session for
  /// the voice route's own duplex one to fight over.
  void _openVoice(BuildContext context) => context.push(AiChatRoutes.voice);

  void _send(BuildContext context, String text) {
    final composer = context.read<AiComposerBloc>();
    final attachments = composer.state.readyAttachments;
    if (text.isEmpty && attachments.isEmpty) return;

    context.read<AiChatBloc>().add(
      AiChatMessageSubmitted(text, attachments: attachments),
    );
    composer.add(const AiComposerSubmitted());
  }

  /// Same rule the shared `FailureLocalizer` applies: a dotted lower-snake
  /// string is one of our own keys and gets translated; anything else is the
  /// agent's own prose and is shown verbatim.
  String _resolveFailureText(String message) =>
      RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+)+$').hasMatch(message)
      ? message.tr()
      : message;
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    final activeStream = context.read<AiChatBloc>().activeStream;

    return BlocBuilder<AiChatBloc, AiChatState>(
      // Only list-shaped changes rebuild the list. Token deltas never emit
      // state at all, so they cannot reach here.
      buildWhen: (previous, current) =>
          previous.messages != current.messages ||
          previous.isTyping != current.isTyping,
      builder: (context, state) {
        // No `AppEmptyState` illustration here any more: the AI center visual
        // and the suggestions row are the empty state now, per Figma. The
        // hero occupies this same slot while the conversation is empty
        // (`_ConversationOrHero`), so this returning nothing is what lets the
        // switch between the two compositions be a clean swap rather than two
        // competing illustrations.
        if (state.showsLanding) return const SizedBox.shrink();

        final rows = state.messages.reversed.toList();

        return ListView.separated(
          // Reversed so new messages appear at the bottom without the list
          // re-laying-out the whole conversation each time one arrives.
          reverse: true,
          // Figma `7137:30407`: 20dp gutters, 24dp between turns.
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          itemCount: rows.length + (state.isTyping ? 1 : 0),
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.xxl),
          itemBuilder: (context, index) {
            if (state.isTyping && index == 0) return const _TypingIndicator();
            final message = rows[index - (state.isTyping ? 1 : 0)];

            // A stable key plus a repaint boundary: an unchanged bubble is
            // neither rebuilt nor repainted when its neighbours change.
            // `AppListEntrance` wraps the boundary, not its contents, and
            // plays once per `ValueKey(message.id)` — so it never touches
            // `ActiveStreamController`/the per-token text rebuild below it:
            // a freshly-loaded history batch gets a bounded stagger, and the
            // common case (one new message arriving at index 0) gets a
            // single, immediate, un-delayed reveal.
            return AppListEntrance(
              key: ValueKey(message.id),
              index: index,
              child: RepaintBoundary(
                child: AiChatBubble(
                  message: message,
                  activeStream: activeStream,
                  // Only a failed or queued user turn gets one; the bubble
                  // ignores it otherwise. A queued turn is retryable because
                  // tapping it re-checks the radio, which is a real "try now"
                  // rather than a second attempt at the same failure.
                  onRetry: message.status.isRetryable
                      ? () => context.read<AiChatBloc>().add(
                          AiChatMessageRetryRequested(message.id),
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The AI center visual — Figma `Chat – 01 Home`'s hero mark (`7118:29598`).
///
/// Shown only while the screen is in its landing composition, and **removed
/// from the tree** — not merely faded to zero opacity — once a conversation
/// starts. Figma has no hero behind the transcript, and a hidden-but-mounted
/// Lottie would keep a ticker driving repaints for something nobody can see.
///
/// The `buildWhen` is the whole point of the split: this rebuilds on exactly
/// one boolean flip per conversation (landing → chat), so streaming tokens,
/// composer ticks and message appends never reach the animation. `AppLottie`
/// then isolates its own repaints in a `RepaintBoundary` and freezes under
/// reduced motion, since this is decorative identity rather than progress.
/// The landing state's drifting green glow — the *animated* half of the AI
/// surface's background, over the shell's static wash.
///
/// The two page states have deliberately different background behaviour:
/// landing is alive, the conversation is still. A transcript is something you
/// read, and ambient motion behind text is the wrong kind of alive — so this
/// layer is removed outright once a turn begins.
///
/// Removed, not paused: swapping the widget out is what actually stops the
/// ticker. An `AppAmbientGradient` left mounted with animation disabled would
/// keep a vsync callback alive behind every conversation for nothing.
///
/// ## Isolation
///
/// It subscribes to exactly one boolean and owns no other state, so a flip
/// rebuilds this subtree alone. `AppAmbientGradient` keeps its controller and
/// its `RepaintBoundary` internally, so a tick here never reaches the message
/// list or the composer, and no animation value passes through a Bloc.
class _LandingAmbience extends StatelessWidget {
  const _LandingAmbience();

  @override
  Widget build(BuildContext context) => BlocBuilder<AiChatBloc, AiChatState>(
    buildWhen: (previous, current) =>
        previous.showsLanding != current.showsLanding,
    builder: (context, state) => IgnorePointer(
      child: state.showsLanding
          ? AppAmbientGradient(color: context.appColors.primary)
          : const SizedBox.shrink(),
    ),
  );
}

class _ConversationOrHero extends StatelessWidget {
  const _ConversationOrHero();

  @override
  Widget build(BuildContext context) => BlocBuilder<AiChatBloc, AiChatState>(
    buildWhen: (previous, current) =>
        previous.showsLanding != current.showsLanding,
    builder: (context, state) => AnimatedSwitcher(
      duration: AppMotionDuration.emphasis,
      switchInCurve: AppMotionCurve.standard,
      switchOutCurve: AppMotionCurve.standard,
      child: state.showsLanding
          // Not tappable, and it must never eat a tap meant for the list
          // that replaces it.
          ? const IgnorePointer(child: Center(child: _HeroFitted()))
          : const _MessageList(),
    ),
  );
}

/// Scales the hero down when the slot is shorter than it wants — which is
/// exactly what happens when the keyboard opens on a small screen.
///
/// `scaleDown` rather than `contain`: at full size it must stay at Figma's
/// dimensions and not grow to fill a tall screen; only a genuinely cramped
/// slot shrinks it.
class _HeroFitted extends StatelessWidget {
  const _HeroFitted();

  @override
  Widget build(BuildContext context) => const FittedBox(
    fit: BoxFit.scaleDown,
    child: AiHeroVisual(),
  );
}

/// Starter prompts shown only while the conversation is empty and the
/// composer is doing nothing else — Figma `quick-suggestions` (`5153:42722`).
///
/// Two narrow `BlocBuilder`s rather than one wide one: each rebuilds only on
/// the one boolean it actually needs (conversation emptiness, composer
/// idleness), so neither a streaming token nor a composer tick ever reaches
/// this far — the same discipline `_MessageList`'s own `buildWhen` applies.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onSelected});

  /// Called with the suggestion's localized text — the same shape the send
  /// handler already accepts, so a tap here is indistinguishable from typing
  /// the same words and pressing send.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => BlocBuilder<AiChatBloc, AiChatState>(
    buildWhen: (previous, current) =>
        previous.showsLanding != current.showsLanding,
    builder: (context, chatState) {
      if (!chatState.showsLanding) return const SizedBox.shrink();

      return BlocBuilder<AiComposerBloc, AiComposerState>(
        buildWhen: (previous, current) => previous.isIdle != current.isIdle,
        builder: (context, composerState) {
          if (!composerState.isIdle) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: AiChatSuggestions(
              suggestions: defaultAiChatSuggestions,
              onSelected: (suggestion) => onSelected(suggestion.labelKey.tr()),
            ),
          );
        },
      );
    },
  );
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: AppRadius.circularMd,
        border: Border.all(color: context.appColors.border),
      ),
      child: Semantics(
        label: 'ai_chat.typing'.tr(),
        liveRegion: true,
        child: const AppLoadingIndicator(size: 20),
      ),
    ),
  );
}

/// Reads the two transport flags off the bloc and hands them to
/// [AiTransportBanner].
///
/// A `BlocSelector` over exactly those two booleans, so a streaming token — or
/// any other message-list change — cannot rebuild the banner.
class _TransportBanner extends StatelessWidget {
  const _TransportBanner();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AiChatBloc, AiChatState, (bool, bool)>(
        selector: (state) => (state.isOffline, state.hasUndeliveredMessage),
        builder: (context, flags) => AiTransportBanner(
          isOffline: flags.$1,
          hasUndeliveredMessage: flags.$2,
        ),
      );
}

/// Bridges `ChatContextCubit` to the presentation-only context layer.
///
/// The one place that knows both halves, and deliberately thin: the cubit says
/// *whether there is content and what it is*, the layer says *how it moves*,
/// and neither knows the other exists. When there is nothing on offer this
/// returns null through [AiChatLayout.context], so the layer is not in the tree
/// at all and the chat looks exactly as it does with no context.
///
/// The body is an `AiUiSurface` over the agent's own document — the same
/// renderer the transcript uses, reading the same environment and the same
/// interaction ledger from the `AiUiHost` above. That is what makes a provider
/// card in here the *same* card, answerable once, rather than a copy of one.
class _ContextLayer extends StatelessWidget {
  const _ContextLayer({required this.controller});

  final AiChatContextController controller;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ChatContextCubit, ChatContextState>(
        builder: (context, state) {
          final content = state.content;
          if (content == null) return const SizedBox.shrink();

          return AiChatContextLayer(
            // Keyed on the payload id so replacing the content swaps the
            // subtree outright rather than diffing one document's widgets onto
            // another's.
            key: ValueKey(content.id),
            controller: controller,
            peekLabel: content.peekLabel,
            // Figma's 12 dp between the two offer cards.
            child: AiUiSurface(document: content.document, gap: AppSpacing.md),
          );
        },
      );
}

/// Starts a fresh conversation.
///
/// Present only against the local transport, and only in a debug build: the
/// route itself does not exist in release. One control, not a picker — there is
/// one journey and nothing to choose between, and the thing most likely to be
/// needed between two run-throughs is a clean start.
///
/// It is the page's only mock-aware affordance, and it shows nothing about the
/// mock: a conversation you can restart is an ordinary thing for a chat to
/// offer.
class _RestartControl extends StatelessWidget {
  const _RestartControl({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: AppSpacing.xl,
      end: AppSpacing.xl,
      bottom: AppSpacing.sm,
    ),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppChip(
        label: 'ai_chat.restart_conversation'.tr(),
        style: AppChipStyle.outline,
        icon: const Icon(Icons.restart_alt_rounded),
        onTap: onRestart,
      ),
    ),
  );
}
