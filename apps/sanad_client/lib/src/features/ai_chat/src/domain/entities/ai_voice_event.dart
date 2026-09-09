import 'package:equatable/equatable.dart';

/// A **low-frequency** event from a live-voice session.
///
/// Deliberately a third channel alongside `status` and `inputLevel` rather
/// than a merge of them. The level ticks dozens of times a second and must
/// stay on its own path to the waveform; these arrive once or twice a
/// conversation. Folding them together would put an audio meter and a semantic
/// card on one stream and force every listener to filter.
///
/// The payload is the *raw* `{schemaVersion, blocks}` object, not a validated
/// document — exactly like `AiChatUiEvent`. Validation needs host
/// configuration the transport has no business knowing, and it happens once at
/// ingestion in the bloc.
sealed class AiVoiceEvent extends Equatable {
  /// Creates an event.
  const AiVoiceEvent();

  @override
  List<Object?> get props => const [];
}

/// The assistant is asking something a card answers.
///
/// The session moves to `AiVoiceSessionStatus.awaitingInteraction` alongside
/// this, so the screen and the microphone agree about what is happening.
final class AiVoiceUiRequested extends AiVoiceEvent {
  /// Creates a UI request carrying a raw protocol payload.
  const AiVoiceUiRequested(this.payload);

  /// The unvalidated `{schemaVersion, blocks}` object.
  final Map<String, dynamic> payload;

  @override
  List<Object?> get props => [payload];
}

/// The card is finished with — answered, or dropped because the session is
/// ending. The screen takes it down.
final class AiVoiceUiResolved extends AiVoiceEvent {
  /// Creates a resolution for [nodeId], or for whatever is on screen when it
  /// is `null`.
  const AiVoiceUiResolved([this.nodeId]);

  /// The node that was answered.
  final String? nodeId;

  @override
  List<Object?> get props => [nodeId];
}
