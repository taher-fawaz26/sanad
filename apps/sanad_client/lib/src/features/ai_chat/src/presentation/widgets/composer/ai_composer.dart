import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_recording_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/speech_transcript_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_audio_preview_row.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer_tokens.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_hold_to_record_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_live_voice_glyph.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_recording_bar.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_speech_bar.dart';
import 'package:sanad_client/src/ui/glass/client_glass_surface.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// The multimodal composer — Figma `Sanad AI Input` (`5153:42646` /
/// `7827:30542`, states `Default`/`Focused`/`Typing`/`Voice Recording`).
///
/// ## What it does and does not know
///
/// It emits **intents** — "the user asked for the camera", "the user pressed
/// record" — and nothing else. It cannot open a camera, request a permission,
/// encode audio, compress an image or read a file, and it holds no business
/// state: the attachment list, the recording status and every failure live in
/// [AiComposerBloc].
///
/// The state it does own — draft text, focus, whether the send affordance is
/// showing — is a text field's own editing/UI state, not business state, the
/// same call the previous composer made.
///
/// Temporary UI. The final design is not approved, so this is built from
/// design-system components and is meant to be replaced without any of the
/// logic above it moving.
class AiComposer extends StatefulWidget {
  /// Creates the composer.
  const AiComposer({required this.onSend, required this.onVoice, super.key});

  /// Called with the trimmed text when the user sends.
  ///
  /// Attachments are not passed here: the page reads them from
  /// [AiComposerBloc], which is their owner.
  final void Function(String text) onSend;

  /// Called when the user asks for a live voice session.
  ///
  /// A callback rather than a `context.push` here: navigation is the page's
  /// job, and `routing.md` keeps route knowledge out of leaf widgets.
  final VoidCallback onVoice;

  @override
  State<AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<AiComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _hasFocus = false;

  SpeechTranscriptController? _transcript;

