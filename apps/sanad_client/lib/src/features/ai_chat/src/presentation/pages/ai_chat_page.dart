import 'dart:math' as math;

import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/default_ai_chat_suggestions.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_connectivity_service.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_interaction_sink.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_chat_bubble.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_transport_banner.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_chat_suggestions.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/ui/background/client_ambient_background.dart';

/// The chat surface: message list, scenario picker and composer.
class AiChatPage extends StatefulWidget {
  /// Creates the chat page.
  const AiChatPage({super.key, this.mockSource, this.mockConnectivity});

  /// Present only in the prototype: lets the dev scenario picker force a
  /// specific scripted reply. A production source would not expose this.
  final MockAiChatEventSource? mockSource;

  /// Present only in the prototype: lets the dev picker flip the device's
  /// apparent connectivity, which is the only way to reach the offline
  /// queueing path without a real radio. See [MockConnectivityService].
  final MockConnectivityService? mockConnectivity;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  AiUiEnvironment? _environment;
  String? _selectedScenarioId;

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
      // The agent's `request_image_upload` now reaches the composer's real
      // picker instead of a "coming soon" snackbar.
      capabilities: const ComposerAiChatCapabilities(),
      // A capability outcome — a granted camera, a refused location — becomes
      // an answer the agent hears, instead of ending in a snackbar it never
      // learns about.
      interactions: AiChatBlocInteractionSink(bloc),
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

  void _selectScenario(String? id) {
    setState(() => _selectedScenarioId = id);
    widget.mockSource?.forcedScenarioId = id;
  }

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
                child: Column(
                  children: [
                    // Above the transcript, not inside it: the connection is a
                    // property of the whole conversation rather than of one
                    // turn, and a banner that scrolled away with the messages
                    // would stop answering "why is nothing sending?".
                    const _TransportBanner(),
                    // One slot, two compositions. The hero and the transcript
                    // are alternatives, never neighbours, so they share the
                    // same flexible region rather than the hero floating over
                    // the conversation in a `Stack`.
                    //
                    // That also fixes the hero and the suggestions colliding
                    // when the keyboard opens: as a `Stack` overlay the hero
                    // was positioned against the whole body and simply
                    // overlapped whatever the shrinking `Column` pushed up
                    // into it. Sharing the slot means the keyboard takes its
                    // space out of the hero, which is the part that can
                    // afford to give it.
                    const Expanded(child: _ConversationOrHero()),
                    if (widget.mockSource != null)
                      _ScenarioPicker(
                        selectedId: _selectedScenarioId,
                        onSelected: _selectScenario,
                        connectivity: widget.mockConnectivity,
                      ),
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
    child: _AiCenterVisual(),
  );
}

/// The hero mark itself — Figma `Frame 427319459` (`7118:29598`): the green
/// bloom with Sanad's sparkle riding on it, which together read as one
/// visual.
///
/// ## Two halves, two sources
///
/// The **bloom is the Lottie** (`AppLottie.aiAssistant` →
/// `AppAnimations.aiAssistantLoading`): a rotating aura ring behind an orb
/// that fades up, looping every 5s. That file used to paint an empty box
/// because its image layers had no images in this package — the supplied
/// dotLottie carried them, and they are now recoloured and embedded in the
/// composition itself, so it renders from that one file.
///
/// The **mark is not in the Lottie**. That animation is a bloom and nothing
/// else: no sparkle, no check. So Figma's own exported mark still rides on
/// top — [AppSvgs.aiChatHeroMark] is the node's exact asset, and the geometry
/// below is transcribed from the node.
///
/// The hand-written breathe that used to wrap this is gone: the Lottie owns
/// the hero's motion now, and a second rhythm on top of it would read as two
/// animations rather than one visual. `AppLottie` keeps the reduced-motion
/// contract (frozen to frame one, since this is identity rather than
/// progress) and its own `RepaintBoundary`.
class _AiCenterVisual extends StatelessWidget {
  const _AiCenterVisual();

  /// Figma's hero frame is 200dp square, with the mark at ~93.8 x 91.8
  /// centred and nudged 6.95dp above centre (`7118:29600`).
  static const _markWidth = 93.77;
  static const _markHeight = 91.82;
  static const _markOffsetY = -6.95;

