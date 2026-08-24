import 'package:account_settings/src/data/models/account_deletion_eligibility_dto.dart';
import 'package:account_settings/src/domain/enums/deletion_blocker_code.dart';
import 'package:account_settings/src/domain/enums/deletion_persona.dart';
import 'package:account_settings/src/domain/enums/deletion_warning_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountDeletionEligibilityDto.fromJson', () {
    test('parses the documented example response', () {
      final json = {
        'isEligible': true,
        'gracePeriodDays': 14,
        'blockers': <dynamic>[],
        'warnings': [
          {
            'code': 'TEAM_ACCOUNTS_DELETED',
            'message':
                '3 team account(s) will be deleted along with the '
                'company.',
            'details': {'count': 3},
          },
        ],
        'cascadePreview': {
          'persona': 'companyProvider',
          'branches': 2,
          'services': 5,
          'teamAccounts': 3,
          'invitations': 1,
          'documents': 2,
          'media': 8,
          'branchesUnassigned': 0,
        },
      };

      final entity = AccountDeletionEligibilityDto.fromJson(json).toEntity();

      expect(entity.isEligible, isTrue);
      expect(entity.gracePeriodDays, 14);
      expect(entity.blockers, isEmpty);
      expect(entity.warnings, hasLength(1));
      expect(
        entity.warnings.single.code,
        DeletionWarningCode.teamAccountsDeleted,
      );
      expect(entity.cascadePreview.persona, DeletionPersona.companyProvider);
      expect(entity.cascadePreview.branches, 2);
      expect(entity.cascadePreview.branchesUnassigned, 0);
    });

    test('maps an unrecognized persona to unknown rather than crashing', () {
      final json = {
        'isEligible': true,
        'gracePeriodDays': 14,
        'blockers': <dynamic>[],
        'warnings': <dynamic>[],
        'cascadePreview': {
          'persona': 'somethingBrandNew',
          'branches': 0,
          'services': 0,
          'teamAccounts': 0,
          'invitations': 0,
          'documents': 0,
          'media': 0,
          'branchesUnassigned': 0,
        },
      };

      final entity = AccountDeletionEligibilityDto.fromJson(json).toEntity();

      expect(entity.cascadePreview.persona, DeletionPersona.unknown);
    });

    test('preserves extra cascade fields the client does not yet know', () {
      final json = {
        'isEligible': true,
        'gracePeriodDays': 14,
        'blockers': <dynamic>[],
        'warnings': <dynamic>[],
        'cascadePreview': {
          'persona': 'worker',
          'branches': 0,
          'services': 0,
          'teamAccounts': 0,
          'invitations': 0,
          'documents': 0,
          'media': 0,
          'branchesUnassigned': 0,
          'futureNewField': 7,
        },
      };

      final entity = AccountDeletionEligibilityDto.fromJson(json).toEntity();

      expect(entity.cascadePreview.extraCounts, {'futureNewField': 7});
    });

    test(
      'maps an unrecognized blocker code to unknown, preserving message',
      () {
        final json = {
          'isEligible': false,
          'gracePeriodDays': 14,
          'blockers': [
            {
              'code': 'SOME_NEW_BLOCKER_CODE',
              'message': 'Deletion is blocked for a new reason.',
            },
          ],
          'warnings': <dynamic>[],
          'cascadePreview': {
            'persona': 'worker',
            'branches': 0,
            'services': 0,
            'teamAccounts': 0,
            'invitations': 0,
            'documents': 0,
            'media': 0,
            'branchesUnassigned': 0,
          },
        };

        final entity = AccountDeletionEligibilityDto.fromJson(json).toEntity();

        final blocker = entity.blockers.single;
        expect(blocker.code, DeletionBlockerCode.unknown);
        expect(blocker.rawCode, 'SOME_NEW_BLOCKER_CODE');
        expect(blocker.message, 'Deletion is blocked for a new reason.');
      },
    );

    test('missing warnings/blockers default to empty lists', () {
      final json = {
        'isEligible': true,
        'gracePeriodDays': 14,
        'cascadePreview': {
          'persona': 'client',
          'branches': 0,
          'services': 0,
          'teamAccounts': 0,
          'invitations': 0,
          'documents': 0,
          'media': 0,
          'branchesUnassigned': 0,
        },
      };

      final entity = AccountDeletionEligibilityDto.fromJson(json).toEntity();

      expect(entity.blockers, isEmpty);
      expect(entity.warnings, isEmpty);
    });
  });
}
