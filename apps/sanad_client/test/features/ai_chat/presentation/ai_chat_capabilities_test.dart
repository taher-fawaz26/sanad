import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:testing/testing.dart';

import '../support/composer_fakes.dart';

/// The action side of the AI card refresh.
///
/// A card's button only survives validation if its action is in
/// [AiChatConfig.supportedActions] **and** the registry has a handler for it.
/// These tests assert the third link in that chain: that dispatching the action
/// reaches app-owned code carrying the typed payload the card put in it, and
/// that the app's mapping of a protocol capability onto a device capability is
/// the one documented.
///
/// EasyLocalization is deliberately not bootstrapped — this repo's convention —
/// so `.tr()` falls back to the raw key.
class MockAiComposerBloc extends MockBloc<AiComposerEvent, AiComposerState>
    implements AiComposerBloc {}

/// Records what the handler asked for instead of touching a device.
class RecordingCapabilities extends AiChatCapabilities {
  RecordingCapabilities({
    this.locationResult,
    this.permissionOutcome = AiUiPermissionOutcome.granted,
  });

  final List<String> calls = [];

  /// What the app's location flow resolved, or `null` for a user who backed
  /// out of the map without confirming.
  final LocationPickerResult? locationResult;

  /// What the platform prompt is pretended to have returned.
  final AiUiPermissionOutcome permissionOutcome;

  @override
  Future<LocationPickerResult?> shareLocation(BuildContext context) async {
    calls.add('shareLocation');
    return locationResult;
  }

  @override
  Future<int?> uploadImages(
    BuildContext context, {
    AiUiMediaSource? source,
  }) async {
    calls.add('uploadImages:${source?.wire}');
    return uploadedCount;
  }

  /// What the fake picker reports back. `null` is "backed out".
  int? uploadedCount;

  @override
  Future<AiUiPermissionOutcome> ensurePermission(
    BuildContext context,
    AiUiPermissionKind permission,
  ) async {
    calls.add('ensurePermission:${permission.wire}');
    return permissionOutcome;
  }

  @override
  Future<void> openMap(BuildContext context, String query) async =>
      calls.add('openMap:$query');

  @override
  Future<void> callPhone(BuildContext context, String phoneNumber) async =>
      calls.add('callPhone:$phoneNumber');
}

