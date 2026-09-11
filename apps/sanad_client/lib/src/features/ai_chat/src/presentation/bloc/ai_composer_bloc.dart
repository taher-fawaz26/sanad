import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_speech_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/speech_locale_resolver.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/validate_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/speech_transcript_controller.dart';

part 'ai_composer_event.dart';
part 'ai_composer_state.dart';

/// Owns what the user is *about to* send.
///
/// ## Why this is not part of `AiChatBloc`
///
/// Two reasons, both load-bearing:
///
/// 1. **Lifetime.** Composer state dies the moment a turn is sent; the
///    conversation outlives every turn. Merging them would mean the message
///    list carries draft state it has no business knowing about.
/// 2. **Rebuild cost.** Picking, validating and recognising churn several times
///    per second. Routing that through `AiChatState.messages` would emit a new
///    message list on every tick and rebuild the whole conversation — exactly
///    what `ActiveStreamController` exists to prevent.
///
/// It is deliberately *one* composer bloc and not one per modality. Images and
/// documents are the same responsibility — staging a turn — and splitting them
/// would double the wiring for no separation gain.
///
/// ## The one microphone capability
///
/// Speech recognition, and only speech recognition. The composer transcribes
/// what the user says into editable text and sends that as an ordinary text
/// turn: it records no audio, writes no file, stages no audio attachment and
/// uploads nothing. (A live-voice *session* is a separate feature on its own
/// route, with its own bloc and its own capture path — it never reaches here.)
///
/// ## What it never does
///
/// No plugin call, no `BuildContext`, no `dart:io`, no `Timer`. Acquisition
/// lives behind [AiAttachmentSource], recognition behind [AiSpeechRecognizer],
/// permissions behind [AiPermissionGateway] — so every path here is exercisable
/// with three fakes and no device.
class AiComposerBloc extends Bloc<AiComposerEvent, AiComposerState> {
  /// Creates the composer.
  ///
  /// [transcript] is injectable so a test can watch the hot path without
  /// reaching into the bloc.
  AiComposerBloc({
    required AiAttachmentSource attachmentSource,
    required AiPermissionGateway permissions,
    required AiSpeechRecognizer recognizer,

    /// Reads the app's current language code, for choosing a recognition
    /// locale. Injected as a getter rather than a value because the user can
    /// change language while the chat is open, and injected rather than read
    /// from the service locator because a bloc that calls `sl<>` cannot be
    /// tested without one. `app_di.dart` already passes
    /// `() => sl<TranslateBloc>().state.languageCode` this way.
    required String Function() resolveLanguageCode,
    this.rules = const AiAttachmentRules(),
    ValidateAttachment? validate,
    SpeechTranscriptController? transcript,
  }) : _source = attachmentSource,
       _permissions = permissions,
       _recognizer = recognizer,
       _resolveLanguageCode = resolveLanguageCode,
       _validate = validate ?? ValidateAttachment(rules: rules),
       transcript = transcript ?? SpeechTranscriptController(),
       super(const AiComposerState()) {
    // A second tap while the picker is open is meaningless — the OS already
    // has the foreground — so those are dropped rather than queued.
    on<AiComposerAttachmentRequested>(
      _onAttachmentRequested,
      transformer: droppable(),
    );
    on<AiComposerAttachmentRemoved>(_onAttachmentRemoved);
    on<AiComposerSubmitted>(_onSubmitted);
    on<AiComposerNoticeDismissed>(_onNoticeDismissed);
    on<AiComposerSettingsRequested>(_onSettingsRequested);
    // `sequential` keeps two events *of the same type* from interleaving — a
    // second stop cannot overtake the first — which is what stops a stop from
    // stranding the recogniser mid-start.
    on<AiComposerSpeechStarted>(_onSpeechStarted, transformer: sequential());
    on<AiComposerSpeechStopped>(_onSpeechStopped, transformer: sequential());
    on<AiComposerSpeechCancelled>(
      _onSpeechCancelled,
      transformer: sequential(),
    );
    on<AiComposerSpeechEnded>(_onSpeechEnded, transformer: sequential());
    on<AiComposerSpeechFailed>(_onSpeechFailed, transformer: sequential());
    on<AiComposerBackgrounded>(_onBackgrounded, transformer: sequential());

    // Partial results go straight to the controller and emit no state at all —
    // the whole reason dictation does not rebuild the conversation.
    //
    // `this.` because the constructor parameter of the same name is still in
    // scope here and is nullable.
    _transcriptSubscription = _recognizer.transcripts.listen(
      (value) => this.transcript.value = value,
    );
    _speechFailureSubscription = _recognizer.failures.listen(
      (failure) => add(AiComposerSpeechFailed(failure)),
    );
    // The platform decides when a phrase is over, so a recogniser that stops
    // itself has to be able to move the state machine.
    _speechListeningSubscription = _recognizer.listening.listen((listening) {
      if (listening) return;
      // Compared against `listening` exactly, and not `speech.isActive`: the
      // plugin also reports `false` on its way down from a user-pressed stop,
      // where `_onSpeechStopped` has already emitted `completed` and a second
      // `AiComposerSpeechEnded` behind it would be noise.
      if (state.speech == AiSpeechStatus.listening) {
        add(const AiComposerSpeechEnded());
      }
    });
  }

