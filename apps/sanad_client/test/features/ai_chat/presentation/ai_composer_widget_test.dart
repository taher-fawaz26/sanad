import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_recording_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_speech_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/audio_playback_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/recording_level_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/speech_transcript_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_level_meter.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_recording_bar.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_speech_bar.dart';
import 'package:testing/testing.dart';

import '../support/attachment_fixtures.dart';

/// Widget behaviour of the composer.
///
/// ## Why a mocked bloc
///
/// `testing.md` prefers one when a test only needs to render a given state, and
/// here it is the only workable choice: `testWidgets` runs its body in a
/// `FakeAsync` zone, so a real bloc built outside it never settles under
/// `tester.pump`, and one built inside it cannot be closed from teardown.
/// `ai_chat_widget_test.dart` documents the same hazard from the other side.
///
/// So this file asserts the two things a widget test should: that a given state
/// renders the right controls, and that a tap emits the right event. What those
/// events then *do* is covered by `ai_composer_bloc_test.dart` against real
/// fakes.
///
/// EasyLocalization is deliberately not bootstrapped — this repo's convention —
/// so `.tr()` falls back to the raw key and assertions read against keys.
class MockAiComposerBloc extends MockBloc<AiComposerEvent, AiComposerState>
    implements AiComposerBloc {}

