/// Pure view-model derivations for the general-settings page and its
/// sections.
///
/// None of these read `BuildContext`, a bloc, or a service locator — every
/// input they need (entities, the active locale, "now", UI callbacks) is
/// passed in explicitly. Keeping them free functions (not methods on a
/// `State`) makes the status/compliance/date logic unit-testable without a
/// widget harness, and keeps the page itself limited to rendering + event
/// dispatch (see `.claude/rules/state-management.md`).
library;

import 'package:branches/branches.dart'
    show BranchScheduleFormatter, BranchTimeSlotEntity;
// `easy_localization` re-exports `package:intl/intl.dart` (`DateFormat`), so
// no direct `intl` dependency is needed.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/business_profile_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/policies/working_hours_policy.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/organization_status_badge.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/business_progress_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/compliance_documents_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/working_hours_section.dart';
import 'package:shared_ui/shared_ui.dart' show ComplianceDocumentStatus;

/// Maps completion-checklist items to the section's display item.
List<BusinessProgressChecklistItem> businessProgressChecklist(
  ProviderCompletionEntity? completion,
) {
  final items = completion?.items ?? const [];
  return [
    for (final item in items)
      BusinessProgressChecklistItem(
        label: item.label,
        completed: item.completed,
      ),
  ];
}

/// The header's overall profile status.
///
/// Precedence: `expired`/`suspended` are backend-driven and always win over
/// the completion-checklist-derived states below — a provider whose profile
/// lapsed or was suspended needs to see that, not "in review".
OrganizationProfileStatus organizationHeaderStatus(
  OrganizationProfileEntity profile,
  ProviderCompletionEntity? completion,
) {
  if (profile.status == BusinessProfileStatus.expired) {
    return OrganizationProfileStatus.expired;
  }
  if (profile.status == BusinessProfileStatus.suspended) {
    return OrganizationProfileStatus.suspended;
  }
  if (profile.isReviewed) return OrganizationProfileStatus.published;
  if (completion != null && !completion.visibleToCustomers) {
    return OrganizationProfileStatus.incomplete;
  }
  if (completion == null) return OrganizationProfileStatus.incomplete;
  return OrganizationProfileStatus.inReview;
}

ComplianceDocumentStatus _legalDataStatus(LegalDataStatus status) =>
    switch (status) {
      LegalDataStatus.expired => ComplianceDocumentStatus.expired,
      LegalDataStatus.expiringSoon => ComplianceDocumentStatus.expiring,
      LegalDataStatus.verified => ComplianceDocumentStatus.verified,
    };

/// Formats an ISO date for the compliance-documents list.
///
/// `localeName` (e.g. `en_US`/`ar`) drives month-name localization — passed
/// in explicitly (from `context.locale` at the call site) rather than read
/// here, which is what keeps this function pure and correct under Arabic/RTL
/// (previously hardcoded to English month abbreviations regardless of app
/// locale).
String? formatComplianceExpiryDate(
  String? isoDate, {
  required String localeName,
}) {
  if (isoDate == null) return null;
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;
  return DateFormat('d MMM y', localeName).format(date);
}

/// Localized "expires today" / "in N days" copy for a soon-to-expire
/// document. `now` is injected rather than read via `DateTime.now()` inline
/// so the result is deterministic and testable.
String? complianceCountdownText(String? isoDate, {required DateTime now}) {
  final date = DateTime.tryParse(isoDate ?? '');
  if (date == null) return null;

  final days = date.difference(now).inDays;
  if (days <= 0) return 'settings.compliance_expires_today'.tr();
  return 'settings.compliance_expires_in_days'.tr(
    namedArgs: {'days': '$days'},
  );
}