  /// What an attachment is allowed to be.
  final AiAttachmentRules rules;

  /// Words being recognised right now. Read directly by the composer's text
  /// field and the dictation bar; never state.
  final SpeechTranscriptController transcript;

  final AiAttachmentSource _source;
  final AiPermissionGateway _permissions;
  final AiSpeechRecognizer _recognizer;
  final String Function() _resolveLanguageCode;
  final ValidateAttachment _validate;

  StreamSubscription<AiSpeechTranscript>? _transcriptSubscription;
  StreamSubscription<AiSpeechFailure>? _speechFailureSubscription;
  StreamSubscription<bool>? _speechListeningSubscription;

  bool _closed = false;

  // ── attachments ───────────────────────────────────────────────────────────

  Future<void> _onAttachmentRequested(
    AiComposerAttachmentRequested event,
    Emitter<AiComposerState> emit,
  ) async {
    if (state.attachments.length >= rules.maxAttachments) {
      emit(state.copyWith(notice: _notice(AiAttachmentFailureKeys.tooMany)));
      return;
    }

    // Finish dictation before handing the screen to the picker (A-13).
    //
    // The picker takes the microphone with it, so dictation was ending anyway
    // — but as a platform *timeout*, silently, with the composer simply
    // reverting. Stopping it here makes that deterministic and says so, and
    // `_onSpeechStopped` keeps whatever was already recognised: the transcript
    // is written into the composer as it arrives, so stopping loses nothing.
    if (state.speech.isActive) {
      emit(state.copyWith(speech: AiSpeechStatus.finalizing));
      await _recognizer.stop();
      if (_closed) return;
      emit(
        state.copyWith(
          speech: AiSpeechStatus.completed,
          notice: _notice(
            'ai_chat.dictation_stopped_for_attachment',
            tone: AiNoticeTone.info,
          ),
        ),
      );
    }

    emit(state.copyWith(isPicking: true));
    final result = await _source.pick(event.intent);
    if (_closed) return;

    switch (result) {
      case AiAttachmentPickCancelled():
        // Backing out is not a failure and says nothing to the user.
        emit(state.copyWith(isPicking: false));

      case AiAttachmentPickDenied(:final permanently):
        emit(
          state.copyWith(
            isPicking: false,
            notice: _notice(
              permanently
                  ? 'ai_chat.permission_denied_permanently'
                  : 'ai_chat.permission_denied',
              canOpenSettings: permanently,
            ),
          ),
        );

      case AiAttachmentPickFailed(:final failureKey):
        emit(state.copyWith(isPicking: false, notice: _notice(failureKey)));

      case AiAttachmentsPicked(:final attachments):
        emit(_accept(attachments).copyWith(isPicking: false));
    }
  }

  /// Validates a freshly picked batch against the rules and what is already
  /// staged.
  ///
  /// A rejected attachment is **not** staged as a failed tile. Retrying a file
  /// that is too large or of the wrong type cannot succeed, so a tile the user
  /// must then dismiss is worse than a single explanation. Attachments that
  /// fail *later*, during preparation, do keep their tile.
  AiComposerState _accept(List<AiChatAttachment> picked) {
    final accepted = [...state.attachments];
    String? firstFailure;

    for (final attachment in picked) {
      // Counted against the running total, so a batch cannot overshoot the
      // limit by arriving all at once.
      final validated = _validate(attachment, currentCount: accepted.length);
      if (validated.isReady) {
        accepted.add(validated);
      } else {
        firstFailure ??= validated.failureKey;
      }
    }

    return state.copyWith(
      attachments: accepted,
      notice: firstFailure == null ? null : _notice(firstFailure),
    );
  }

