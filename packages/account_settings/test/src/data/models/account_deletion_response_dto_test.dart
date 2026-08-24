import 'package:account_settings/src/data/models/account_deletion_response_dto.dart';
import 'package:account_settings/src/domain/enums/account_deletion_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountDeletionResponseDto.fromJson', () {
    Map<String, dynamic> baseJson({String status = 'scheduled'}) => {
      'id': 'req-1',
      'status': status,
      'initiator': 'self',
      'cascadeSummary': <String, dynamic>{'branches': 2},
      'verificationRequired': false,
      'scheduledExecutionDate': '2026-09-05T00:00:00.000Z',
      'gracePeriodDays': 14,
      'message': 'account_deletion.scheduled_status',
      'createdAt': '2026-08-22T00:00:00.000Z',
      'updatedAt': '2026-08-22T00:00:00.000Z',
    };

    for (final status in [
      'pending_verification',
      'scheduled',
      'executing',
      'completed',
      'cancelled',
      'failed',
      'restored',
    ]) {
      test('parses status "$status"', () {
        final entity = AccountDeletionResponseDto.fromJson(
          baseJson(status: status),
        ).toEntity();
        expect(entity.status, isNot(AccountDeletionStatus.unknown));
      });
    }

    test('maps an unrecognized status to unknown rather than throwing', () {
      final entity = AccountDeletionResponseDto.fromJson(
        baseJson(status: 'some_future_status'),
      ).toEntity();
      expect(entity.status, AccountDeletionStatus.unknown);
    });

    test('pending_verification and scheduled are cancellable', () {
      expect(
        AccountDeletionResponseDto.fromJson(
          baseJson(status: 'pending_verification'),
        ).toEntity().isCancellable,
        isTrue,
      );
      expect(
        AccountDeletionResponseDto.fromJson(
          baseJson(),
        ).toEntity().isCancellable,
        isTrue,
      );
    });

    test('executing is not cancellable', () {
      expect(
        AccountDeletionResponseDto.fromJson(
          baseJson(status: 'executing'),
        ).toEntity().isCancellable,
        isFalse,
      );
    });

    test('parses scheduledExecutionDate as a DateTime', () {
      final entity = AccountDeletionResponseDto.fromJson(
        baseJson(),
      ).toEntity();
      expect(entity.scheduledExecutionDate, isNotNull);
      expect(entity.scheduledExecutionDate!.year, 2026);
    });

    test('a null scheduledExecutionDate stays null', () {
      final json = baseJson()..['scheduledExecutionDate'] = null;
      final entity = AccountDeletionResponseDto.fromJson(json).toEntity();
      expect(entity.scheduledExecutionDate, isNull);
    });
  });
}