  /// How far the live record gesture has travelled.
  ///
  /// A `ValueNotifier` and not `setState`: this moves with every pointer frame,
  /// and rebuilding the card would rebuild the `TextField` inside it at pointer
  /// rate. Same rule the amplitude, the playback position and the partial
  /// transcript already follow.
  final ValueNotifier<Offset> _recordDrag = ValueNotifier(Offset.zero);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bound once, to the bloc's controller. Writing into a
    // `TextEditingController` is the narrowest update available: the field is
    // its own listener, so a partial result repaints the text and nothing else
    // in the tree.
    final transcript = context.read<AiComposerBloc>().transcript;
    if (identical(transcript, _transcript)) return;
    _transcript?.removeListener(_onTranscript);
    _transcript = transcript..addListener(_onTranscript);
  }

  @override
  void dispose() {
    _transcript?.removeListener(_onTranscript);
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    _recordDrag.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus == _hasFocus) return;
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  /// Mirrors the words being recognised into the field.
  ///
  /// No business decision is taken here — the bloc owns whether dictation is
  /// running, when it ends and what any failure means. This only copies text,
  /// which is what leaves the final transcript sitting in the composer as
  /// ordinary, editable text once the recogniser lets go.
  ///
  /// It replaces rather than appends, because dictation can only ever start
  /// from an empty composer: the microphone gives way to send as soon as there
  /// is anything to send.
  void _onTranscript() {
    final words = _transcript?.value.text ?? '';
    if (words.isEmpty) return;

    _controller.value = TextEditingValue(
      text: words,
      selection: TextSelection.collapsed(offset: words.length),
    );
    if (!_hasText) setState(() => _hasText = true);
  }

  void _submit(AiComposerState state) {
    if (!state.canSend(_controller.text)) return;
    final text = _controller.text.trim();
    _controller.clear();
    setState(() => _hasText = false);
    widget.onSend(text);
  }

  Future<void> _showAttachMenu(AiComposerBloc bloc) async {
    final choice = await showSheet<AiComposerCapture>(
      context,
      child: const _AttachMenu(),
    );
    if (choice == null) return;

    // Switched on the choice itself rather than on `intent == null`. Dictation
    // is not a picker intent and never will be, and inferring "the one with no
    // intent" would silently reroute the next capability added here.
    bloc.add(
      switch (choice) {
        AiComposerCapture.speechToText => const AiComposerSpeechStarted(),
        AiComposerCapture.camera ||
        AiComposerCapture.gallery ||
        AiComposerCapture.document => AiComposerAttachmentRequested(
          choice.intent!,
        ),
      },
    );
  }

  /// The card's first slot.
  Widget _contentRow(_AiComposerSurface surface, AiComposerState state) =>
      switch (surface) {
        _AiComposerSurface.recording => const AiRecordingContentRow(),
        _AiComposerSurface.locked => const AiRecordingContentRow(
          isLocked: true,
        ),
        // `previewTake` is non-null exactly when the surface is `preview` —
        // both derive from the same pair of facts, so the `!` cannot fire.
        _AiComposerSurface.preview => AiAudioPreviewRow(
          attachment: state.previewTake!,
        ),
        _AiComposerSurface.dictation => AiSpeechContentRow(
          status: state.speech,
        ),
        _AiComposerSurface.idle => _TextRow(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) {
            final hasText = value.trim().isNotEmpty;
            if (hasText != _hasText) setState(() => _hasText = hasText);
          },
          onSubmitted: (_) => _submit(state),
        ),
      };

  /// The card's second slot.
  Widget _actionsRow(
    _AiComposerSurface surface,
    AiComposerState state,
    AiComposerBloc bloc, {
    required bool canSend,
  }) => switch (surface) {
    // A held take offers no buttons at all: the finger that would press one is
    // the finger holding the take open.
    _AiComposerSurface.recording => AiRecordingHintRow(drag: _recordDrag),
    _AiComposerSurface.locked => const AiRecordingActionsRow(),
    _AiComposerSurface.preview => _PreviewActionsRow(
      onDelete: () => bloc.add(const AiComposerRecordingCancelled()),
      onSubmit: () => _submit(state),
    ),
    _AiComposerSurface.dictation => AiSpeechActionsRow(
      status: state.speech,
      onAttach: () => _showAttachMenu(bloc),
    ),
    _AiComposerSurface.idle => _IdleActionsRow(
      canSend: canSend,
      isPicking: state.isPicking,
      isCapturing: state.isCapturing,
      onAttach: () => _showAttachMenu(bloc),
      onVoice: widget.onVoice,
      onRecordDrag: (offset) => _recordDrag.value = offset,
      onSubmit: () => _submit(state),
    ),
  };

  /// Fades and lifts, a few points only.
  ///
  /// Enough to read as one surface replacing another and not enough to be a
  /// flourish — the transition's job is to say the composer changed state, not
  /// to be noticed for itself.
  static Widget _fadeUp(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<AiComposerBloc, AiComposerState>(
          builder: (context, state) {
            final bloc = context.read<AiComposerBloc>();
            final surface = _AiComposerSurface.of(state);
            final canSend = state.canSend(_controller.text);
            final focused = _hasFocus && surface == _AiComposerSurface.idle;
            final accent = AiComposerTokens.accent(context);
            final strip = state.stripAttachments;

            // Glass, and tinted hardest of the three levels: this is the one
            // surface in the client a user reads a sentence off, so the wash
            // behind it has to show through without ever competing with the
            // text. The focused border and its accent glow are kept exactly as
            // Figma specifies — glass replaces the card's flat fill, not its
            // state treatment.
            return ClientGlassSurface(
              borderRadius: AppRadius.circularLg,
              border: BorderSide(
                color: focused ? accent : colors.border,
                width: focused ? 2 : 1,
              ),
              shadow: [
                BoxShadow(
                  color: focused
                      ? accent.withValues(alpha: 0.13)
                      : colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: focused ? 8 : 16,
                  offset: Offset(0, focused ? 8 : 4),
                ),
              ],
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              // One switcher over both slots, keyed by the surface, so a
              // state change reads as the card *becoming* something else
              // rather than as unrelated widgets vanishing and appearing. The
              // size animates with it because the two slots are different
              // heights and a jump would undo the effect.
              //
              // Functional motion, so it is deliberately not gated on
              // `AppMotion.reduceMotionOf` — see that helper's own doc for
              // which bucket is and is not suppressed.
              child: AnimatedSize(
                duration: AppMotionDuration.quick,
                curve: AppMotionCurve.standard,
                alignment: Alignment.bottomCenter,
                child: AnimatedSwitcher(
                  duration: AppMotionDuration.quick,
                  switchInCurve: AppMotionCurve.standard,
                  switchOutCurve: AppMotionCurve.standard,
                  transitionBuilder: _fadeUp,
                  // Layout-only: the outgoing child must not reserve space
                  // while the incoming one is already sized, or the card
                  // lurches to the taller of the two mid-transition.
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ...previous.map(
                        (child) => Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: child,
                        ),
                      ),
                      if (current != null) current,
                    ],
                  ),
                  child: Column(
                    // The surface in the key is what makes the switcher fire:
                    // without it every state would rebuild the same child and
                    // nothing would animate.
                    key: ValueKey(surface),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xl,
                    children: [
                      if (strip.isNotEmpty)
                        _AttachmentStrip(attachments: strip),
                      _contentRow(surface, state),
                      _actionsRow(surface, state, bloc, canSend: canSend),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Which shape the composer card is currently wearing.
///
/// Derived from [AiComposerState], never stored in it. The bloc already knows
/// everything this answers — a fifth state field restating it in presentation
/// terms would be a second source of truth that could disagree with the first.
///
/// It exists as a named value because it is what the card's `AnimatedSwitcher`
/// is keyed on: "did the surface change" is the question that decides whether
/// to animate, and it is not the same question as "did the state change".
enum _AiComposerSurface {
  /// Text, attachments, and the full set of controls. Typing is not a separate
  /// surface — the card does not change shape for it, only the trailing
  /// control swaps between the microphone pair and the send pill.
  idle,

  /// A take is running under a held finger.
  recording,

  /// A take is running hands-free.
  locked,

  /// A finished take is waiting to be played, discarded or sent.
  preview,

  /// The recogniser is producing editable text.
  dictation
  ;

  /// Reads the surface out of [state].
  ///
  /// Order matters: recording is checked before dictation because the two are
  /// mutually exclusive in the bloc and the recording answer is the one that
  /// owns the microphone.
  static _AiComposerSurface of(AiComposerState state) {
    if (state.recording == AiRecordingStatus.lockedRecording) return locked;
    if (state.recording.showsRecordingRow) return recording;
    if (state.previewTake != null) return preview;
    if (state.speech.occupiesComposer) return dictation;
    return idle;
  }
}

/// Row 1 in the card's idle/typing states — the leading sparkle mark and the
/// borderless text field. No border/fill of its own: the card around it
/// already carries the border, so a second one from a design-system text
/// field would double up visually against Figma's flat, chrome-less field.
class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      spacing: AppSpacing.md,
      children: [
        SvgPicture.asset(
          AppSvgs.aiChatSparkle,
          package: AppAssets.package,
          width: 22,
          height: 22,
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: context.appTypography.regularNormal.copyWith(
              color: colors.textPrimary,
            ),
            // Every field-shaped property is neutralised explicitly, not left
            // to `InputDecoration.collapsed`.
            //
            // `collapsed` only clears `border`; the app's global
            // `InputDecorationTheme` (design_system `field_tokens.dart`) also
            // sets `filled`, `fillColor`, `enabledBorder`, `focusedBorder`
            // and — the one that actually breaks this layout — fixed
            // min/max height `constraints`. Those flow straight through
            // `collapsed`, which is what drew a second bordered, filled box
            // around the text inside the composer card, and what stopped
            // `maxLines: 4` from ever growing past one line.
            //
            // Figma's field is chrome-less: the card around it carries the
            // only border.
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: 'ai_chat.composer_hint'.tr(),
              hintStyle: context.appTypography.regularNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
            textInputAction: TextInputAction.send,
            // A caption is a sentence, not a word: a single line is the
            // wrong shape for it. It grows to four and then scrolls.
            maxLines: 4,
            minLines: 1,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }
}

/// Row 2 in the card's idle/typing states.
class _IdleActionsRow extends StatelessWidget {
  const _IdleActionsRow({
    required this.canSend,
    required this.isPicking,
    required this.isCapturing,
    required this.onAttach,
    required this.onVoice,
    required this.onRecordDrag,
    required this.onSubmit,
  });

  final bool canSend;
  final bool isPicking;
  final bool isCapturing;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final ValueChanged<Offset> onRecordDrag;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Figma fills the attach control (`7825:28939`) — it is the only
      // left-hand action, and the fill is what separates it from the
      // borderless field above it.
      AiCircleIconButton(
        svgAsset: AppSvgs.aiChatComposerPlus,
        semanticLabel: 'ai_chat.attach'.tr(),
        background: AiComposerTokens.controlFill(context),
        onTap: isPicking ? null : onAttach,
      ),
      // The microphone gives way to send as soon as there is something to
      // send, which is the gesture people already know from every chat app.
      if (canSend)
        _SendPillButton(onTap: onSubmit)
      else
        Row(
          spacing: AppSpacing.sm,
          children: [
            // The microphone means exactly one thing now: hold it and you
            // are recording a voice message. Dictation moved into the attach
            // sheet, which is what makes this button unambiguous — it used
            // to sit here meaning "dictate" while a third entry point buried
            // in that same sheet meant "record", and no arrangement of icons
            // could have made that legible.
            //
            // Unfilled, as Figma has it (`7825:28942`): only the live-voice
            // control beside it carries a fill, which is what ranks the two
            // against each other.
            AiHoldToRecordButton(onDragUpdate: onRecordDrag),
            // The other capability, and visibly its own thing — a live
            // session is a conversation, not a message, so it gets its own
            // affordance rather than a mode on this one.
            AiCircleIconButton(
              semanticLabel: 'ai_chat.voice_mode'.tr(),
              background: AiComposerTokens.controlFill(context),
              onTap: isCapturing ? null : onVoice,
              child: const AiLiveVoiceGlyph(),
            ),
          ],
        ),
    ],
  );
}

/// The second slot while a finished take is being previewed.
///
/// Discard is a plain icon and send is the same pill the text composer uses:
/// the take is now just an attachment waiting on the send it shares with every
/// other kind of turn, and giving it a bespoke send control would suggest
/// otherwise.
class _PreviewActionsRow extends StatelessWidget {
  const _PreviewActionsRow({required this.onDelete, required this.onSubmit});

  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      AiCircleIconButton(
        icon: Icons.delete_outline_rounded,
        semanticLabel: 'ai_chat.record_delete'.tr(),
        iconColor: context.appColors.error,
        onTap: onDelete,
      ),
      _SendPillButton(onTap: onSubmit),
    ],
  );
}

class _SendPillButton extends StatelessWidget {
  const _SendPillButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      label: 'ai_chat.send'.tr(),
      child: Material(
        // Figma `7825:28990`: 24/12 padding on a fully-rounded pill in the
        // AI accent green.
        color: AiComposerTokens.accent(context),
        borderRadius: AppRadius.circularXxl,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circularXxl,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.md,
            ),
            // The label text below would otherwise contribute its own
            // semantics node, merging into (and duplicating) the label this
            // widget already declares above.
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    'ai_chat.send'.tr(),
                    style: context.appTypography.regularNormal.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SvgPicture.asset(
                    AppSvgs.aiChatComposerSend,
                    package: AppAssets.package,
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      colors.onPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentStrip extends StatelessWidget {
  const _AttachmentStrip({required this.attachments});

  final List<AiChatAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          // A stable key, so removing one tile does not rebuild the rest.
          return AiAttachmentTile(
            key: ValueKey(attachment.id),
            attachment: attachment,
            onRemove: () =>
                bloc.add(AiComposerAttachmentRemoved(attachment.id)),
          );
        },
      ),
    );
  }
}

