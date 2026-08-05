import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
/// Compliance documents are managed via a dedicated update flow — the section
/// has no inline edit button.
class ComplianceDocumentsSection extends StatelessWidget {
  const ComplianceDocumentsSection({
    super.key,
    this.documents = const [],
  });

  final List<ComplianceDocumentEntry> documents;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_compliance'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < documents.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.md),
            AppComplianceDocumentCard(
              documentTitle: documents[i].documentTitle,
              status: documents[i].status,
              companyName: documents[i].companyName,
              licenseNumber: documents[i].licenseNumber,
              expiryDate: documents[i].expiryDate,
              countdownText: documents[i].countdownText,
              alertMessage: documents[i].alertMessage,
              onUpdateDocument: documents[i].onUpdateDocument,
            ),
          ],
        ],
      ),
    );
  }
}
