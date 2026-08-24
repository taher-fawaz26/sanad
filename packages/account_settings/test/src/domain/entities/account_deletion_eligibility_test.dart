import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';
import 'package:account_settings/src/domain/entities/deletion_blocker.dart';
import 'package:account_settings/src/domain/entities/deletion_cascade_preview.dart';
import 'package:account_settings/src/domain/enums/deletion_blocker_code.dart';
import 'package:account_settings/src/domain/enums/deletion_persona.dart';
import 'package:flutter_test/flutter_test.dart';

const _cascade = DeletionCascadePreview(
  persona: DeletionPersona.companyProvider,
  branches: 0,
  services: 0,
  teamAccounts: 0,
  invitations: 0,
  documents: 0,
  media: 0,
  branchesUnassigned: 0,
);

AccountDeletionEligibility _withBlockers(List<DeletionBlocker> blockers) =>
    AccountDeletionEligibility(
      isEligible: blockers.isEmpty,
      gracePeriodDays: 14,
      blockers: blockers,
      warnings: const [],
      cascadePreview: _cascade,
    );

const _alreadyPending = DeletionBlocker(
  code: DeletionBlockerCode.alreadyPendingDeletion,
  rawCode: 'ALREADY_PENDING_DELETION',
  message: 'in progress',
);

const _lastAdmin = DeletionBlocker(
  code: DeletionBlockerCode.lastActiveSuperAdmin,
  rawCode: 'LAST_ACTIVE_SUPER_ADMIN',
  message: 'last admin',
);

void main() {
  group('AccountDeletionEligibility.hardBlockers', () {
    test('an already-pending request is not a hard blocker', () {
      final e = _withBlockers(const [_alreadyPending]);
      expect(e.hasBlockers, isTrue);
      expect(e.hasHardBlockers, isFalse);
      expect(e.hardBlockers, isEmpty);
    });

    test('a genuine dead-end is a hard blocker', () {
      final e = _withBlockers(const [_lastAdmin]);
      expect(e.hasHardBlockers, isTrue);
      expect(
        e.hardBlockers.single.code,
        DeletionBlockerCode.lastActiveSuperAdmin,
      );
    });

    test('already-pending is filtered out but real blockers remain', () {
      final e = _withBlockers(const [_alreadyPending, _lastAdmin]);
      expect(e.hasHardBlockers, isTrue);
      expect(e.hardBlockers, hasLength(1));
      expect(
        e.hardBlockers.single.code,
        DeletionBlockerCode.lastActiveSuperAdmin,
      );
    });

    test('no blockers means no hard blockers', () {
      final e = _withBlockers(const []);
      expect(e.hasHardBlockers, isFalse);
    });
  });
}
