import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// A single compliance document entry rendered as [AppComplianceDocumentCard].
class ComplianceDocumentEntry {
  const ComplianceDocumentEntry({
    required this.documentTitle,
    required this.status,
    this.companyName,
    this.licenseNumber,
    this.expiryDate,
    this.countdownText,
    this.alertMessage,
    this.onUpdateDocument,
  });

  final String documentTitle;
  final ComplianceDocumentStatus status;
  final String? companyName;
  final String? licenseNumber;
  final String? expiryDate;
  final String? countdownText;
  final String? alertMessage;
  final VoidCallback? onUpdateDocument;
}

/// View-mode section listing organization compliance documents.
///
/// Compliance documents are managed via a dedicated update flow — the
/// section header has no edit action.
class ComplianceDocumentsSection extends StatelessWidget {
  const ComplianceDocumentsSection({
    super.key,
    this.documents = const [],
  });

  final List<ComplianceDocumentEntry> documents;

  @override
  Widget build(BuildContext context) {
    final labels = ComplianceDocumentCardLabels(
      companyName: 'settings.legal_documents.compliance_card.company_name_label'
          .tr(),
      licenseNumber:
          'settings.legal_documents.compliance_card.license_number_label'.tr(),
      updateDocument:
          'settings.legal_documents.compliance_card.update_document_action'
              .tr(),
      expiryDate: 'settings.legal_documents.compliance_card.expiry_date_label'
          .tr(),
      underReviewSince:
          'settings.legal_documents.compliance_card.under_review_since_label'
              .tr(),
      rejectedOn: 'settings.legal_documents.compliance_card.rejected_on_label'
          .tr(),
      expiredOn: 'settings.legal_documents.compliance_card.expired_on_label'
          .tr(),
      expiringSoon:
          'settings.legal_documents.compliance_card.status_expiring_soon'.tr(),
      expired: 'settings.legal_documents.compliance_card.status_expired'.tr(),
      underReview:
          'settings.legal_documents.compliance_card.status_under_review'.tr(),
      rejected: 'settings.legal_documents.compliance_card.status_rejected'.tr(),
      alertExpiring: 'settings.legal_documents.compliance_card.alert_expiring'
          .tr(),
      alertExpired: 'settings.legal_documents.compliance_card.alert_expired'
          .tr(),
      alertUnderReview:
          'settings.legal_documents.compliance_card.alert_under_review'.tr(),
      alertRejected: 'settings.legal_documents.compliance_card.alert_rejected'
          .tr(),
    );

    return AppSectionCard(
      title: 'settings.section_compliance'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < documents.length; index++) ...[
            if (index > 0) SizedBox(height: AppSpacing.md),
            AppComplianceDocumentCard(
              documentTitle: documents[index].documentTitle,
              status: documents[index].status,
              labels: labels,
              companyName: documents[index].companyName,
              licenseNumber: documents[index].licenseNumber,
              expiryDate: documents[index].expiryDate,
              countdownText: documents[index].countdownText,
              alertMessage: documents[index].alertMessage,
              onUpdateDocument: documents[index].onUpdateDocument,
            ),
          ],
        ],
      ),
    );
  }
}
