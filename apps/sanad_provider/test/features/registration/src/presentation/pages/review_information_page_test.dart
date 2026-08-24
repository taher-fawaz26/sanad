import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/pages/review_information_page.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_extracting_view.dart';

/// SAN-575 regression coverage for the review screen:
///  - a domain-rejection banner renders resolved field labels, never the raw
///    backend identifiers (e.g. `full_name_english`) the message embeds.
///  - re-extraction (`PhaseExtracting`, entered while replacing a document)
///    renders the same mounted extraction visual as the first extraction,
///    never the bare, background-less loader that painted as a black screen.
///
/// A mocked bloc is used throughout (per `testing.md`): these tests only
/// need to render given states, not drive the real bloc's async behavior.
/// EasyLocalization is intentionally not initialized — `.tr()` falls back to
/// the raw key, so assertions target i18n keys, not display copy.
class _MockDocumentFlowBloc
    extends MockBloc<DocumentFlowEvent, DocumentFlowState>
    implements DocumentFlowBloc {}

const _config = DocumentFlowConfig(
  requiredDocuments: [
    DocumentType.emiratesIdFront,
    DocumentType.emiratesIdBack,
  ],
);

void main() {
  late _MockDocumentFlowBloc bloc;

  setUp(() {
    bloc = _MockDocumentFlowBloc();
  });

  Future<void> pumpPage(WidgetTester tester, DocumentFlowState state) async {
    // The page is a full phone-sized screen; the default flutter_test
    // surface (800x600) is too short and triggers spurious overflow errors
    // unrelated to the behavior under test. Width is generous (not just
    // phone-width) because EasyLocalization is intentionally uninitialized
    // here, so header/badge labels render as their full raw i18n keys —
    // much longer than real translated copy — which would otherwise
    // overflow a realistic phone width.
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(bloc, Stream.value(state), initialState: state);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(900, 1200),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider<DocumentFlowBloc>.value(
            value: bloc,
            child: const ReviewInformationPage(homeRoute: '/home'),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'a domain rejection with resolved missing fields never shows the raw '
    'backend field identifier',
    (tester) async {
      const state = DocumentFlowState(
        config: _config,
        phase: PhaseExtracted(),
        extracted: ExtractedDocuments(
          sections: [
            ExtractedDocument(
              type: DocumentType.emiratesIdFront,
              fields: [],
              issue: DocumentIssue.imageUnclear,
              issueDetail:
                  'لم نتمكن من قراءة الحقول: full_name_english, id_number.',
              missingFields: ['full_name_english', 'id_number'],
            ),
          ],
        ),
      );

      await pumpPage(tester, state);
      await tester.pump();

      // The raw backend rejection sentence (which embeds the raw field
      // identifiers verbatim) is never shown — missingFields takes priority.
      expect(
        find.text(
          'لم نتمكن من قراءة الحقول: full_name_english, id_number.',
        ),
        findsNothing,
      );
      // The missing-fields banner (not the raw issueDetail sentence) is used
      // when missingFields is non-empty.
      expect(
        find.text('registration.missing_fields_message'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a domain rejection with no attributable fields falls back to the raw '
    'issueDetail sentence',
    (tester) async {
      const detail = 'الوجه الأمامي والخلفي للهوية الإماراتية لا يتطابقان.';
      const state = DocumentFlowState(
        config: _config,
        phase: PhaseExtracted(),
        extracted: ExtractedDocuments(
          sections: [
            ExtractedDocument(
              type: DocumentType.emiratesIdFront,
              fields: [],
              issue: DocumentIssue.imageUnclear,
              issueDetail: detail,
            ),
          ],
        ),
      );

      await pumpPage(tester, state);
      await tester.pump();

      expect(find.text(detail), findsOneWidget);
      expect(
        find.text('registration.missing_fields_message'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'PhaseExtracting (re-extraction while replacing) renders the mounted '
    'extraction visual, never a bare unscaffolded loader',
    (tester) async {
      const state = DocumentFlowState(
        config: _config,
        phase: PhaseExtracting(),
        extracted: ExtractedDocuments(
          sections: [
            ExtractedDocument(type: DocumentType.emiratesIdFront, fields: []),
          ],
        ),
      );

      await pumpPage(tester, state);
      await tester.pump();

      expect(find.byType(RegistrationExtractingView), findsOneWidget);
    },
  );
}
