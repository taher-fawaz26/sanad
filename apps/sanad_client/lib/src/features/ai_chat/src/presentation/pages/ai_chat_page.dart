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
import 'package:sanad_client/src/features/ai_chat/src/data/mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_interaction_sink.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_chat_bubble.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_chat_background.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_chat_suggestions.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';

/// The chat surface: message list, scenario picker and composer.
class AiChatPage extends StatefulWidget {
  /// Creates the chat page.
  const AiChatPage({super.key, this.mockSource});

  /// Present only in the prototype: lets the dev scenario picker force a
  /// specific scripted reply. A production source would not expose this.
  final MockAiChatEventSource? mockSource;

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
          const Positioned.fill(child: AiChatBackground(child: SizedBox())),
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
              listenWhen: (previous, current) =>
                  previous.failureMessage != current.failureMessage &&
                  current.failureMessage != null,
              listener: (context, state) => showAppErrorSnackbar(
                context: context,
                title: _resolveFailureText(state.failureMessage!),
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
    // Not everything the composer says is a failure. "Hold the microphone to
    // record" is coaching, and it fires on every accidental tap — rendering
    // that in the error snackbar's red would tell the user they broke
    // something each time they brushed the button.
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
  /// Playback stops first: the voice route brings up its own audio session for
  /// a duplex call, and leaving a voice note playing underneath it would mean
  /// two sessions competing for the same speaker.
  void _openVoice(BuildContext context) {
    context.read<AiComposerBloc>()
      ..add(const AiComposerPlaybackStopped())
      // A locked take keeps recording with nobody holding it, including
      // across a push. The voice route brings up its own duplex audio
      // session and the two would fight over the microphone, so the take is
      // discarded here rather than left to fail there. A held take cannot
      // reach this — the live-voice button is not on screen while one is
      // running — but a locked one can, which is exactly what locking is for.
      ..add(const AiComposerRecordingCancelled());
    context.push(AiChatRoutes.voice);
  }

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
            return RepaintBoundary(
              key: ValueKey(message.id),
              child: AiChatBubble(
                message: message,
                activeStream: activeStream,
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
/// ## Why this is not a Lottie
///
/// It should be, and the wiring for one is still in place
/// (`AppLottie.aiAssistant`). Neither available export can render it:
///
/// - The authored export registered at `AppAnimations.aiAssistantLoading`
///   draws entirely through image layers whose PNGs are not in this package,
///   so it paints an empty box (see that constant's own doc).
/// - `source/ai_logo_foriday.json` is vector and does render — but its layers
///   are named `bubble`, and it is an iridescent soap bubble, not Sanad's
///   mark. Wrong artwork renders worse than none.
///
/// So the hero is composed from Figma's own exported mark plus its own
/// documented motion, and nothing here is invented: [AppSvgs.aiChatHeroMark]
/// is the node's exact asset, the geometry below is transcribed from the
/// node, and the breathe is Figma's published keyframe track for it.
/// Swapping a corrected Lottie back in later replaces one widget.
class _AiCenterVisual extends StatelessWidget {
  const _AiCenterVisual();

  /// Figma's hero frame is 200dp square, with the mark at ~93.8 x 91.8
  /// centred and nudged 6.95dp above centre (`7118:29600`).
  static const _markWidth = 93.77;
  static const _markHeight = 91.82;
  static const _markOffsetY = -6.95;

  /// The bloom is painted a little past Figma's 200dp frame so its falloff
  /// completes before the edge — clipping it exactly at 200 would turn the
  /// wash into a visible disc. Not much past it, though: at 320 the glow
  /// spread most of the screen's width and went so pale that the mark looked
  /// unlit, where Figma keeps a compact, clearly-green core around it.
  static const _bloomSize = 240.0;

  /// Figma applies a 179.66° rotation to the mark inside this node.
  static const double _markTurns = 179.66 / 360;

  @override
  Widget build(BuildContext context) {
    final primary = context.appColors.primary;

    return _HeroBreathe(
      child: SizedBox.square(
        dimension: _bloomSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Figma builds the wash from two large blurred shapes; a radial
            // gradient is the same result with far less to composite, and it
            // takes its color from the theme rather than baking the brand
            // green into an export that a palette change would strand.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Figma's bloom is a saturated green core that falls away
                // fast, not an even haze — at lower alphas the mark read as
                // unlit and the glow disappeared into the page.
                //
                // Four stops rather than three: with a single midpoint the
                // falloff was linear enough to read as the edge of a disc.
                // Front-loading the decay keeps the core strong while the
                // outer half fades to nothing, which is what makes it a cloud.
                gradient: RadialGradient(
                  colors: [
                    primary.withValues(alpha: 0.70),
                    primary.withValues(alpha: 0.44),
                    primary.withValues(alpha: 0.14),
                    primary.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.32, 0.62, 1],
                ),
              ),
              child: const SizedBox.expand(),
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
      ),
    );
  }
}

/// The hero's idle breathe — Figma's own published keyframe track for
/// `7118:29598`: a 4s infinite loop easing opacity `0.85 → 1 → 0.85` and
/// scale `1 → 1.02 → 1`.
///
/// Transcribed, not invented: those are the exact values and duration Figma
/// reports for this node, which is why the motion is as slight as it is —
/// the hero is meant to feel alive without competing with the composer.
///
/// A `StatefulWidget` with its own controller rather than anything in a
/// Bloc: this ticks 60 times a second, and high-frequency animation values
/// never belong in Bloc state. The controller drives a
/// `AnimatedBuilder`/`FadeTransition` pair beneath a `RepaintBoundary`, so
/// each tick repaints this subtree alone.
class _HeroBreathe extends StatefulWidget {
  const _HeroBreathe({required this.child});

  final Widget child;

  @override
  State<_HeroBreathe> createState() => _HeroBreatheState();
}

class _HeroBreatheState extends State<_HeroBreathe>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(seconds: 4);
  static const _minOpacity = 0.85;
  static const _maxScale = 1.02;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  late final CurvedAnimation _pulse = CurvedAnimation(
    parent: _controller,
    // 0 → 1 → 0 across the period, so one controller drives both halves of
    // the loop and the midpoint lands exactly at 50% as Figma specifies.
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Decorative motion: reduced motion pins it to the resting frame rather
    // than breathing, matching how `AppLottie` treats decorative animations.
    if (AppMotion.reduceMotionOf(context)) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        // The subtree is built once and passed through — the builder only
        // re-wraps it, so the SVG is not rebuilt on every tick.
        child: widget.child,
        builder: (context, child) => Opacity(
          opacity: _minOpacity + (1 - _minOpacity) * _pulse.value,
          child: Transform.scale(
            scale: 1 + (_maxScale - 1) * _pulse.value,
            child: child,
          ),
        ),
      ),
    );
  }
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

/// Prototype-only affordance for replaying a specific scripted reply,
/// including the deliberately broken ones.
class _ScenarioPicker extends StatelessWidget {
  const _ScenarioPicker({required this.selectedId, required this.onSelected});

  final String? selectedId;
  final void Function(String? id) onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      // Two leading chips before the scenarios: keyword-driven replay, and a
      // way into the component showcase. The showcase is where a design change
      // gets reviewed; reaching it from here means it needs no entry point of
      // its own.
      itemCount: mockScenarios.length + 2,
      separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppChip(
            label: 'ai_chat.scenario_auto'.tr(),
            selected: selectedId == null,
            style: AppChipStyle.outline,
            onTap: () => onSelected(null),
          );
        }
        if (index == 1) {
          return AppChip(
            label: 'ai_chat.showcase_open'.tr(),
            style: AppChipStyle.outline,
            icon: const Icon(Icons.grid_view_rounded),
            onTap: () => context.push(AiChatRoutes.showcase),
          );
        }
        final scenario = mockScenarios[index - 2];
        return AppChip(
          label: scenario.label,
          selected: selectedId == scenario.id,
          style: AppChipStyle.outline,
          onTap: () => onSelected(scenario.id),
        );
      },
    ),
  );
}