void main() {
  /// Dispatches [action] from a real [BuildContext] and returns once the
  /// handler's future completes.
  Future<void> dispatch(
    WidgetTester tester,
    AiActionRegistry registry,
    AiUiAction action, {
    Widget Function(Widget child)? wrap,
  }) async {
    late BuildContext captured;
    final probe = Builder(
      builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      },
    );
    await pumpDsWidget(tester, wrap == null ? probe : wrap(probe));
    await registry.dispatch(captured, action);
    await tester.pump();
  }

  group('registry dispatch', () {
    late RecordingCapabilities capabilities;
    late AiActionRegistry registry;

    setUp(() {
      capabilities = RecordingCapabilities();
      registry = buildAiChatActionRegistry(
        onSendMessage: (_) {},
        capabilities: capabilities,
      );
    });

    test('implements exactly the declared supported set', () {
      // Restated here because this file is where a new capability action gets
      // added: forgetting either side leaves a button that validates and then
      // does nothing, or an action the validator drops for no reason.
      expect(registry.supportedTypes, equals(AiChatConfig.supportedActions));
    });

    testWidgets('request_permission passes the named capability', (
      tester,
    ) async {
      await dispatch(
        tester,
        registry,
        const AiUiAction(
          type: AiUiActionType.requestPermission,
          params: {'permission': 'location'},
        ),
      );

      expect(capabilities.calls, ['ensurePermission:location']);
    });

    testWidgets('request_permission with an unknown capability does nothing', (
      tester,
    ) async {
      // Unreachable through the validator, which drops the card first. Asserted
      // so a cached payload from an older catalog cannot crash a tap.
      await dispatch(
        tester,
        registry,
        const AiUiAction(
          type: AiUiActionType.requestPermission,
          params: {'permission': 'contacts'},
        ),
      );

      expect(capabilities.calls, isEmpty);
    });

    testWidgets('open_map forwards the bounded query verbatim', (tester) async {
      await dispatch(
        tester,
        registry,
        const AiUiAction(
          type: AiUiActionType.openMap,
          params: {'query': '25.2048,55.2708'},
        ),
      );

      expect(capabilities.calls, ['openMap:25.2048,55.2708']);
    });

    testWidgets('call_phone forwards the number', (tester) async {
      await dispatch(
        tester,
        registry,
        const AiUiAction(
          type: AiUiActionType.callPhone,
          params: {'phone': '+971500000000'},
        ),
      );

      expect(capabilities.calls, ['callPhone:+971500000000']);
    });

    testWidgets('request_image_upload carries the suggested source', (
      tester,
    ) async {
      await dispatch(
        tester,
        registry,
        const AiUiAction(
          type: AiUiActionType.requestImageUpload,
          params: {'source': 'camera'},
        ),
      );

      expect(capabilities.calls, ['uploadImages:camera']);
    });

    testWidgets('request_image_upload without a source stays unopinionated', (
      tester,
    ) async {
      await dispatch(
        tester,
        registry,
        const AiUiAction(type: AiUiActionType.requestImageUpload),
      );

      expect(capabilities.calls, ['uploadImages:null']);
    });

    testWidgets('an unregistered action is dropped, not thrown', (
      tester,
    ) async {
      await dispatch(
        tester,
        registry,
        const AiUiAction(
          type: AiUiActionType.openUrl,
          params: {'url': 'https://example.com'},
        ),
      );

      expect(capabilities.calls, isEmpty);
    });
  });

  group('ComposerAiChatCapabilities.ensurePermission', () {
    late FakePermissionGateway gateway;
    late AiChatCapabilities capabilities;

    setUp(() {
      gateway = FakePermissionGateway();
      capabilities = ComposerAiChatCapabilities(gateway: gateway);
    });

    /// Every protocol capability resolves through the feature's single
    /// permission boundary — the same gateway the composer's paperclip uses.
    const mapping = {
      AiUiPermissionKind.camera: 'camera',
      AiUiPermissionKind.photos: 'gallery',
      AiUiPermissionKind.microphone: 'microphone',
      AiUiPermissionKind.location: 'location',
      AiUiPermissionKind.notifications: 'notifications',
    };

    for (final entry in mapping.entries) {
      testWidgets('${entry.key.wire} asks the gateway for ${entry.value}', (
        tester,
      ) async {
        late BuildContext captured;
        await pumpDsWidget(
          tester,
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        );

        await capabilities.ensurePermission(captured, entry.key);

        expect(gateway.requested, [entry.value]);
      });
    }

    testWidgets('a denial surfaces a message rather than failing silently', (
      tester,
    ) async {
      gateway.location = AiPermissionOutcome.permanentlyDenied;
      late BuildContext captured;
      // A Scaffold because the refusal is surfaced as a snackbar, which needs
      // a ScaffoldMessenger above it — the chat page always has one.
      await pumpDsWidget(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await capabilities.ensurePermission(
        captured,
        AiUiPermissionKind.location,
      );
      await tester.pump();

      expect(find.text('ai_chat.permission_denied_permanently'), findsOne);
    });
  });

  group('ComposerAiChatCapabilities.uploadImages', () {
    late MockAiComposerBloc bloc;

    setUpAll(() {
      registerFallbackValue(
        const AiComposerAttachmentRequested(AiAttachmentIntent.camera),
      );
    });

    /// One run of the composer's picker, as the bloc publishes it: the picker
    /// opens, then settles with whatever was staged.
    ///
    /// The capability reads exactly this — no new state, no callback — which is
    /// what lets `request_image_upload` be answered without a second pipeline.
    Stream<AiComposerState> picking({int staged = 0}) => Stream.fromIterable([
      const AiComposerState(isPicking: true),
      AiComposerState(
        attachments: List.generate(staged, _staged),
      ),
    ]);

    setUp(() {
      bloc = MockAiComposerBloc();
      whenListen(
        bloc,
        picking(staged: 2),
        initialState: const AiComposerState(),
      );
    });

    tearDown(() => bloc.close());

    /// The agent names a *source*; the composer speaks in attachment intents,
    /// and video shares the gallery picker because the composer validates type
    /// and size afterwards.
    const mapping = {
      AiUiMediaSource.camera: AiAttachmentIntent.camera,
      AiUiMediaSource.gallery: AiAttachmentIntent.gallery,
      AiUiMediaSource.video: AiAttachmentIntent.gallery,
      AiUiMediaSource.document: AiAttachmentIntent.document,
    };

    for (final entry in mapping.entries) {
      testWidgets('${entry.key.wire} routes to ${entry.value.name}', (
        tester,
      ) async {
        late BuildContext captured;
        await pumpDsWidget(
          tester,
          BlocProvider<AiComposerBloc>.value(
            value: bloc,
            child: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final count = await const ComposerAiChatCapabilities().uploadImages(
          captured,
          source: entry.key,
        );

        verify(
          () => bloc.add(AiComposerAttachmentRequested(entry.value)),
        ).called(1);
        // The capability reports what the picker actually produced, so the
        // agent that asked for photos learns that it got two.
        expect(count, 2);
      });
    }

    testWidgets('an empty picker run reads as backing out, not zero', (
      tester,
    ) async {
      whenListen(bloc, picking(), initialState: const AiComposerState());

      late BuildContext captured;
      await pumpDsWidget(
        tester,
        BlocProvider<AiComposerBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Nothing staged means the sheet was dismissed or everything was
      // rejected by validation. Both are "the user did not answer", and
      // reporting zero instead would have the agent carry on as though the
      // photos had been refused.
      expect(
        await const ComposerAiChatCapabilities().uploadImages(captured),
        isNull,
      );
    });

    testWidgets('a picker that never opens does not hang the handler', (
      tester,
    ) async {
      // The bloc refuses outright when the staging area is full, and never
      // raises `isPicking`. Waiting for a rise that will not come would strand
      // the card that asked.
      whenListen(
        bloc,
        const Stream<AiComposerState>.empty(),
        initialState: const AiComposerState(),
      );

      late BuildContext captured;
      await pumpDsWidget(
        tester,
        BlocProvider<AiComposerBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final pending = const ComposerAiChatCapabilities().uploadImages(captured);
      await tester.pump(const Duration(seconds: 2));
      expect(await pending, isNull);
    });
  });
}

/// One staged photo, in the only shape the capability actually reads: it counts
/// them and never looks inside.
AiChatAttachment _staged(int index) => AiImageAttachment(
  id: 'att_$index',
  fileName: 'photo_$index.jpg',
  sizeBytes: 1024,
  mimeType: 'image/jpeg',
  localPath: '/tmp/photo_$index.jpg',
);
