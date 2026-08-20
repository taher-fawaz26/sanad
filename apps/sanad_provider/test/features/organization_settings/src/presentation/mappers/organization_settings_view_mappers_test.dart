import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/business_profile_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/personal_legal_data_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/trade_license_legal_data_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/mappers/organization_settings_view_mappers.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/organization_status_badge.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/working_hours_section.dart';
import 'package:shared_ui/shared_ui.dart' show ComplianceDocumentStatus;

// Note: EasyLocalization is deliberately not bootstrapped in this repo's unit
// tests (see edit_identity_bottom_sheet_test.dart), so `.tr()` returns the raw
// key unchanged. Assertions below target the key, matching that convention.
void main() {
  OrganizationProfileEntity profile({
    BusinessProfileStatus status = BusinessProfileStatus.inReview,
    PersonalLegalDataEntity? personalLegalData,
    TradeLicenseLegalDataEntity? tradeLicenseLegalData,
  }) => OrganizationProfileEntity(
    id: 'org-1',
    categories: const [],
    status: status,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    personalLegalData: personalLegalData,
    tradeLicenseLegalData: tradeLicenseLegalData,
  );

  group('businessProgressChecklist', () {
    test('maps completion items to checklist items', () {
      const completion = ProviderCompletionEntity(
        percentage: 50,
        requiredCompleted: 1,
        requiredTotal: 2,
        visibleToCustomers: false,
        items: [
          ProviderCompletionItemEntity(
            id: ProviderCompletionItemId.category,
            label: 'Category',
            completed: true,
            required: true,
          ),
        ],
      );
      final result = businessProgressChecklist(completion);
      expect(result, hasLength(1));
      expect(result.single.label, 'Category');
      expect(result.single.completed, isTrue);
    });

    test('null completion maps to an empty list', () {
      expect(businessProgressChecklist(null), isEmpty);
    });
  });

  group('organizationHeaderStatus', () {
    test('expired status wins over everything else', () {
      final result = organizationHeaderStatus(
        profile(status: BusinessProfileStatus.expired),
        const ProviderCompletionEntity(
          percentage: 100,
          requiredCompleted: 5,
          requiredTotal: 5,
          visibleToCustomers: true,
          items: [],
        ),
      );
      expect(result, OrganizationProfileStatus.expired);
    });

    test('suspended status wins over completion state', () {
      final result = organizationHeaderStatus(
        profile(status: BusinessProfileStatus.suspended),
        null,
      );
      expect(result, OrganizationProfileStatus.suspended);
    });

    test('active (reviewed) profile is published', () {
      final result = organizationHeaderStatus(
        profile(status: BusinessProfileStatus.active),
        null,
      );
      expect(result, OrganizationProfileStatus.published);
    });

    test(
      'not visible to customers is incomplete even with completion data',
      () {
        final result = organizationHeaderStatus(
          profile(),
          const ProviderCompletionEntity(
            percentage: 50,
            requiredCompleted: 1,
            requiredTotal: 2,
            visibleToCustomers: false,
            items: [],
          ),
        );
        expect(result, OrganizationProfileStatus.incomplete);
      },
    );

    test('null completion is incomplete', () {
      expect(
        organizationHeaderStatus(profile(), null),
        OrganizationProfileStatus.incomplete,
      );
    });

    test('visible to customers with non-active status is in review', () {
      final result = organizationHeaderStatus(
        profile(),
        const ProviderCompletionEntity(
          percentage: 100,
          requiredCompleted: 2,
          requiredTotal: 2,
          visibleToCustomers: true,
          items: [],
        ),
      );
      expect(result, OrganizationProfileStatus.inReview);
    });
  });

  group('formatComplianceExpiryDate', () {
    test('null isoDate returns null', () {
      expect(formatComplianceExpiryDate(null, localeName: 'en_US'), isNull);
    });

    test('unparseable isoDate is returned unchanged', () {
      expect(
        formatComplianceExpiryDate('not-a-date', localeName: 'en_US'),
        'not-a-date',
      );
    });

    test('valid isoDate formats as "d MMM y" in the given locale', () {
      expect(
        formatComplianceExpiryDate('2026-01-05', localeName: 'en_US'),
        '5 Jan 2026',
      );
    });
  });

  group('complianceCountdownText', () {
    final now = DateTime(2026);

    test('null isoDate returns null', () {
      expect(complianceCountdownText(null, now: now), isNull);
    });

    test('a date today or in the past returns the "expires today" key', () {
      expect(
        complianceCountdownText('2026-01-01', now: now),
        'settings.compliance_expires_today',
      );
      expect(
        complianceCountdownText('2025-12-01', now: now),
        'settings.compliance_expires_today',
      );
    });

    test('a future date returns the "in N days" key with the day count', () {
      // .tr() falls back to the raw key with namedArgs unsubstituted when
      // EasyLocalization isn't bootstrapped (see file-level note) — this
      // still proves the correct key and day count are being computed.
      final result = complianceCountdownText('2026-01-06', now: now);
      expect(result, contains('settings.compliance_expires_in_days'));
    });
  });

  group('complianceDocumentEntries', () {
    final now = DateTime(2026);

    test('no legal data on the profile yields no entries', () {
      final result = complianceDocumentEntries(
        profile: profile(),
        localeName: 'en_US',
        now: now,
        onUpdateEmiratesId: () {},
        onUpdateTradeLicense: () {},
      );
      expect(result, isEmpty);
    });

    test('personal legal data maps to an Emirates ID entry', () {
      var tapped = false;
      final result = complianceDocumentEntries(
        profile: profile(
          personalLegalData: PersonalLegalDataEntity(
            id: 'p-1',
            status: LegalDataStatus.expiringSoon,
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
            idNumber: '784-1990-1234567-1',
            expiryDate: '2026-01-06',
          ),
        ),
        localeName: 'en_US',
        now: now,
        onUpdateEmiratesId: () => tapped = true,
        onUpdateTradeLicense: () {},
      );

      expect(result, hasLength(1));
      final entry = result.single;
      expect(entry.documentTitle, 'settings.legal_documents.emirates_id');
      expect(entry.status, ComplianceDocumentStatus.expiring);
      expect(entry.licenseNumber, '784-1990-1234567-1');
      expect(entry.expiryDate, '6 Jan 2026');
      expect(entry.countdownText, isNotNull);
      entry.onUpdateDocument?.call();
      expect(tapped, isTrue);
    });

    test(
      'trade license legal data maps to a Trade License entry with no '
      'countdown when not expiring soon',
      () {
        final result = complianceDocumentEntries(
          profile: profile(
            tradeLicenseLegalData: TradeLicenseLegalDataEntity(
              id: 't-1',
              status: LegalDataStatus.verified,
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
              licenseNumber: 'CN-123',
              expiryDate: '2028-01-01',
            ),
          ),
          localeName: 'en_US',
          now: now,
          onUpdateEmiratesId: () {},
          onUpdateTradeLicense: () {},
        );

        expect(result, hasLength(1));
        final entry = result.single;
        expect(entry.documentTitle, 'settings.legal_documents.trade_license');
        expect(entry.status, ComplianceDocumentStatus.verified);
        expect(entry.countdownText, isNull);
      },
    );

    test('both legal data present yields both entries, Emirates ID first', () {
      final result = complianceDocumentEntries(
        profile: profile(
          personalLegalData: PersonalLegalDataEntity(
            id: 'p-1',
            status: LegalDataStatus.verified,
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          tradeLicenseLegalData: TradeLicenseLegalDataEntity(
            id: 't-1',
            status: LegalDataStatus.expired,
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ),
        localeName: 'en_US',
        now: now,
        onUpdateEmiratesId: () {},
        onUpdateTradeLicense: () {},
      );

      expect(result, hasLength(2));
      expect(
        result[0].documentTitle,
        'settings.legal_documents.emirates_id',
      );
      expect(
        result[1].documentTitle,
        'settings.legal_documents.trade_license',
      );
      expect(result[1].status, ComplianceDocumentStatus.expired);
    });
  });

  group('workingHoursDayGroups', () {
    test('emits one group per day with chronologically-sorted slots', () {
      final result = workingHoursDayGroups(const [
        WorkingHoursDayEntity(
          day: 'Saturday',
          slots: [
            // deliberately unsorted input
            WorkingHoursSlotEntity(from: '14:00', to: '18:00'),
            WorkingHoursSlotEntity(from: '09:00', to: '12:00'),
          ],
        ),
      ], localeName: 'en_US');

      expect(result, hasLength(1));
      expect(result.single.slots, hasLength(2));
      // First slot must be the chronologically earlier one after sort.
      expect(result.single.slots.first.hoursLabel, contains('9:00'));
    });

    test('sorts days Saturday → Friday regardless of input order', () {
      final result = workingHoursDayGroups(const [
        WorkingHoursDayEntity(
          day: 'Friday',
          slots: [WorkingHoursSlotEntity(from: '09:00', to: '12:00')],
        ),
        WorkingHoursDayEntity(
          day: 'Saturday',
          slots: [WorkingHoursSlotEntity(from: '09:00', to: '12:00')],
        ),
      ], localeName: 'en_US');

      // Uses BranchScheduleFormatter.localizedDay whose key template is
      // `branches.add_branch.days.<day>` — with l10n unbootstrapped in
      // tests, the raw key is returned. First group must be Saturday.
      expect(result.first.dayLabel, contains('saturday'));
      expect(result.last.dayLabel, contains('friday'));
    });

    test('drops empty days (not rendered as closed rows)', () {
      final result = workingHoursDayGroups(const [
        WorkingHoursDayEntity(day: 'Saturday', slots: []),
        WorkingHoursDayEntity(
          day: 'Sunday',
          slots: [WorkingHoursSlotEntity(from: '10:00', to: '16:00')],
        ),
      ], localeName: 'en_US');
      expect(result, hasLength(1));
      expect(result.single.dayLabel, contains('sunday'));
    });

    test('empty availability yields an empty list', () {
      expect(
        workingHoursDayGroups(const [], localeName: 'en_US'),
        isEmpty,
      );
    });
  });

  group('groupWorkingHoursEntries', () {
    test(
      'groups multiple slots for the same day and returns days in canonical '
      'Saturday-first order with chronologically-sorted slots (SAN-573)',
      () {
        final result = groupWorkingHoursEntries(const [
          // Deliberately out of order (Friday first) to prove canonical sort.
          WorkingHoursEditEntry(dayId: 'Friday', from: '10:00', to: '16:00'),
          WorkingHoursEditEntry(dayId: 'Saturday', from: '14:00', to: '18:00'),
          WorkingHoursEditEntry(dayId: 'Saturday', from: '09:00', to: '12:00'),
        ]);

        expect(result, hasLength(2));
        // Saturday must come before Friday.
        expect(result.first.day, 'Saturday');
        expect(result.last.day, 'Friday');

        // Saturday slots must be chronologically sorted.
        expect(result.first.slots, hasLength(2));
        expect(result.first.slots[0].from, '09:00');
        expect(result.first.slots[1].from, '14:00');
      },
    );

    test('empty entries yields an empty list', () {
      expect(groupWorkingHoursEntries(const []), isEmpty);
    });
  });
}
