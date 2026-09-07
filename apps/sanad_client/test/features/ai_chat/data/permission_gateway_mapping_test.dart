import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/permissions.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/permissions_ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';

/// The mapping is the only part of the gateway with a decision in it, so it is
/// the part worth testing. Everything else is a one-line delegation to the
/// shared façade, which has its own tests in `packages/permissions`.
void main() {
  AiPermissionOutcome map(PermissionStatus status) =>
      PermissionsAiPermissionGateway.mapPermissionResult(
        PermissionResult(
          permission: PermissionType.microphone,
          status: status,
        ),
      );

  group('mapPermissionResult', () {
    test('granted is granted', () {
      expect(map(PermissionStatus.granted), AiPermissionOutcome.granted);
    });

    test('limited counts as granted', () {
      // iOS limited photo access is a real grant: the user chose which photos
      // to share and the picker shows exactly those. Reporting a refusal would
      // re-prompt someone who already answered.
      expect(map(PermissionStatus.limited), AiPermissionOutcome.granted);
    });

    test('provisional counts as granted', () {
      expect(map(PermissionStatus.provisional), AiPermissionOutcome.granted);
    });

    test('denied is denied and stays askable', () {
      final outcome = map(PermissionStatus.denied);

      expect(outcome, AiPermissionOutcome.denied);
      expect(outcome.needsSettings, isFalse);
    });

    test('permanentlyDenied is the only outcome that wants settings', () {
      final outcome = map(PermissionStatus.permanentlyDenied);

      expect(outcome, AiPermissionOutcome.permanentlyDenied);
      expect(outcome.needsSettings, isTrue);
    });

    test('restricted is unavailable, not permanently denied', () {
      // Policy — parental controls, MDM — forbids it. The settings screen
      // cannot fix that, so offering it would send the user somewhere useless.
      final outcome = map(PermissionStatus.restricted);

      expect(outcome, AiPermissionOutcome.unavailable);
      expect(outcome.needsSettings, isFalse);
    });

    test('unknown degrades to denied rather than granted', () {
      // Failing closed: an unreadable status must never be treated as consent.
      expect(map(PermissionStatus.unknown), AiPermissionOutcome.denied);
    });

    test('every PermissionStatus maps to something', () {
      for (final status in PermissionStatus.values) {
        expect(() => map(status), returnsNormally, reason: status.name);
      }
    });

    test('only granted reports isGranted', () {
      for (final outcome in AiPermissionOutcome.values) {
        expect(
          outcome.isGranted,
          outcome == AiPermissionOutcome.granted,
          reason: outcome.name,
        );
      }
    });
  });
}