  /// The composition is drawn larger than the box it occupies, because most
  /// of its 512-square canvas is empty: the widest painted element (the aura
  /// ring) spans only ~59% of it, and the orb ~37%.
  ///
  /// Sized by measurement rather than by eye. Figma's bloom measures ~145dp
  /// of green across the mark's centre line (`7118:29598`, thresholded the
  /// same way); rendering the file at its own 340 gave 109dp on device, so
  /// the canvas is drawn at [_compositionSize] to land on Figma's figure.
  /// Everything painted still fits inside [_bloomSize] — 266dp of content in
  /// a 280dp box — so nothing is clipped and only dead margin falls outside.
  ///
  /// Reserving the full 452 as layout would have been worse than useless:
  /// `_HeroFitted` would scale it back down to the slot and give the 109dp
  /// bloom straight back.
  static const _bloomSize = 280.0;
  static const _compositionSize = 452.0;

  /// Figma applies a 179.66° rotation to the mark inside this node.
  static const double _markTurns = 179.66 / 360;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _bloomSize,
    child: Stack(
      alignment: Alignment.center,
      children: [
        OverflowBox(
          maxWidth: _compositionSize,
          maxHeight: _compositionSize,
          child: AppLottie.aiAssistant(size: _compositionSize),
        ),
        Transform.translate(
          offset: const Offset(0, _markOffsetY),
          child: Transform.rotate(
            angle: _markTurns * 2 * math.pi,
            child: SvgPicture.asset(
              AppSvgs.aiChatHeroMark,
              package: AppAssets.package,
              width: _markWidth,
              height: _markHeight,
            ),
          ),
        ),
      ],
    ),
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

/// Prototype-only affordance for replaying a specific scripted reply,
/// including the deliberately broken ones.
class _ScenarioPicker extends StatefulWidget {
  const _ScenarioPicker({
    required this.selectedId,
    required this.onSelected,
    this.connectivity,
  });

  final String? selectedId;
  final void Function(String? id) onSelected;

  /// The fake radio, when this visit has one.
  final MockConnectivityService? connectivity;

  @override
  State<_ScenarioPicker> createState() => _ScenarioPickerState();
}

class _ScenarioPickerState extends State<_ScenarioPicker> {
  /// Extra leading chips before the scenarios: keyword-driven replay, a way
  /// into the component showcase, and — when this visit owns a fake radio —
  /// the offline toggle.
  int get _leadingChips => widget.connectivity == null ? 2 : 3;

  void _toggleOffline() {
    final connectivity = widget.connectivity;
    if (connectivity == null) return;
    setState(() => connectivity.isOffline = !connectivity.isOffline);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: mockScenarios.length + _leadingChips,
      separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppChip(
            label: 'ai_chat.scenario_auto'.tr(),
            selected: widget.selectedId == null,
            style: AppChipStyle.outline,
            onTap: () => widget.onSelected(null),
          );
        }
        if (index == 1) {
          // The showcase is where a design change gets reviewed; reaching it
          // from here means it needs no entry point of its own.
          return AppChip(
            label: 'ai_chat.showcase_open'.tr(),
            style: AppChipStyle.outline,
            icon: const Icon(Icons.grid_view_rounded),
            onTap: () => context.push(AiChatRoutes.showcase),
          );
        }
        if (index == 2 && widget.connectivity != null) {
          // The offline edge case's fixture. It is a chip rather than a
          // scenario because a scenario builds *assistant events*, and there
          // are none: losing signal is a device fact. Everything after the
          // flip is the real path — the bloc queues, the banner appears, and
          // flipping back flushes.
          return AppChip(
            label: 'ai_chat.scenario_offline'.tr(),
            selected: widget.connectivity!.isOffline,
            style: AppChipStyle.outline,
            icon: const Icon(Icons.wifi_off_rounded),
            onTap: _toggleOffline,
          );
        }
        final scenario = mockScenarios[index - _leadingChips];
        return AppChip(
          label: scenario.label,
          selected: widget.selectedId == scenario.id,
          style: AppChipStyle.outline,
          onTap: () => widget.onSelected(scenario.id),
        );
      },
    ),
  );
}