  /// Drops one staged attachment.
  ///
  /// The file is deliberately **not** deleted: every attachment the composer
  /// holds came from a picker and lives in that picker's own cache, which is
  /// not ours to remove. The composer creates no files of its own.
  void _onAttachmentRemoved(
    AiComposerAttachmentRemoved event,
    Emitter<AiComposerState> emit,
  ) {
    if (!state.attachments.any((a) => a.id == event.id)) return;

    emit(
      state.copyWith(
        attachments: state.attachments.where((a) => a.id != event.id).toList(),
      ),
    );
  }

  void _onSubmitted(
    AiComposerSubmitted event,
    Emitter<AiComposerState> emit,
  ) {
    transcript.reset();
    emit(const AiComposerState());
  }

  void _onNoticeDismissed(
    AiComposerNoticeDismissed event,
    Emitter<AiComposerState> emit,
  ) => emit(state.copyWith(clearNotice: true));

  Future<void> _onSettingsRequested(
    AiComposerSettingsRequested event,
    Emitter<AiComposerState> emit,
  ) async {
    emit(state.copyWith(clearNotice: true));
    await _permissions.openSettings();
  }

  // ── dictation ─────────────────────────────────────────────────────────────

  Future<void> _onSpeechStarted(
    AiComposerSpeechStarted event,
    Emitter<AiComposerState> emit,
  ) async {
    // A second tap while the recogniser is already up is a no-op rather than a
    // restart, which would throw away the phrase in progress.
    if (state.speech.isActive) return;

    emit(state.copyWith(speech: AiSpeechStatus.requestingPermission));

    final microphone = await _permissions.ensureMicrophone();
    if (_closed) return;
    if (!microphone.isGranted) {
      emit(_speechDenied(microphone));
      return;
    }

    // iOS treats recognition as its own grant with its own prompt; on Android
    // this is the same RECORD_AUDIO already allowed above and returns at once.
    final recognition = await _permissions.ensureSpeechRecognition();
    if (_closed) return;
    if (!recognition.isGranted) {
      emit(_speechDenied(recognition));
      return;
    }

    emit(state.copyWith(speech: AiSpeechStatus.starting));
    transcript.reset();

    if (!await _recognizer.initialize()) {
      if (_closed) return;
      emit(
        state.copyWith(
          speech: AiSpeechStatus.error,
          notice: _notice('ai_chat.speech_unavailable'),
        ),
      );
      return;
    }
    if (_closed) return;

    // Ask the device what it can actually recognise rather than asserting a
    // tag. `null` back means no recogniser for this language — the device's
    // own default is a better answer than refusing to dictate at all.
    final localeId = SpeechLocaleResolver.resolve(
      languageCode: _resolveLanguageCode(),
      available: await _recognizer.availableLocales(),
    );
    if (_closed) return;

    try {
      await _recognizer.start(localeId: localeId);
      if (_closed) return;
      emit(state.copyWith(speech: AiSpeechStatus.listening));
    } on Object {
      if (_closed) return;
      emit(
        state.copyWith(
          speech: AiSpeechStatus.error,
          notice: _notice('ai_chat.speech_failed'),
        ),
      );
    }
  }

  AiComposerState _speechDenied(AiPermissionOutcome outcome) => state.copyWith(
    speech: AiSpeechStatus.error,
    notice: _notice(
      outcome.needsSettings
          ? 'ai_chat.speech_denied_permanently'
          : 'ai_chat.speech_denied',
      canOpenSettings: outcome.needsSettings,
    ),
  );

  Future<void> _onSpeechStopped(
    AiComposerSpeechStopped event,
    Emitter<AiComposerState> emit,
  ) async {
    if (!state.speech.isActive) return;

    emit(state.copyWith(speech: AiSpeechStatus.finalizing));
    await _recognizer.stop();
    if (_closed) return;

    // The text is already in the composer, put there by the transcript
    // controller as it arrived. Nothing to move here — from now on it is
    // ordinary editable text, and pressing send makes it an ordinary text turn.
    emit(state.copyWith(speech: AiSpeechStatus.completed));
  }