/// Builds the compliance-documents list for [profile]. `onUpdateEmiratesId`/
/// `onUpdateTradeLicense` are the already-decided navigation callbacks — this
/// function only decides *what* to show, not how tapping "update" navigates.
List<ComplianceDocumentEntry> complianceDocumentEntries({
  required OrganizationProfileEntity profile,
  required String localeName,
  required DateTime now,
  required VoidCallback onUpdateEmiratesId,
  required VoidCallback onUpdateTradeLicense,
}) {
  final entries = <ComplianceDocumentEntry>[];

  final personal = profile.personalLegalData;
  if (personal != null) {
    entries.add(
      ComplianceDocumentEntry(
        documentTitle: 'settings.legal_documents.emirates_id'.tr(),
        status: _legalDataStatus(personal.status),
        licenseNumber: personal.idNumber,
        expiryDate: formatComplianceExpiryDate(
          personal.expiryDate,
          localeName: localeName,
        ),
        countdownText: personal.status == LegalDataStatus.expiringSoon
            ? complianceCountdownText(personal.expiryDate, now: now)
            : null,
        onUpdateDocument: onUpdateEmiratesId,
      ),
    );
  }

  final tradeLicense = profile.tradeLicenseLegalData;
  if (tradeLicense != null) {
    entries.add(
      ComplianceDocumentEntry(
        documentTitle: 'settings.legal_documents.trade_license'.tr(),
        status: _legalDataStatus(tradeLicense.status),
        licenseNumber: tradeLicense.licenseNumber,
        expiryDate: formatComplianceExpiryDate(
          tradeLicense.expiryDate,
          localeName: localeName,
        ),
        countdownText: tradeLicense.status == LegalDataStatus.expiringSoon
            ? complianceCountdownText(tradeLicense.expiryDate, now: now)
            : null,
        onUpdateDocument: onUpdateTradeLicense,
      ),
    );
  }

  return entries;
}

/// Turns backend availability into one [WorkingHoursDayGroup] per weekday,
/// with days sorted Saturday→Friday ([WorkingHoursPolicy.sortDaysCanonically])
/// and slots within each day sorted chronologically
/// ([WorkingHoursPolicy.sortSlotsChronologically]).
///
/// Empty days are dropped — the section renders nothing for a day with zero
/// slots (that would misleadingly read as "closed" rather than "unset").
/// `localeName` drives AM/PM localization (ص/م in ar, AM/PM in en) via
/// [BranchScheduleFormatter.formatSlot]'s `locale` parameter.
List<WorkingHoursDayGroup> workingHoursDayGroups(
  List<WorkingHoursDayEntity> availability, {
  required String localeName,
}) {
  final sortedDays = WorkingHoursPolicy.sortDaysCanonically(availability);
  return [
    for (final day in sortedDays)
      if (day.slots.isNotEmpty)
        WorkingHoursDayGroup(
          dayLabel: BranchScheduleFormatter.localizedDay(day.day),
          slots: [
            for (final slot in WorkingHoursPolicy.sortSlotsChronologically(
              day.slots,
            ))
              WorkingHoursSlotView(
                hoursLabel: BranchScheduleFormatter.formatSlot(
                  BranchTimeSlotEntity(from: slot.from, to: slot.to),
                  locale: localeName,
                ),
              ),
          ],
        ),
  ];
}

/// Groups the edit sheet's flat, possibly-multiple-slots-per-day entries back
/// into one [WorkingHoursDayEntity] per day (the shape the backend/bloc
/// expect) — the edit sheet allows split shifts (SAN-568), so a single day id
/// can appear more than once in [entries].
///
/// Slots within each day are sorted chronologically, and days are sorted
/// Saturday→Friday, so the persisted payload matches the intended visual
/// order (defensive — the backend does not require ordering).
List<WorkingHoursDayEntity> groupWorkingHoursEntries(
  List<WorkingHoursEditEntry> entries,
) {
  final slotsByDay = <String, List<WorkingHoursSlotEntity>>{};
  for (final entry in entries) {
    (slotsByDay[entry.dayId] ??= <WorkingHoursSlotEntity>[]).add(
      WorkingHoursSlotEntity(from: entry.from, to: entry.to),
    );
  }
  final grouped = [
    for (final MapEntry(key: day, value: slots) in slotsByDay.entries)
      WorkingHoursDayEntity(
        day: day,
        slots: WorkingHoursPolicy.sortSlotsChronologically(slots),
      ),
  ];
  return WorkingHoursPolicy.sortDaysCanonically(grouped);
}
