import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

const _labels = ComplianceDocumentCardLabels(
  companyName: 'اسم الشركة',
  licenseNumber: 'رقم الرخصة',
  updateDocument: 'تحديث المستند',
  expiryDate: 'تاريخ الانتهاء',
  underReviewSince: 'قيد المراجعة منذ',
  rejectedOn: 'تم الرفض في',
  expiredOn: 'انتهت الصلاحية في',
  expiringSoon: 'قريبة الانتهاء',
  expired: 'منتهية الصلاحية',
  underReview: 'قيد المراجعة',
  rejected: 'مرفوضة',
  alertExpiring: 'تنبيه انتهاء',
  alertExpired: 'تنبيه انتهاء الصلاحية',
  alertUnderReview: 'تنبيه المراجعة',
  alertRejected: 'تنبيه الرفض',
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('AppComplianceDocumentCard', () {
    testWidgets(
      'renders every fixed label from the supplied labels bundle, never '
      'hardcoded English — this is the SAN-565 regression: the card used to '
      'hardcode "Company Name", "License No.", "Update Document", status '
      'badge text, and the alert body regardless of the selected locale',
      (tester) async {
        await _pump(
          tester,
          AppComplianceDocumentCard(
            documentTitle: 'الرخصة التجارية',
            status: ComplianceDocumentStatus.expiring,
            labels: _labels,
            companyName: 'شركة تجريبية',
            licenseNumber: 'TL-1',
            expiryDate: '15 مايو 2026',
            onUpdateDocument: () {},
          ),
        );

        expect(find.text(_labels.companyName), findsOneWidget);
        expect(find.text(_labels.licenseNumber), findsOneWidget);
        expect(find.text(_labels.updateDocument), findsOneWidget);
        expect(find.text(_labels.expiringSoon), findsOneWidget);
        expect(find.text(_labels.alertExpiring), findsOneWidget);

        expect(find.text('Company Name'), findsNothing);
        expect(find.text('License No.'), findsNothing);
        expect(find.text('Update Document'), findsNothing);
        expect(find.text('Expiring Soon'), findsNothing);
      },
    );

    testWidgets('expired status shows the localized "expired on" prefix', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppComplianceDocumentCard(
          documentTitle: 'الهوية الإماراتية',
          status: ComplianceDocumentStatus.expired,
          labels: _labels,
          expiryDate: '1 يناير 2026',
        ),
      );

      expect(
        find.text('${_labels.expiredOn} 1 يناير 2026'),
        findsOneWidget,
      );
      expect(find.textContaining('Expired on'), findsNothing);
    });

    testWidgets(
      'underReview status uses the localized "under review since" label',
      (tester) async {
        await _pump(
          tester,
          const AppComplianceDocumentCard(
            documentTitle: 'الرخصة التجارية',
            status: ComplianceDocumentStatus.underReview,
            labels: _labels,
          ),
        );

        expect(find.text(_labels.underReviewSince), findsOneWidget);
        expect(find.text(_labels.underReview), findsOneWidget);
        expect(find.text(_labels.alertUnderReview), findsOneWidget);
        expect(find.text('Under review since'), findsNothing);
      },
    );

    testWidgets(
      'a null expiryDate never collapses to an empty value next to the '
      '"expired on" label — the backend allows any stored date to be '
      'unreadable, so this must show a placeholder, not nothing',
      (tester) async {
        await _pump(
          tester,
          const AppComplianceDocumentCard(
            documentTitle: 'الهوية الإماراتية',
            status: ComplianceDocumentStatus.expired,
            labels: _labels,
          ),
        );

        expect(find.text('${_labels.expiredOn} —'), findsOneWidget);
      },
    );

    testWidgets(
      'a null expiryDate on a verified document shows a placeholder instead '
      'of an empty value',
      (tester) async {
        await _pump(
          tester,
          const AppComplianceDocumentCard(
            documentTitle: 'الهوية الإماراتية',
            status: ComplianceDocumentStatus.verified,
            labels: _labels,
          ),
        );

        expect(find.text('—'), findsOneWidget);
      },
    );
  });
}
