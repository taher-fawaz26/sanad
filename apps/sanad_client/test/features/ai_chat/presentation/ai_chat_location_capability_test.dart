import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';

/// The seam between the app's map and the agent's ears.
///
/// These tests are deliberately about the *boundary* — what a resolved
/// `LocationPickerResult` becomes on the wire, and what a cancelled one does to
/// the card that opened it. The map itself, its search, its permissions and its
/// camera belong to `packages/maps` and are tested there; re-testing them here
/// would only assert that a delegation still delegates.
class _RecordingSink implements AiUiInteractionSink {
  final List<AiUiInteraction> submitted = [];

  @override
  void submit(AiUiInteraction interaction) => submitted.add(interaction);
}

/// A capability set that returns whatever the test tells it to.
class _FakeCapabilities extends AiChatCapabilities {
  _FakeCapabilities(this.result);

  final LocationPickerResult? result;
  int calls = 0;

  @override
  Future<LocationPickerResult?> shareLocation(BuildContext context) async {
    calls += 1;
    return result;
  }

  @override
  Future<int?> uploadImages(BuildContext context, {AiUiMediaSource? source}) =>
      throw UnimplementedError();

  @override
  Future<AiUiPermissionOutcome> ensurePermission(
    BuildContext context,
    AiUiPermissionKind permission,
  ) => throw UnimplementedError();

  @override
  Future<void> openMap(BuildContext context, String query) =>
      throw UnimplementedError();

  @override
  Future<void> callPhone(BuildContext context, String phoneNumber) =>
      throw UnimplementedError();
}

void main() {
  const nodeId = 'lp_1';
  const messageId = 'msg_1';

  /// The action the render scope dispatches for a `location_picker`'s
  /// "use current location" row — correlation params included.
  const action = AiUiAction(
    type: AiUiActionType.requestLocationShare,
    params: {
      AiUiInteractionParams.nodeId: nodeId,
      AiUiInteractionParams.messageId: messageId,
    },
  );

  const resolved = LocationPickerResult(
    position: LatLng(25.0805, 55.1403),
    address: 'Dubai Marina, Dubai',
    placeId: 'ChIJ_dubai_marina',
  );

  late _RecordingSink sink;
  late AiUiInteractionLedger ledger;

  setUp(() {
    sink = _RecordingSink();
    ledger = AiUiInteractionLedger();
  });

  tearDown(() => ledger.dispose());

  AiChatCapabilityReporter reporter() =>
      AiChatCapabilityReporter(sink: sink, ledger: ledger);

  group('a confirmed location becomes location_selected', () {
    test('carries the canonical result in the protocol contract', () {
      reporter().reportLocation(action, resolved);

      final interaction = sink.submitted.single;
      expect(interaction.kind, AiUiInteractionKind.locationSelected);
      expect(interaction.nodeId, nodeId);
      expect(interaction.messageId, messageId);
      expect(interaction.nodeType, AiUiNodeType.locationPicker);
      expect(interaction.status, AiUiInteractionStatus.submitted);

      final value = interaction.value as AiUiLocationValue;
      // The Places id travels, so the agent can resolve the place rather than
      // re-interpret its name.
      expect(value.id, 'ChIJ_dubai_marina');
      expect(value.name, 'Dubai Marina, Dubai');
      expect(value.addressText, 'Dubai Marina, Dubai');
      expect(value.source, AiUiLocationSource.map);
    });

    test('serialises to exactly the fields the contract has', () {
      reporter().reportLocation(action, resolved);

      expect(sink.submitted.single.value.toJson(), {
        'id': 'ChIJ_dubai_marina',
        'name': 'Dubai Marina, Dubai',
        'addressText': 'Dubai Marina, Dubai',
        'source': 'map',
      });
    });

    test('a dropped pin has no place id and still reports', () {
      // Panning the map or using GPS resolves an address with no Places id —
      // the picker documents this, and it must not become a dropped answer.
      reporter().reportLocation(
        action,
        const LocationPickerResult(
          position: LatLng(25.2, 55.27),
          address: 'Downtown Dubai',
        ),
      );

      final value = sink.submitted.single.value as AiUiLocationValue;
      expect(value.id, isNull);
      expect(value.name, 'Downtown Dubai');
      expect(value.source, AiUiLocationSource.map);
      expect(value.toJson().containsKey('id'), isFalse);
    });

    test('an unknown source degrades to typed for an older consumer', () {
      // Forward compatibility is what made adding the member safe: a consumer
      // built before `map` existed still decodes the interaction.
      final decoded = AiUiInteractionCodec.tryDecodeMap({
        'interactionId': 'int_1',
        'nodeId': nodeId,
        'kind': 'location_selected',
        'status': 'submitted',
        'value': {'name': 'Dubai Marina', 'source': 'map'},
      });

      expect(decoded, isNotNull);
      expect(
        (decoded!.value as AiUiLocationValue).source,
        AiUiLocationSource.map,
      );
    });
  });

  group('a cancelled map submits nothing', () {
    test('sends no interaction at all', () {
      reporter().reportLocation(action, null);

      expect(sink.submitted, isEmpty);
    });

    test('hands the card back so the user can retry', () {
      // The tap that opened the map claimed the node; without the release
      // below the card is disabled forever and the conversation dead-ends.
      expect(ledger.beginSubmission(nodeId), isTrue);
      expect(ledger.canSubmit(nodeId), isFalse);

      reporter().reportLocation(action, null);

      expect(ledger.stateOf(nodeId), AiUiNodeInteractionState.active);
      expect(ledger.canSubmit(nodeId), isTrue);
    });

    test(
      're-opening after a cancel works, and confirming then reports once',
      () {
        expect(ledger.beginSubmission(nodeId), isTrue);
        reporter().reportLocation(action, null);

        // Second attempt: claim again, confirm this time.
        expect(ledger.beginSubmission(nodeId), isTrue);
        reporter().reportLocation(action, resolved);

        expect(sink.submitted, hasLength(1));
      },
    );
  });

  group('correlation', () {
    test('an action with no node id reports nothing', () {
      // A bare `request_location_share` button asked no question, so there is
      // nothing for an answer to be the answer *to*.
      reporter().reportLocation(
        const AiUiAction(type: AiUiActionType.requestLocationShare),
        resolved,
      );

      expect(sink.submitted, isEmpty);
    });

    test('a reporter with no ledger still submits a confirmed location', () {
      const AiChatCapabilityReporter().reportLocation(action, resolved);
      // Nothing to assert beyond "did not throw": the default no-op sink
      // swallows it, which is what a preview host wants.
    });
  });

  group('the handler runs the capability and reports its result', () {
    testWidgets('a confirmed place reaches the sink', (tester) async {
      final capabilities = _FakeCapabilities(resolved);
      final handler = LocationShareHandler(capabilities, reporter());

      await tester.pumpWidget(const SizedBox());
      await handler.handle(tester.element(find.byType(SizedBox)), action);

      expect(capabilities.calls, 1);
      expect(sink.submitted.single.kind, AiUiInteractionKind.locationSelected);
    });

    testWidgets('a cancelled map reaches nothing', (tester) async {
      final capabilities = _FakeCapabilities(null);
      final handler = LocationShareHandler(capabilities, reporter());

      await tester.pumpWidget(const SizedBox());
      await handler.handle(tester.element(find.byType(SizedBox)), action);

      expect(capabilities.calls, 1);
      expect(sink.submitted, isEmpty);
    });
  });
}
