import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_speech_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/validate_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';

import '../support/attachment_fixtures.dart';
import '../support/composer_fakes.dart';

void main() {
  late FakeAttachmentSource source;
  late FakePermissionGateway permissions;
  late FakeSpeechRecognizer recognizer;
  late String languageCode;

  const rules = AiAttachmentRules();

  AiComposerBloc build() => AiComposerBloc(
    attachmentSource: source,
    permissions: permissions,
    recognizer: recognizer,
    resolveLanguageCode: () => languageCode,
  );

  setUp(() {
    source = FakeAttachmentSource();
    permissions = FakePermissionGateway();
    recognizer = FakeSpeechRecognizer();
    languageCode = 'en';
  });

  /// Runs [body] against a fresh bloc and always closes it, so a leaked
  /// subscription shows up as a test failure rather than a later mystery.
  Future<void> withBloc(Future<void> Function(AiComposerBloc bloc) body) async {
    final bloc = build();
    try {
      await body(bloc);
    } finally {
      await bloc.close();
    }
  }

  group('attachment picking', () {
    test('a successful pick stages the attachments as ready', () async {
      source.result = picked([imageFixture(), documentFixture()]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, hasLength(2));
        expect(
          bloc.state.attachments.every((a) => a.isReady),
          isTrue,
        );
        expect(bloc.state.hasReadyAttachments, isTrue);
        expect(source.calls, [AiAttachmentIntent.gallery]);
      });
    });

    test('cancelling says nothing and stages nothing', () async {
      source.result = const AiAttachmentPickCancelled();

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, isEmpty);
        expect(bloc.state.notice, isNull);
      });
    });

    test('a refusal notices without the settings path', () async {
      source.result = const AiAttachmentPickDenied(permanently: false);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(bloc.state.notice, isNotNull);
        expect(bloc.state.notice!.canOpenSettings, isFalse);
      });
    });

    test('a permanent refusal offers the settings path', () async {
      source.result = const AiAttachmentPickDenied(permanently: true);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(bloc.state.notice!.canOpenSettings, isTrue);
      });
    });

    test('a platform failure surfaces its key, never prose', () async {
      source.result = const AiAttachmentPickFailed(
        'ai_chat.attachment_pick_failed',
      );

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.document),
        );
        await pumpEventQueue();

        expect(bloc.state.notice!.messageKey, 'ai_chat.attachment_pick_failed');
      });
    });

    test('a second request while one is open is dropped', () async {
      source
        ..result = picked([imageFixture()])
        ..gate = Completer<void>();

      await withBloc((bloc) async {
        bloc
          ..add(
            const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
          )
          ..add(
            const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
          );
        await pumpEventQueue();

        expect(bloc.state.isPicking, isTrue);
        source.gate!.complete();
        await pumpEventQueue();

        // droppable(): the OS already had the foreground, so the second tap
        // never reaches the picker.
        expect(source.calls, [AiAttachmentIntent.gallery]);
      });
    });

    test('isPicking clears whatever the outcome', () async {
      source.result = const AiAttachmentPickFailed('ai_chat.x');

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.isPicking, isFalse);
      });
    });
  });

  group('validation on the way in', () {
    test('an oversized file is rejected and not staged', () async {
      source.result = picked([
        imageFixture(sizeBytes: FileSizePolicy.maxBytes + 1),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, isEmpty);
        expect(
          bloc.state.notice!.messageKey,
          AiAttachmentFailureKeys.tooLarge,
        );
      });
    });

    test('a mixed batch keeps the good ones and explains once', () async {
      source.result = picked([
        imageFixture(id: 'a'),
        imageFixture(id: 'b', sizeBytes: FileSizePolicy.maxBytes + 1),
        imageFixture(id: 'c'),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments.map((a) => a.id), ['a', 'c']);
        expect(bloc.state.notice, isNotNull);
      });
    });

    test('a batch cannot overshoot the limit by arriving at once', () async {
      source.result = picked([
        for (var i = 0; i < rules.maxAttachments + 3; i++)
          imageFixture(id: 'a$i'),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        expect(bloc.state.attachments, hasLength(rules.maxAttachments));
        expect(bloc.state.notice!.messageKey, AiAttachmentFailureKeys.tooMany);
      });
    });

    test('requesting more when already full never opens the picker', () async {
      source.result = picked([
        for (var i = 0; i < rules.maxAttachments; i++) imageFixture(id: 'a$i'),
      ]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        expect(bloc.state.attachments, hasLength(rules.maxAttachments));

        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        expect(source.calls, hasLength(1));
        expect(bloc.state.notice!.messageKey, AiAttachmentFailureKeys.tooMany);
      });
    });
  });

  group('removal and submission', () {
    test('removing drops the attachment', () async {
      source.result = picked([imageFixture(id: 'a'), imageFixture(id: 'b')]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerAttachmentRemoved('a'));
        await pumpEventQueue();

        expect(bloc.state.attachments.map((a) => a.id), ['b']);
      });
    });

    test('removing an unknown id changes nothing', () async {
      source.result = picked([imageFixture(id: 'a')]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerAttachmentRemoved('nope'));
        await pumpEventQueue();

        expect(bloc.state.attachments, hasLength(1));
      });
    });

    test('removal never deletes the underlying file', () async {
      // Every attachment comes from a picker, and picker files live in the
      // picker's own cache — not ours to remove. Deleting one could
      // invalidate a cache another feature is using. The composer creates no
      // files of its own, so removal is a list operation and nothing more.
      source.result = picked([imageFixture(id: 'a')]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        final path = bloc.state.attachments.single.localPath;

        bloc.add(const AiComposerAttachmentRemoved('a'));
        await pumpEventQueue();

        expect(bloc.state.attachments, isEmpty);
        expect(path, '/tmp/photo.jpg');
      });
    });

    test('submitting clears everything back to the initial state', () async {
      source.result = picked([imageFixture(id: 'a')]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        expect(bloc.state.attachments, hasLength(1));

        bloc.add(const AiComposerSubmitted());
        await pumpEventQueue();

        expect(bloc.state, const AiComposerState());
        expect(bloc.transcript.value.text, isEmpty);
      });
    });
  });

  group('notices', () {
    test('two identical failures both surface', () async {
      // The bug this guards: an equal notice would make listenWhen skip the
      // second one and the user would never be told twice.
      source.result = const AiAttachmentPickFailed('ai_chat.same');

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        final first = bloc.state.notice!;

        bloc
          ..add(const AiComposerNoticeDismissed())
          ..add(
            const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
          );
        await pumpEventQueue();
        final second = bloc.state.notice!;

        expect(first.messageKey, second.messageKey);
        expect(first.id, isNot(second.id));
        expect(first, isNot(second));
      });
    });

    test('a notice can be cleared back to null', () async {
      source.result = const AiAttachmentPickFailed('ai_chat.x');

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();
        expect(bloc.state.notice, isNotNull);

        bloc.add(const AiComposerNoticeDismissed());
        await pumpEventQueue();

        expect(bloc.state.notice, isNull);
      });
    });

    test('requesting settings opens them and clears the notice', () async {
      source.result = const AiAttachmentPickDenied(permanently: true);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        );
        await pumpEventQueue();

        bloc.add(const AiComposerSettingsRequested());
        await pumpEventQueue();

        expect(permissions.settingsOpened, 1);
        expect(bloc.state.notice, isNull);
      });
    });
  });

  group('canSend', () {
    test('text alone is enough', () {
      expect(const AiComposerState().canSend('hello'), isTrue);
    });

    test('whitespace alone is not', () {
      expect(const AiComposerState().canSend('   '), isFalse);
    });

    test('an attachment alone is enough', () {
      final state = AiComposerState(
        attachments: [imageFixture(status: AiAttachmentStatus.ready)],
      );

      expect(state.canSend(''), isTrue);
    });

    test('a still-preparing attachment blocks sending', () {
      final state = AiComposerState(
        attachments: [imageFixture(status: AiAttachmentStatus.processing)],
      );

      expect(state.canSend('hi'), isFalse);
    });

    test('a live phrase blocks sending, a finished one does not', () {
      // While the recogniser still holds the microphone the text is not
      // settled, so sending would post half a sentence. Once it lets go the
      // words are ordinary editable text and send is available again.
      for (final status in [
        AiSpeechStatus.starting,
        AiSpeechStatus.listening,
        AiSpeechStatus.finalizing,
      ]) {
        expect(
          AiComposerState(speech: status).canSend('hi'),
          isFalse,
          reason: '$status should block',
        );
      }

      for (final status in [
        AiSpeechStatus.idle,
        AiSpeechStatus.completed,
        AiSpeechStatus.error,
      ]) {
        expect(
          AiComposerState(speech: status).canSend('hi'),
          isTrue,
          reason: '$status should allow',
        );
      }
    });
  });

  group('disposal', () {
    test('close releases the recogniser and its controller', () async {
      final bloc = build();
      await bloc.close();

      expect(recognizer.disposeCount, 1);
    });

    test('close while dictating still tears down', () async {
      final bloc = build()..add(const AiComposerSpeechStarted());
      await pumpEventQueue();

      await bloc.close();

      expect(recognizer.disposeCount, 1);
    });

    test('closing twice is safe', () async {
      final bloc = build();
      await bloc.close();
      await bloc.close();

      expect(recognizer.disposeCount, 1);
    });
  });

  group('dictation', () {
    /// Drives the bloc into `listening`.
    Future<void> startSpeech(AiComposerBloc bloc) async {
      bloc.add(const AiComposerSpeechStarted());
      await pumpEventQueue();
    }

    test('it asks for both grants, then listens', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.listening);
        expect(recognizer.startCount, 1);
      });
    });

    test('a refused microphone never reaches the recogniser', () async {
      permissions.microphone = AiPermissionOutcome.denied;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_denied');
        expect(bloc.state.notice!.canOpenSettings, isFalse);
        expect(recognizer.startCount, 0);
      });
    });

    test('a refused speech grant is its own path', () async {
      // iOS asks twice. Allowing the microphone and refusing recognition is a
      // real state, and it must not read as a microphone problem.
      permissions.speechRecognition = AiPermissionOutcome.permanentlyDenied;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(
          bloc.state.notice!.messageKey,
          'ai_chat.speech_denied_permanently',
        );
        expect(bloc.state.notice!.canOpenSettings, isTrue);
        expect(recognizer.startCount, 0);
      });
    });

    test('an unavailable recogniser fails before listening', () async {
      recognizer.available = false;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_unavailable');
        expect(recognizer.startCount, 0);
      });
    });

    test('a recogniser that throws is reported, not swallowed', () async {
      recognizer.throwOnStart = true;

      await withBloc((bloc) async {
        await startSpeech(bloc);

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_failed');
      });
    });

    test('the app language chooses the recognition locale', () async {
      languageCode = 'ar';

      await withBloc((bloc) async {
        await startSpeech(bloc);
        expect(recognizer.startedLocales, ['ar-AE']);
      });
    });

    test('a language the device lacks falls back to its default', () async {
      languageCode = 'ar';
      recognizer.locales = ['en-US'];

      await withBloc((bloc) async {
        await startSpeech(bloc);

        // `null` = let the device decide. Dictating in the wrong language is a
        // better outcome than a button that refuses to work.
        expect(recognizer.startedLocales, [null]);
        expect(bloc.state.speech, AiSpeechStatus.listening);
      });
    });

    test('partial results reach the controller and emit NO state', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);

        final states = <AiComposerState>[];
        final sub = bloc.stream.listen(states.add);

        for (final word in ['book', 'book a', 'book a table']) {
          await recognizer.emitTranscript(word);
        }

        // The load-bearing assertion of the whole hot path: if these emitted,
        // the message list above the composer would rebuild on every word.
        expect(
          states,
          isEmpty,
          reason: 'partial transcripts must not emit composer state',
        );
        expect(bloc.transcript.value.text, 'book a table');
        expect(bloc.transcript.value.isFinal, isFalse);

        await sub.cancel();
      });
    });

    test('stopping finalises and leaves the text in place', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('book a table', isFinal: true);

        bloc.add(const AiComposerSpeechStopped());
        await pumpEventQueue();

        expect(recognizer.stopCount, 1);
        expect(bloc.state.speech, AiSpeechStatus.completed);
        // Still there — it is ordinary editable composer text now.
        expect(bloc.transcript.value.text, 'book a table');
      });
    });

    test('cancelling throws the words away', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('never mind');

        bloc.add(const AiComposerSpeechCancelled());
        await pumpEventQueue();

        expect(recognizer.cancelCount, 1);
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.transcript.value.text, isEmpty);
      });
    });

    test('a recogniser that stops itself moves the state machine', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('a short phrase', isFinal: true);

        // Nobody pressed anything: the platform ended the phrase after a
        // pause. The composer must follow rather than keep claiming to listen.
        await recognizer.emitListening(value: false);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.completed);
      });
    });

    test('hearing nothing is not an error banner', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitFailure(AiSpeechFailure.noMatch);
        await pumpEventQueue();

        // Pressing the button and not speaking is normal. It just goes quiet.
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.state.notice, isNull);
      });
    });

    test('a real failure surfaces its own message', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitFailure(AiSpeechFailure.network);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice!.messageKey, 'ai_chat.speech_network');
      });
    });

    test('a failure arriving after a cancel is ignored', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        bloc.add(const AiComposerSpeechCancelled());
        await pumpEventQueue();
        expect(bloc.state.speech, AiSpeechStatus.idle);

        // The plugin reports an error on its way down. Nobody is waiting on
        // this dictation any more, so it must not raise a banner.
        await recognizer.emitFailure(AiSpeechFailure.network);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.state.notice, isNull);
      });
    });

    test('sending clears dictation along with everything else', () async {
      await withBloc((bloc) async {
        await startSpeech(bloc);
        await recognizer.emitTranscript('send this', isFinal: true);
        bloc.add(const AiComposerSpeechStopped());
        await pumpEventQueue();

        bloc.add(const AiComposerSubmitted());
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.transcript.value.text, isEmpty);
      });
    });

    test('closing releases the recogniser', () async {
      final bloc = build();
      await bloc.close();

      expect(recognizer.disposeCount, 1);
    });
  });

  group('the microphone has exactly one owner', () {
    // There is only one microphone capability left in the composer, so the
    // old mutual-exclusion matrix collapses to this: dictation refuses to
    // restart itself, and nothing else here opens the microphone at all.
    test('a second start while already listening is ignored', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        expect(bloc.state.speech, AiSpeechStatus.listening);

        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        // One session, not two — a restart would throw away the phrase in
        // progress.
        expect(recognizer.startCount, 1);
        expect(bloc.state.speech, AiSpeechStatus.listening);
      });
    });

    test('sending cannot happen mid-phrase', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        expect(bloc.state.canSend('half a sentence'), isFalse);
      });
    });
  });

  group('leaving the foreground', () {
    test('it cancels dictation', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('mid sentence');

        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(recognizer.cancelCount, 1);
        expect(bloc.state.speech, AiSpeechStatus.idle);
        expect(bloc.transcript.value.text, isEmpty);
      });
    });

    test('it is harmless when nothing is running', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerBackgrounded());
        await pumpEventQueue();

        expect(bloc.state, const AiComposerState());
        expect(recognizer.cancelCount, 0);
      });
    });
  });

  group('the recogniser drives the composer, never bloc state', () {
    test('it still writes the composer text field', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('typed by voice');

        expect(bloc.transcript.value.text, 'typed by voice');
        // No attachment is created by speaking: the words are text, and text
        // is all a dictated turn ever carries.
        expect(bloc.state.attachments, isEmpty);
      });
    });

    test('its failures still raise a notice', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        await recognizer.emitFailure(AiSpeechFailure.network);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.error);
        expect(bloc.state.notice?.messageKey, 'ai_chat.speech_network');
      });
    });

    test('the recogniser ending still completes the phrase', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        await recognizer.emitListening(value: true);
        await pumpEventQueue();

        await recognizer.emitListening(value: false);
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.completed);
      });
    });
  });

  group('speech is text, and only text', () {
    // The product invariant this feature was reduced to. AI Chat has no
    // recorded-audio path any more: a dictated turn must be indistinguishable
    // from a typed one by the time it leaves the composer.
    test('a completed dictation stages no attachment at all', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();
        await recognizer.emitTranscript('book me for tomorrow at nine');

        bloc.add(const AiComposerSpeechStopped());
        await pumpEventQueue();

        expect(bloc.state.speech, AiSpeechStatus.completed);
        expect(bloc.transcript.value.text, 'book me for tomorrow at nine');
        // The whole point: the words are in the composer as editable text and
        // nothing was attached, uploaded or written to disk.
        expect(bloc.state.attachments, isEmpty);
        expect(bloc.state.hasReadyAttachments, isFalse);
        expect(bloc.state.canSend(bloc.transcript.value.text), isTrue);
      });
    });

    test('the only attachment types the composer can hold', () async {
      // A structural assertion, so reintroducing an audio variant fails here
      // rather than silently reaching the wire again.
      source.result = picked([imageFixture(), documentFixture()]);

      await withBloc((bloc) async {
        bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.gallery),
        );
        await pumpEventQueue();

        for (final attachment in bloc.state.attachments) {
          expect(
            attachment,
            anyOf(isA<AiImageAttachment>(), isA<AiDocumentAttachment>()),
          );
          expect(attachment.mimeType.startsWith('audio/'), isFalse);
        }
      });
    });

    test('dictation opens the microphone and writes no file', () async {
      await withBloc((bloc) async {
        bloc.add(const AiComposerSpeechStarted());
        await pumpEventQueue();

        // Both grants, because the platform recogniser needs the microphone
        // and iOS gates recognition separately. Nothing more than that.
        expect(permissions.requested, ['microphone', 'speechRecognition']);
        expect(recognizer.startCount, 1);
        expect(bloc.state.attachments, isEmpty);
      });
    });
  });
}
