import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_engine.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_fixtures.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_signal.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_stage.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_step.dart';

import 'journey_test_support.dart';

void main() {
  late AiJourneyEngine engine;

  setUp(() => engine = AiJourneyEngine());

  /// Walks the engine to the offer stage, which is where most branching starts.
  List<AiJourneyStep> toOffers() {
    engine
      ..respond(const AiJourneyTextSignal('I need a home cleaning tomorrow'))
      ..respond(AiJourneyInteractionSignal(locationSelected()))
      ..respond(AiJourneyInteractionSignal(permissionResult()));
    return engine.respond(AiJourneyInteractionSignal(mediaResult()));
  }

  group('opening the journey', () {
    test('a service request emits the existing location_picker node', () {
      final steps = engine.respond(
        const AiJourneyTextSignal('I need a home cleaning tomorrow at 10 AM'),
      );

      expect(typesOf(steps), ['location_picker']);
      expect(engine.stage, AiJourneyStage.locationRequired);
    });

    test('a paraphrase still starts it', () {
      expect(
        typesOf(engine.respond(const AiJourneyTextSignal('book a cleaner'))),
        ['location_picker'],
      );
    });

    test('an unrelated opener answers without starting the journey', () {
      final steps = engine.respond(const AiJourneyTextSignal('hello there'));

      expect(typesOf(steps), isEmpty);
      expect(steps.single.prose, isNotEmpty);
      expect(engine.stage, AiJourneyStage.idle);
    });
  });

  group('the location the user actually picked reaches the agent', () {
    test('location_selected advances, and the reply names the place', () {
      engine.respond(const AiJourneyTextSignal('home cleaning please'));

      final steps = engine.respond(
        AiJourneyInteractionSignal(
          locationSelected(name: 'Marina Gate 2, Dubai'),
        ),
      );

      // Read off the value, not off any message text: this is the assertion
      // that the map pick genuinely travelled.
      expect(steps.single.prose, contains('Marina Gate 2, Dubai'));
      expect(typesOf(steps), ['permission_request']);
      expect(engine.stage, AiJourneyStage.cameraPermissionRequired);
    });

    test('a saved or typed place works the same way', () {
      for (final source in [
        AiUiLocationSource.saved,
        AiUiLocationSource.typed,
      ]) {
        final fresh = AiJourneyEngine()
          ..respond(const AiJourneyTextSignal('home cleaning'));

        expect(
          typesOf(
            fresh.respond(
              AiJourneyInteractionSignal(locationSelected(source: source)),
            ),
          ),
          ['permission_request'],
          reason: 'source ${source.wire} should advance the same way',
        );
      }
    });

    test('answering it twice produces nothing the second time', () {
      engine
        ..respond(const AiJourneyTextSignal('home cleaning'))
        ..respond(AiJourneyInteractionSignal(locationSelected()));

      expect(
        engine.respond(AiJourneyInteractionSignal(locationSelected())),
        isEmpty,
      );
      expect(engine.stage, AiJourneyStage.cameraPermissionRequired);
    });

    test('a signal the stage is not waiting for is a no-op', () {
      engine.respond(const AiJourneyTextSignal('home cleaning'));

      expect(
        engine.respond(AiJourneyInteractionSignal(mediaResult())),
        isEmpty,
      );
      expect(engine.stage, AiJourneyStage.locationRequired);
    });
  });

  group('permission and media use the existing nodes', () {
    test('permission_result advances to media_request', () {
      engine
        ..respond(const AiJourneyTextSignal('home cleaning'))
        ..respond(AiJourneyInteractionSignal(locationSelected()));

      final steps = engine.respond(
        AiJourneyInteractionSignal(permissionResult()),
      );

      expect(typesOf(steps), ['media_request']);
      expect(engine.stage, AiJourneyStage.mediaRequired);
    });

    test('a refused camera is not re-offered on the media card', () {
      engine
        ..respond(const AiJourneyTextSignal('home cleaning'))
        ..respond(AiJourneyInteractionSignal(locationSelected()));

      final steps = engine.respond(
        AiJourneyInteractionSignal(
          permissionResult(outcome: AiUiPermissionOutcome.denied),
        ),
      );

      final options =
          steps.single.ui!.single['options']! as List<Map<String, dynamic>>;
      expect(options.map((o) => o['source']), ['gallery']);
    });

    test('media_result advances to the provider search and the offer', () {
      final steps = toOffers();

      expect(typesOf(steps), ['provider_search', 'provider_card']);
      expect(engine.stage, AiJourneyStage.providersFound);
    });

    test('staged attachments advance it too', () {
      engine
        ..respond(const AiJourneyTextSignal('home cleaning'))
        ..respond(AiJourneyInteractionSignal(locationSelected()))
        ..respond(AiJourneyInteractionSignal(permissionResult()));

      expect(
        typesOf(engine.respond(const AiJourneyAttachmentsSignal(2))),
        ['provider_search', 'provider_card'],
      );
    });

    test('zero photos is an answer, not a repeat of the question', () {
      engine
        ..respond(const AiJourneyTextSignal('home cleaning'))
        ..respond(AiJourneyInteractionSignal(locationSelected()))
        ..respond(AiJourneyInteractionSignal(permissionResult()));

      expect(
        typesOf(
          engine.respond(AiJourneyInteractionSignal(mediaResult(count: 0))),
        ),
        ['provider_search', 'provider_card'],
      );
    });
  });

  group('offers', () {
    test('the offer turn also publishes contextual content', () {
      final steps = toOffers();
      final context = steps.last.context;

      expect(context, isNotNull);
      expect(
        context!.peekLabel,
        contains('${AiJourneyFixtures.offerCount}'),
      );
      // The same node ids the transcript uses, so one shared ledger keeps the
      // two surfaces in step and one answer advances the journey once.
      expect(
        context.blocks.map((b) => b['id']),
        ['journey_provider_offer_0', 'journey_provider_offer_1'],
      );
      expect(context.blocks.map((b) => b['type']), [
        'provider_card',
        'provider_card',
      ]);
    });

    test(
      'accepting emits booking_summary and confirm_prompt in one document',
      () {
        toOffers();

        final steps = engine.respond(
          AiJourneyInteractionSignal(offerResolved()),
        );

        expect(steps, hasLength(1));
        expect(typesOf(steps), ['booking_summary', 'confirm_prompt']);
        expect(steps.single.clearsContext, isTrue);
        expect(engine.stage, AiJourneyStage.bookingSummary);
      },
    );

    test('declining offers the alternate rather than ending the story', () {
      toOffers();

      final steps = engine.respond(
        AiJourneyInteractionSignal(
          offerResolved(decision: AiUiOfferDecision.declined),
        ),
      );

      expect(typesOf(steps), ['provider_card']);
      expect(steps.single.ui!.single['name'], 'Carlos R');
      expect(engine.stage, AiJourneyStage.providersFound);
    });

    test('declining every alternate ends in the exhausted search card', () {
      toOffers();
      for (var i = 0; i <= AiJourneyFixtures.alternates.length; i++) {
        engine.respond(
          AiJourneyInteractionSignal(
            offerResolved(decision: AiUiOfferDecision.declined, index: i),
          ),
        );
      }

      expect(engine.stage, AiJourneyStage.searchingProviders);
    });

    test('accepting twice books once', () {
      toOffers();
      engine.respond(AiJourneyInteractionSignal(offerResolved()));

      expect(
        engine.respond(AiJourneyInteractionSignal(offerResolved())),
        isEmpty,
      );
    });
  });

  group('booking through to review', () {
    /// The whole happy path, and the node types it puts on screen in order.
    List<String> walk() {
      final types = <String>[...typesOf(toOffers())];
      void answer(AiJourneySignal signal) =>
          types.addAll(typesOf(engine.respond(signal)));

      answer(AiJourneyInteractionSignal(offerResolved()));
      answer(AiJourneyInteractionSignal(confirmationResolved()));
      // Reminder, then the three lifecycle steps: assigned, en route, in
      // progress, completed.
      for (var i = 0; i < 4; i++) {
        answer(const AiJourneyTextSignal('ok'));
      }
      return types;
    }

    test('every node is one the renderer already draws', () {
      const catalog = {
        'location_picker',
        'permission_request',
        'media_request',
        'provider_search',
        'provider_card',
        'booking_summary',
        'confirm_prompt',
        'appointment_card',
        'payment_receipt',
        'reminder_card',
        'service_timeline',
        'verification_code',
        'review_request',
      };

      expect(walk().toSet().difference(catalog), isEmpty);
    });

    test('confirming produces the appointment and the receipt', () {
      toOffers();
      engine.respond(AiJourneyInteractionSignal(offerResolved()));

      final steps = engine.respond(
        AiJourneyInteractionSignal(confirmationResolved()),
      );

      expect(
        typesOf(steps),
        containsAll(<String>['appointment_card', 'payment_receipt']),
      );
    });

    test('cancelling the confirmation does not book', () {
      toOffers();
      engine.respond(AiJourneyInteractionSignal(offerResolved()));

      final steps = engine.respond(
        AiJourneyInteractionSignal(confirmationResolved(confirmed: false)),
      );

      expect(typesOf(steps), ['provider_card']);
      expect(engine.stage, AiJourneyStage.providersFound);
    });

    test('the lifecycle reaches verification then review', () {
      final types = walk();

      expect(types, contains('verification_code'));
      expect(types, contains('review_request'));
      expect(engine.stage, AiJourneyStage.reviewRequested);
    });

    test('review_submitted completes the journey', () {
      walk();

      final steps = engine.respond(
        AiJourneyInteractionSignal(reviewSubmitted(comment: 'Spotless')),
      );

      expect(typesOf(steps), isEmpty);
      expect(steps.single.prose, contains('Spotless'));
      expect(engine.stage, AiJourneyStage.completed);
    });
  });

  group('reset', () {
    test('restarting forgets the stage, the offer and the spent cards', () {
      toOffers();
      engine
        ..respond(AiJourneyInteractionSignal(offerResolved()))
        ..respond(AiJourneyInteractionSignal(confirmationResolved()))
        ..reset();

      expect(engine.stage, AiJourneyStage.idle);
      // Not merely back at the start: the one-shot guard has to be clear too,
      // or the second run would reach the booking and print no receipt.
      expect(
        typesOf(engine.respond(const AiJourneyTextSignal('home cleaning'))),
        ['location_picker'],
      );
      toOffers();
      expect(
        typesOf(engine.respond(AiJourneyInteractionSignal(offerResolved()))),
        ['booking_summary', 'confirm_prompt'],
      );
    });
  });
}