void main() {
  late MockAiComposerBloc bloc;
  late RecordingLevelController level;
  late AudioPlaybackController playback;
  late List<String> sent;
  late SpeechTranscriptController transcript;
  late int voiceTaps;

  setUpAll(() {
    registerFallbackValue(
      const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
    );
  });

  setUp(() {
    bloc = MockAiComposerBloc();
    level = RecordingLevelController();
    playback = AudioPlaybackController();
    sent = [];
    transcript = SpeechTranscriptController();
    voiceTaps = 0;

    // The hot-path controllers are real. They are plain `ValueNotifier`s with
    // no async of their own, and several tests below exist precisely to show
    // the widget reads them directly rather than through bloc state.
    when(() => bloc.recordingLevel).thenReturn(level);
    when(() => bloc.playback).thenReturn(playback);
    when(() => bloc.transcript).thenReturn(transcript);
  });

  tearDown(() {
    level.dispose();
    playback.dispose();
    transcript.dispose();
  });

  /// Renders the composer over [state].
  Future<void> pumpComposer(
    WidgetTester tester, [
    AiComposerState state = const AiComposerState(),
  ]) async {
    whenListen(
      bloc,
      const Stream<AiComposerState>.empty(),
      initialState: state,
    );
    await pumpDsWidget(
      tester,
      BlocProvider<AiComposerBloc>.value(
        value: bloc,
        child: Scaffold(
          body: AiComposer(
            onSend: sent.add,
            onVoice: () => voiceTaps++,
          ),
        ),
      ),
    );
  }

  group('the send affordance', () {
    testWidgets('starts as a microphone, with nothing to send', (tester) async {
      await pumpComposer(tester);

      expect(find.bySemanticsLabel('ai_chat.speech_start'), findsOneWidget);
      expect(find.bySemanticsLabel('ai_chat.send'), findsNothing);
    });

    testWidgets('becomes send once there is text', (tester) async {
      await pumpComposer(tester);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      expect(find.bySemanticsLabel('ai_chat.send'), findsOneWidget);
      expect(find.bySemanticsLabel('ai_chat.speech_start'), findsNothing);
    });

    testWidgets('is send when an attachment is staged, with no text', (
      tester,
    ) async {
      // A photo with no caption is a legitimate turn.
      await pumpComposer(
        tester,
        AiComposerState(
          attachments: [documentFixture(status: AiAttachmentStatus.ready)],
        ),
      );

      expect(find.bySemanticsLabel('ai_chat.send'), findsOneWidget);
    });

    testWidgets('sending forwards the trimmed text and clears the field', (
      tester,
    ) async {
      await pumpComposer(tester);

      await tester.enterText(find.byType(TextField), '  find me a service  ');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('ai_chat.send'));
      await tester.pump();

      expect(sent, ['find me a service']);
      expect(find.text('  find me a service  '), findsNothing);
    });

    testWidgets('whitespace alone never becomes send', (tester) async {
      await pumpComposer(tester);

      await tester.enterText(find.byType(TextField), '     ');
      await tester.pump();

      expect(find.bySemanticsLabel('ai_chat.send'), findsNothing);
    });

    testWidgets('a still-preparing attachment blocks sending', (tester) async {
      await pumpComposer(
        tester,
        AiComposerState(
          attachments: [documentFixture(status: AiAttachmentStatus.processing)],
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      expect(find.bySemanticsLabel('ai_chat.send'), findsNothing);
    });
  });

  group('attachments', () {
    testWidgets('each staged attachment gets a tile', (tester) async {
      await pumpComposer(
        tester,
        AiComposerState(
          attachments: [
            documentFixture(id: 'a', status: AiAttachmentStatus.ready),
            documentFixture(id: 'b', status: AiAttachmentStatus.ready),
          ],
        ),
      );

      expect(
        find.byIcon(Icons.close_rounded),
        findsNWidgets(2),
      );
    });

    testWidgets('a document tile names its extension', (tester) async {
      await pumpComposer(
        tester,
        AiComposerState(
          attachments: [
            documentFixture(
              extension: 'xlsx',
              status: AiAttachmentStatus.ready,
            ),
          ],
        ),
      );

      expect(find.text('XLSX'), findsOneWidget);
    });

    testWidgets('a preparing attachment shows a spinner', (tester) async {
      await pumpComposer(
        tester,
        AiComposerState(
          attachments: [documentFixture(status: AiAttachmentStatus.processing)],
        ),
      );

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('tapping remove emits the removal, it does not delete', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        AiComposerState(
          attachments: [
            documentFixture(id: 'doc-1', status: AiAttachmentStatus.ready),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      // The widget asks; the bloc decides — including whether the file is ours
      // to delete at all.
      verify(
        () => bloc.add(const AiComposerAttachmentRemoved('doc-1')),
      ).called(1);
    });

    testWidgets('the attach button opens a menu and touches no picker', (
      tester,
    ) async {
      await pumpComposer(tester);

      await tester.tap(find.bySemanticsLabel('ai_chat.attach'));
      await _openSheet(tester);

      expect(find.text('ai_chat.attach_camera'), findsOneWidget);
      expect(find.text('ai_chat.attach_gallery'), findsOneWidget);
      expect(find.text('ai_chat.attach_document'), findsOneWidget);
      // Nothing requested yet: the widget cannot open a camera itself.
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('choosing a source emits that intent', (tester) async {
      await pumpComposer(tester);

      await tester.tap(find.bySemanticsLabel('ai_chat.attach'));
      await _openSheet(tester);
      await tester.tap(find.text('ai_chat.attach_camera'));
      await _openSheet(tester);

      verify(
        () => bloc.add(
          const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
        ),
      ).called(1);
    });

    testWidgets('the attach button is disabled while a picker is open', (
      tester,
    ) async {
      await pumpComposer(tester, const AiComposerState(isPicking: true));

      await tester.tap(find.bySemanticsLabel('ai_chat.attach'));
      await tester.pump();

      verifyNever(() => bloc.add(any()));
    });
  });

  group('recording', () {
    testWidgets('the microphone dictates, it does not record', (
      tester,
    ) async {
      // The three microphone capabilities each get their own affordance. This
      // one produces text, so it is the one on the keyboard's edge.
      await pumpComposer(tester);

      await tester.tap(find.bySemanticsLabel('ai_chat.speech_start'));
      await tester.pump();

      verify(() => bloc.add(const AiComposerSpeechStarted())).called(1);
      verifyNever(() => bloc.add(const AiComposerRecordingStarted()));
    });

    testWidgets('recording swaps the input row for the bar', (tester) async {
      await pumpComposer(
        tester,
        const AiComposerState(recording: AiRecordingStatus.recording),
      );

      expect(find.byType(AiRecordingContentRow), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.bySemanticsLabel('ai_chat.record_stop'), findsOneWidget);
      expect(find.bySemanticsLabel('ai_chat.record_cancel'), findsOneWidget);
    });

    testWidgets('the bar follows the level controller, not bloc state', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        const AiComposerState(recording: AiRecordingStatus.recording),
      );

      // No state is emitted here at all — the controller alone drives the row.
      // That is the whole reason a microphone tick cannot rebuild the composer.
      level.value = const AiRecordingSample(
        level: 0.7,
        elapsed: Duration(seconds: 12),
      );
      await tester.pump();

      expect(find.textContaining('0:12'), findsOneWidget);
      expect(find.byType(AiLevelMeter), findsOneWidget);

      level.value = const AiRecordingSample(
        level: 0.2,
        elapsed: Duration(seconds: 65),
      );
      await tester.pump();

      expect(find.textContaining('1:05'), findsOneWidget);
    });

    testWidgets('stop and cancel emit their events', (tester) async {
      await pumpComposer(
        tester,
        const AiComposerState(recording: AiRecordingStatus.recording),
      );

      await tester.tap(find.bySemanticsLabel('ai_chat.record_stop'));
      await tester.pump();
      verify(() => bloc.add(const AiComposerRecordingStopped())).called(1);

      await tester.tap(find.bySemanticsLabel('ai_chat.record_cancel'));
      await tester.pump();
      verify(() => bloc.add(const AiComposerRecordingCancelled())).called(1);
    });

    testWidgets('a finished take returns the input row and stages a tile', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        AiComposerState(
          recording: AiRecordingStatus.preview,
          attachments: [audioFixture(status: AiAttachmentStatus.ready)],
        ),
      );

      expect(find.byType(AiRecordingContentRow), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.byIcon(Icons.close_rounded),
        findsOneWidget,
      );
    });

    testWidgets('the remove control carries an accessible label', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        AiComposerState(
          attachments: [documentFixture(status: AiAttachmentStatus.ready)],
        ),
      );

      // Read off the `Semantics` widget itself rather than the rendered
      // semantics tree: the control is an icon, so the label we attach is its
      // only name, and this asserts it is attached at all.
      final semantics = tester.widgetList<Semantics>(
        find.ancestor(
          of: find.byIcon(Icons.close_rounded),
          matching: find.byType(Semantics),
        ),
      );

      expect(
        semantics.any(
          (s) => s.properties.label == 'ai_chat.remove_attachment',
        ),
        isTrue,
      );
    });

    testWidgets('a refused microphone leaves the composer usable', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        const AiComposerState(recording: AiRecordingStatus.permissionDenied),
      );

      expect(find.byType(AiRecordingContentRow), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('the widget owns no capability', () {
    testWidgets('an affordance emits an event and does nothing else', (
      tester,
    ) async {
      await pumpComposer(tester);

      // If this stops being true the composer stops being replaceable, which
      // is the entire premise of shipping temporary UI.
      await tester.tap(find.bySemanticsLabel('ai_chat.speech_start'));
      await tester.pump();

      verify(() => bloc.add(const AiComposerSpeechStarted())).called(1);
    });
  });

  group('the three microphone capabilities are distinct', () {
    testWidgets('each has its own affordance, none overloaded', (tester) async {
      await pumpComposer(tester);

      // Dictation on the trailing edge, live voice beside attach, and a voice
      // note inside the attach sheet with the other attachments. Three
      // results, three controls.
      expect(find.bySemanticsLabel('ai_chat.speech_start'), findsOneWidget);
      expect(find.bySemanticsLabel('ai_chat.voice_mode'), findsOneWidget);
      expect(find.bySemanticsLabel('ai_chat.attach'), findsOneWidget);
    });

    testWidgets('live voice is a callback, not a route the widget knows', (
      tester,
    ) async {
      await pumpComposer(tester);

      await tester.tap(find.bySemanticsLabel('ai_chat.voice_mode'));
      await tester.pump();

      // The page navigates. A leaf widget that knew the route would be the
      // thing `routing.md` forbids.
      expect(voiceTaps, 1);
    });

    testWidgets('live voice is unavailable while the mic is busy', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        const AiComposerState(recording: AiRecordingStatus.recording),
      );

      // The recording bar has replaced the input row, so there is no way to
      // start a competing session from here at all.
      expect(find.bySemanticsLabel('ai_chat.voice_mode'), findsNothing);
    });

    testWidgets('a voice note is offered with the other attachments', (
      tester,
    ) async {
      await pumpComposer(tester);

      await tester.tap(find.bySemanticsLabel('ai_chat.attach'));
      await _openSheet(tester);

      final entry = find.text('ai_chat.attach_record_audio');
      expect(entry, findsOneWidget);

      // The sheet scrolls: a fourth row can sit outside the viewport at a
      // large text size, and tapping a clipped tile hits whatever is drawn
      // over it instead.
      await tester.ensureVisible(entry);
      await tester.pump();
      await tester.tap(entry);
      await _openSheet(tester);

      // A capture rather than a pick, so it dispatches the recording event —
      // the split that keeps `AiAttachmentIntent` meaning "what a picker can
      // return".
      verify(() => bloc.add(const AiComposerRecordingStarted())).called(1);
    });
  });

  group('dictation', () {
    testWidgets('listening swaps the input row for the speech bar', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        const AiComposerState(speech: AiSpeechStatus.listening),
      );

      expect(find.byType(AiSpeechContentRow), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.bySemanticsLabel('ai_chat.speech_stop'), findsOneWidget);
      expect(find.bySemanticsLabel('ai_chat.speech_cancel'), findsOneWidget);
    });

    testWidgets('the bar follows the transcript controller, not bloc state', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        const AiComposerState(speech: AiSpeechStatus.listening),
      );

      expect(find.text('ai_chat.speech_listening'), findsOneWidget);

      // No new state is emitted — the words arrive on the hot path, exactly
      // as the recording meter's level does.
      transcript.value = const AiSpeechTranscript(
        text: 'book a table',
        isFinal: false,
      );
      await tester.pump();

      expect(find.text('book a table'), findsOneWidget);
    });

    testWidgets('stop and cancel emit their events', (tester) async {
      await pumpComposer(
        tester,
        const AiComposerState(speech: AiSpeechStatus.listening),
      );

      await tester.tap(find.bySemanticsLabel('ai_chat.speech_stop'));
      await tester.pump();
      verify(() => bloc.add(const AiComposerSpeechStopped())).called(1);

      await tester.tap(find.bySemanticsLabel('ai_chat.speech_cancel'));
      await tester.pump();
      verify(() => bloc.add(const AiComposerSpeechCancelled())).called(1);
    });

    testWidgets('stop is disabled while the recogniser is settling', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        const AiComposerState(speech: AiSpeechStatus.finalizing),
      );

      await tester.tap(find.bySemanticsLabel('ai_chat.speech_stop'));
      await tester.pump();

      verifyNever(() => bloc.add(const AiComposerSpeechStopped()));
    });

    testWidgets('a finished transcript is ordinary editable text', (
      tester,
    ) async {
      await pumpComposer(tester);

      transcript.value = const AiSpeechTranscript(
        text: 'book a table',
        isFinal: true,
      );
      await tester.pump();

      // In the field, not in a bubble and not in an attachment — and still
      // typeable, which is the whole point of dictation over a voice note.
      expect(find.text('book a table'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'book a table for two');
      await tester.pump();

      expect(find.bySemanticsLabel('ai_chat.send'), findsOneWidget);
    });

    testWidgets('the microphone is unavailable once there is text', (
      tester,
    ) async {
      await pumpComposer(tester);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      // The microphone gives way to send, which is the gesture every chat app
      // uses — and the reason dictation always begins from an empty composer
      // and replaces rather than appends.
      expect(find.bySemanticsLabel('ai_chat.speech_start'), findsNothing);
      expect(find.bySemanticsLabel('ai_chat.send'), findsOneWidget);
    });
  });

  group('a voice note still looks and behaves like a voice note', () {
    testWidgets('a staged take is an ordinary removable tile', (
      tester,
    ) async {
      // The no-regression guard for the transcript work: the transcript is
      // metadata that rides to the backend, and must change nothing here.
      await pumpComposer(
        tester,
        AiComposerState(
          recording: AiRecordingStatus.preview,
          attachments: [
            audioFixture(
              status: AiAttachmentStatus.ready,
              transcript: 'book me a plumber for tomorrow morning',
            ),
          ],
        ),
      );

      // The composer stages every attachment as a tile; the waveform and the
      // play control live on the bubble, and are covered there.
      expect(find.byType(AiAttachmentTile), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('the transcript is never rendered as text', (tester) async {
      // A voice message shows a waveform, not a wall of recognised words. The
      // transcript exists so the model can read the note, not the user.
      await pumpComposer(
        tester,
        AiComposerState(
          recording: AiRecordingStatus.preview,
          attachments: [
            audioFixture(
              status: AiAttachmentStatus.ready,
              transcript: 'book me a plumber for tomorrow morning',
            ),
          ],
        ),
      );

      expect(find.text('book me a plumber for tomorrow morning'), findsNothing);
    });

    testWidgets('a take with no transcript renders identically', (
      tester,
    ) async {
      await pumpComposer(
        tester,
        AiComposerState(
          recording: AiRecordingStatus.preview,
          attachments: [audioFixture(status: AiAttachmentStatus.ready)],
        ),
      );

      expect(find.byType(AiAttachmentTile), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}

/// Advances the sheet's entry/exit animation with bounded pumps.
///
/// `pumpAndSettle` is the obvious call and the wrong one: `testing.md` rules it
/// out on an animated surface, and the sheet route's transition makes it wait
/// for a frame budget it never reaches.
Future<void> _openSheet(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }}