/// What the attach sheet can return.
///
/// Presentation-level on purpose: three of these map onto an
/// [AiAttachmentIntent] that the picker understands, and one does not.
/// Widening [AiAttachmentIntent] to hold `speechToText` would put a value in
/// the domain picker contract that no picker can ever satisfy.
///
/// Recording a voice note is deliberately **not** here any more. The composer's
/// microphone is the voice-note path now, and a second entry point in this
/// sheet would put the same capability on screen twice — the confusion this
/// redesign exists to remove.
enum AiComposerCapture {
  /// Dictate — speech recognised into editable composer text.
  ///
  /// It leads this list because it is the capability that moved here, and
  /// because it is the one a user reaching for the old microphone is looking
  /// for.
  speechToText(null),

  /// Take a photo.
  camera(AiAttachmentIntent.camera),

  /// Choose an existing photo.
  gallery(AiAttachmentIntent.gallery),

  /// Choose a file.
  document(AiAttachmentIntent.document)
  ;

  const AiComposerCapture(this.intent);

  /// The picker intent, or `null` when this is not something a picker returns.
  final AiAttachmentIntent? intent;
}

/// The attach menu's contents. Pops the chosen intent, `null` on dismissal —
/// the convention `sheet_navigation` sheets already follow.
class _AttachMenu extends StatelessWidget {
  const _AttachMenu();

  static const _entries = <AiComposerCapture, (IconData, String)>{
    AiComposerCapture.speechToText: (
      Icons.keyboard_voice_outlined,
      'ai_chat.speech_to_text',
    ),
    AiComposerCapture.camera: (
      Icons.photo_camera_outlined,
      'ai_chat.attach_camera',
    ),
    AiComposerCapture.gallery: (
      Icons.photo_library_outlined,
      'ai_chat.attach_gallery',
    ),
    AiComposerCapture.document: (
      Icons.attach_file_rounded,
      'ai_chat.attach_document',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SheetScaffold(
      // Scrollable rather than a bare Column: the sheet decides the height it
      // offers, and four rows at a large accessibility text size can exceed
      // it. A widget test caught exactly that.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _entries.entries)
              ListTile(
                leading: Icon(entry.value.$1, color: colors.textPrimary),
                title: Text(
                  entry.value.$2.tr(),
                  style: context.appTypography.regularNormal,
                ),
                // A local, imperative pop returning a value: the pattern
                // `routing.md` sanctions for a sheet result.
                onTap: () => Navigator.of(context).pop(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}
