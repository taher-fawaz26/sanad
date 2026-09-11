part of 'ai_composer_bloc.dart';

/// Something the composer needs to tell the user once.
///
/// Carries an [id] that is unique per occurrence. Without it, two identical
/// failures in a row would compare equal, `listenWhen` would not fire, and the
/// second one would be silently swallowed — the exact bug the chat page works
/// around for `failureMessage`.
final class AiComposerNotice extends Equatable {
  /// Creates a notice.
  const AiComposerNotice({
    required this.id,
    required this.messageKey,
    this.canOpenSettings = false,
    this.tone = AiNoticeTone.error,
  });

  /// Unique per occurrence, so a repeat still reads as a change.
  final String id;

  /// A dotted lower-snake localization key. Never prose.
  final String messageKey;

  /// Whether to offer the system-settings path, which is only meaningful
  /// after a permanent refusal.
  final bool canOpenSettings;

  /// How the message should read. Defaults to [AiNoticeTone.error], so every
  /// notice that predates this field is unchanged.
  final AiNoticeTone tone;

  @override
  List<Object?> get props => [id, messageKey, canOpenSettings, tone];
}

/// How a notice should be presented.
///
/// Exists because not everything the composer says is a failure. Guidance
/// rendered in the error snackbar's red would tell the user they did
/// something wrong when they did not.
enum AiNoticeTone {
  /// Something went wrong. Rendered by `showAppErrorSnackbar`.
  error,

  /// Guidance or confirmation. Rendered by `showAppSnackbar`'s neutral style.
  info,
}

/// The composer as the UI sees it.
///
/// Note what is *not* here: the partial transcript. It arrives many times a
/// second and lives in `SpeechTranscriptController`, so it cannot rebuild the
/// composer card. Only facts that change at human speed are state.
final class AiComposerState extends Equatable {
  /// Creates a composer state.
  const AiComposerState({
    this.attachments = const [],
    this.speech = AiSpeechStatus.idle,
    this.notice,
    this.isPicking = false,
  });

  /// Everything staged for the next turn, in the order it was added.
  final List<AiChatAttachment> attachments;

  /// Where dictation is — the composer's one and only microphone capability.
  final AiSpeechStatus speech;

  /// A one-shot message for the UI, or `null`.
  final AiComposerNotice? notice;

  /// Whether a picker is currently open, so the attach button can disable.
  final bool isPicking;

  /// Attachments that may actually be sent.
  List<AiChatAttachment> get readyAttachments =>
      attachments.where((a) => a.isReady).toList();

  /// Whether anything is staged and ready.
  bool get hasReadyAttachments => attachments.any((a) => a.isReady);

  /// Whether any attachment is still being prepared.
  bool get isPreparing => attachments.any((a) => a.status.isBusy);

  /// Whether a send may be attempted with [text].
  ///
  /// An attachment-only turn is legitimate, so empty text alone does not
  /// block sending. A turn is blocked while anything is still preparing —
  /// sending a half-processed attachment would be worse than waiting.
  bool canSend(String text) =>
      !isPreparing &&
      // While the recogniser still holds the microphone the text is not
      // settled — sending mid-phrase would post half a sentence.
      !speech.isActive &&
      (text.trim().isNotEmpty || hasReadyAttachments);

  /// Whether the composer is doing nothing at all — no attachment staged, no
  /// capability running. Used to decide whether a transient affordance (the
  /// starter suggestions) is appropriate; showing it mid-dictation would be
  /// clutter over content the user is actively producing.
  bool get isIdle => attachments.isEmpty && !speech.isActive;

  /// Returns a copy with the given fields replaced.
  ///
  /// [clearNotice] exists because `??` cannot express "set this back to null",
  /// and a notice that could never be cleared would fire forever.
  AiComposerState copyWith({
    List<AiChatAttachment>? attachments,
    AiSpeechStatus? speech,
    AiComposerNotice? notice,
    bool clearNotice = false,
    bool? isPicking,
  }) => AiComposerState(
    attachments: attachments ?? this.attachments,
    speech: speech ?? this.speech,
    notice: clearNotice ? null : (notice ?? this.notice),
    isPicking: isPicking ?? this.isPicking,
  );

  @override
  List<Object?> get props => [
    attachments,
    speech,
    notice,
    isPicking,
  ];
}
