import 'package:flutter_test/flutter_test.dart';
import 'package:invitation/src/data/models/responses/invitation_preview_response_dto.dart';
import 'package:invitation/src/domain/entities/invitation_status.dart';
import 'package:workers/workers.dart' show WorkerType;

void main() {
  group('InvitationPreviewModel.fromJson', () {
    test('valid: true carries every field through', () {
      final model = InvitationPreviewModel.fromJson(const {
        'valid': true,
        'email': 'worker@example.com',
        'workerType': 'manager',
        'providerName': 'Horizon Ventures',
      });

      expect(model.valid, isTrue);
      expect(model.status, isNull);
      expect(model.email, 'worker@example.com');
      expect(model.workerType, WorkerType.manager);
      expect(model.providerName, 'Horizon Ventures');
    });

    test('valid: false with a status (a real but inactionable invitation)', () {
      final model = InvitationPreviewModel.fromJson(const {
        'valid': false,
        'status': 'expired',
      });

      expect(model.valid, isFalse);
      expect(model.status, InvitationStatus.expired);
      expect(model.email, isNull);
      expect(model.workerType, isNull);
      expect(model.providerName, isNull);
    });

    test('valid: false with no other fields (an unknown/malformed token)', () {
      final model = InvitationPreviewModel.fromJson(const {'valid': false});

      expect(model.valid, isFalse);
      expect(model.status, isNull);
    });

    test('throws a FormatException when valid is missing', () {
      expect(
        () => InvitationPreviewModel.fromJson(const {'email': 'x@y.com'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