  Future<void> _onSpeechCancelled(
    AiComposerSpeechCancelled event,
    Emitter<AiComposerState> emit,
  ) async {
    if (!state.speech.isActive) return;

    await _recognizer.cancel();
    transcript.reset();
    if (_closed) return;

    emit(state.copyWith(speech: AiSpeechStatus.idle));
  }

  Future<void> _onSpeechEnded(
    AiComposerSpeechEnded event,
    Emitter<AiComposerState> emit,
  ) async {
    if (!state.speech.isActive) return;
    // The recogniser let go by itself. Whatever it heard stands.
    emit(state.copyWith(speech: AiSpeechStatus.completed));
  }

  Future<void> _onSpeechFailed(
    AiComposerSpeechFailed event,
    Emitter<AiComposerState> emit,
  ) async {
    // A failure that arrives after the user already cancelled — the plugin
    // reports one on its way down — must not raise a banner about a dictation
    // nobody is waiting on any more.
    if (state.speech == AiSpeechStatus.idle) return;

    await _recognizer.cancel();
    if (_closed) return;

    // Hearing nothing is not a failure worth a red banner — it is the normal
    // outcome of pressing the button and then not speaking. The composer just
    // goes quiet again.
    if (event.failure == AiSpeechFailure.noMatch ||
        event.failure == AiSpeechFailure.timeout) {
      transcript.reset();
      emit(state.copyWith(speech: AiSpeechStatus.idle));
      return;
    }

    emit(
      state.copyWith(
        speech: AiSpeechStatus.error,
        notice: _notice(
          switch (event.failure) {
            AiSpeechFailure.permissionDenied => 'ai_chat.speech_denied',
            AiSpeechFailure.permissionPermanentlyDenied =>
              'ai_chat.speech_denied_permanently',
            AiSpeechFailure.unavailable => 'ai_chat.speech_unavailable',
            AiSpeechFailure.network => 'ai_chat.speech_network',
            _ => 'ai_chat.speech_failed',
          },
          canOpenSettings:
              event.failure == AiSpeechFailure.permissionPermanentlyDenied,
        ),
      ),
    );
  }

  // ── app lifecycle ─────────────────────────────────────────────────────────

  /// The app left the foreground.
  ///
  /// Nothing downstream reports this: the OS putting us behind something else
  /// is not an audio-session interruption, and the recogniser will happily go
  /// on holding the microphone. Android also stops delivering microphone data
  /// to a backgrounded app without a foreground service, so a phrase that
  /// survives here is silently dead anyway.
  ///
  /// The partial transcript goes with it. A phrase nobody was present to
  /// finish is not text the user asked for.
  Future<void> _onBackgrounded(
    AiComposerBackgrounded event,
    Emitter<AiComposerState> emit,
  ) async {
    if (!state.speech.isActive) return;

    await _recognizer.cancel();
    transcript.reset();
    if (_closed) return;
    emit(state.copyWith(speech: AiSpeechStatus.idle));
  }

  // ── plumbing ──────────────────────────────────────────────────────────────

  AiComposerNotice _notice(
    String messageKey, {
    bool canOpenSettings = false,
    AiNoticeTone tone = AiNoticeTone.error,
  }) => AiComposerNotice(
    // A fresh id per occurrence, so two identical failures in a row still
    // read as a change and the second one is not swallowed.
    id: generateUuidV4(),
    messageKey: messageKey,
    canOpenSettings: canOpenSettings,
    tone: tone,
  );

  @override
  Future<void> close() async {
    if (_closed) return super.close();
    _closed = true;

    await _transcriptSubscription?.cancel();
    await _speechFailureSubscription?.cancel();
    await _speechListeningSubscription?.cancel();
    _transcriptSubscription = null;
    _speechFailureSubscription = null;
    _speechListeningSubscription = null;

    // Nothing staged has a file of ours behind it — every attachment came from
    // a picker's own cache — so there is nothing to clean up on the way out.
    await _recognizer.dispose();
    transcript.dispose();

    return super.close();
  }
}
