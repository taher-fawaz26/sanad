import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/data/models/invitation_dto.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';

void main() {
  // Shaped after the backend `InvitationResponseDto` (OpenAPI 3.0.0).
  Map<String, dynamic> invitationJson() => {
    'id': 'inv_1',
    'email': 'jane.roe@example.com',
    'phone': '+971500000000',
    'name': 'Jane Roe',
    'jobTitle': 'Designer',
    'workerType': 'manager',
    'status': 'cancelled',
    'expiresAt': '2026-02-01T00:00:00.000Z',
    'createdAt': '2026-01-01T00:00:00.000Z',
  };

  group('InvitationDto.fromJson — contract', () {
    test('maps name→fullName and computes initials', () {
      final dto = InvitationDto.fromJson(invitationJson());
      expect(dto.id, 'inv_1');
      expect(dto.fullName, 'Jane Roe');
      expect(dto.email, 'jane.roe@example.com');
      expect(dto.phone, '+971500000000');
      expect(dto.initials, 'JR');
    });

    // Regression: role must come from `workerType`, NOT `type`.
    test('reads role from workerType, not type', () {
      final json = invitationJson()
        ..['workerType'] = 'manager'
        ..['type'] = 'worker'; // bogus legacy key must be ignored
      expect(InvitationDto.fromJson(json).role, 'manager');
    });

    test('defaults role to worker when workerType absent', () {
      final json = invitationJson()..remove('workerType');
      expect(InvitationDto.fromJson(json).role, 'worker');
    });

    test('parses createdAt→invitedAt and expiresAt', () {
      final dto = InvitationDto.fromJson(invitationJson());
      expect(dto.invitedAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(dto.expiresAt, DateTime.parse('2026-02-01T00:00:00.000Z'));
    });

    test('null date fields yield null', () {
      final json = invitationJson()
        ..['createdAt'] = null
        ..['expiresAt'] = null;
      final dto = InvitationDto.fromJson(json);
      expect(dto.invitedAt, isNull);
      expect(dto.expiresAt, isNull);
    });

    group('status enum (pending|accepted|expired|cancelled)', () {
      for (final entry in {
        'pending': InvitationStatus.pending,
        'accepted': InvitationStatus.accepted,
        'expired': InvitationStatus.expired,
        'cancelled': InvitationStatus.cancelled,
      }.entries) {
        test('${entry.key} → ${entry.value}', () {
          final json = invitationJson()..['status'] = entry.key;
          expect(InvitationDto.fromJson(json).status, entry.value);
        });
      }

      test('unknown status defaults to pending', () {
        final json = invitationJson()..['status'] = 'nonsense';
        expect(InvitationDto.fromJson(json).status, InvitationStatus.pending);
      });
    });
  });
}
