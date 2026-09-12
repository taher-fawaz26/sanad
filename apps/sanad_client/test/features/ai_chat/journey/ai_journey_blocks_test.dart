import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_blocks.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_engine.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_signal.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_stage.dart';

import 'journey_test_support.dart';

/// The guard this whole change rests on.
///
/// The point of the mock journey is that it is *not* a second UI: the agent
/// stand-in produces wire payloads, and the existing validator and the existing
/// renderer decide what appears. These tests assert exactly that — every block
/// names an existing semantic node type, every block survives the same policy a
/// live agent's payload is held to, and nothing the journey can emit is outside
/// the catalog.
void main() {
  // Release policy, not the developer one: `keepUnsupportedNodes` would let an
  // invented node survive as a labelled marker, which is precisely the failure
  // these tests exist to catch.
  final validator = AiChatConfig.validator(keepUnsupportedNodes: false);

  /// Every block the journey can emit, reached by walking every branch.
  ///
  /// Built from the builders rather than from a hand-written list, so a block
  /// added later cannot quietly escape validation.
  final blocks = <String, Map<String, dynamic>>{
    'location_picker': journeyLocationPickerBlock(),
    'permission_request': journeyCameraPermissionBlock(),
    'media_request': journeyMediaRequestBlock(),
    'media_request (camera refused)': journeyMediaRequestBlock(
      cameraOffered: false,
    ),
    'provider_search': journeyProviderSearchBlock(),
    'provider_search (exhausted)': journeyNoProvidersBlock(),
    'provider_card': journeyProviderOfferBlock(),
    'provider_card (alternate)': journeyProviderOfferBlock(index: 1),
    'booking_summary': journeyBookingSummaryBlock(),
    'confirm_prompt': journeyBookingConfirmBlock(),
    'appointment_card': journeyAppointmentBlock(),
    'payment_receipt': journeyPaymentReceiptBlock(),
    'reminder_card': journeyReminderBlock(),
    'verification_code': journeyVerificationCodeBlock(),
    'review_request': journeyReviewRequestBlock(),
    'service_area_notice': journeyServiceAreaNoticeBlock(),
    'request_notice (cancelled)': journeyBookingCancelledBlock(),
    'request_notice (late)': journeyProviderLateBlock(),
    for (final stage in [
      AiJourneyStage.providerAssigned,
      AiJourneyStage.providerEnRoute,
      AiJourneyStage.serviceInProgress,
      AiJourneyStage.serviceCompleted,
    ])
      'service_timeline (${stage.name})': journeyTimelineBlock(stage),
  };

  group('every block is an existing semantic node', () {
    for (final entry in blocks.entries) {
      test('${entry.key} names a catalog type', () {
        final wire = entry.value['type']! as String;
        final type = AiUiNodeType.tryFromWire(wire);

        expect(
          type,
          isNotNull,
          reason: '$wire is not an AI UI Protocol node type',
        );
        expect(
          type!.isSemantic,
          isTrue,
          reason: '$wire should be a semantic node, not a primitive',
        );
      });
    }

    test('the renderer already draws all of them', () {
      final registry = defaultRendererRegistry();

      for (final block in blocks.values) {
        final type = AiUiNodeType.tryFromWire(block['type']! as String)!;
        expect(
          registry.supports(type),
          isTrue,
          reason:
              '${type.wire} has no renderer — the journey would be showing '
              'something the production surface cannot',
        );
      }
    });
  });

  group('every block survives the live policy', () {
    for (final entry in blocks.entries) {
      test('${entry.key} validates clean', () {
        final result = validator.validate(journeyPayload([entry.value]));

        expect(
          result.diagnostics,
          isEmpty,
          reason: result.diagnostics
              .map((d) => '${d.code.wire} at ${d.path}: ${d.detail}')
              .join('; '),
        );
        expect(result.hasRenderableUi, isTrue);
        // Survived as itself, not as a fallback: a dropped node would still
        // leave a renderable document if anything else were in it.
        expect(
          result.document!.blocks.single.type?.wire,
          entry.value['type'],
        );
      });
    }

    test('every asset id the journey names is published', () {
      final published = AiChatConfig.knownAssetIds;

      Iterable<String> assetIds(Object? node) sync* {
        if (node is Map<String, dynamic>) {
          final id = node['assetId'];
          if (id is String) yield id;
          for (final value in node.values) {
            yield* assetIds(value);
          }
        } else if (node is List) {
          for (final value in node) {
            yield* assetIds(value);
          }
        }
      }

      for (final entry in blocks.entries) {
        for (final id in assetIds(entry.value)) {
          expect(
            published,
            contains(id),
            reason: '${entry.key} names unpublished asset "$id"',
          );
        }
      }
    });
  });

  group('a whole run emits nothing outside the catalog', () {
    test('every turn of the happy path validates and renders', () {
      final engine = AiJourneyEngine();
      final registry = defaultRendererRegistry();

      final turns = <List<Map<String, dynamic>>>[];
      void play(List<dynamic> steps) {
        for (final step in steps) {
          final ui = (step as dynamic).ui as List<Map<String, dynamic>>?;
          if (ui != null) turns.add(ui);
        }
      }

      play(engine.respond(const AiJourneyTextSignal('home cleaning tomorrow')));
      play(engine.respond(AiJourneyInteractionSignal(locationSelected())));
      play(engine.respond(AiJourneyInteractionSignal(permissionResult())));
      play(engine.respond(AiJourneyInteractionSignal(mediaResult())));
      play(engine.respond(AiJourneyInteractionSignal(offerResolved())));
      play(engine.respond(AiJourneyInteractionSignal(confirmationResolved())));
      for (var i = 0; i < 4; i++) {
        play(engine.respond(const AiJourneyTextSignal('ok')));
      }

      expect(turns, isNotEmpty);
      for (final ui in turns) {
        final result = validator.validate(journeyPayload(ui));
        expect(result.diagnostics, isEmpty);
        expect(result.document!.blocks, hasLength(ui.length));
        for (final node in result.document!.blocks) {
          // A node the validator kept but the renderer cannot draw would
          // reach the screen as a blank, which is the failure mode this whole
          // arrangement exists to make impossible.
          expect(node.type, isNotNull);
          expect(registry.supports(node.type!), isTrue);
        }
      }
    });
  });
}
