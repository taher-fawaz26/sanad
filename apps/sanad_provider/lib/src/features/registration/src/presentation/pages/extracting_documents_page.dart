import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_extracting_view.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// Step 8 — "AI extracting document information" loading step.
///
/// Figma: `AI` (`3125:24217`). Runs the (simulated) extraction on entry and
/// replaces itself with the Review Information screen when it completes.
class ExtractingDocumentsPage extends HookWidget {
  const ExtractingDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      context.read<DocumentFlowBloc>().add(const ExtractionRequested());
      return null;
    }, const []);

    return BlocConsumer<DocumentFlowBloc, DocumentFlowState>(
      listenWhen: (prev, curr) => prev.phase != curr.phase,
      listener: (context, state) {
        if (state.phase is PhaseExtracted) {
          context.pushReplacement(RegistrationRoutes.reviewInformation);
        }
      },
      builder: (context, state) {
        if (state.phase is PhaseFailure &&
            (state.phase as PhaseFailure).stage == FailedStage.extraction) {
          final failure = state.failure;
          final extractionFailure = failure is ExtractionFailure
              ? failure
              : null;
          final kind = extractionFailure?.kind ?? ExtractionFailureKind.server;

          // `messageKey` is overloaded: for network/server/missing-context it
          // is an i18n key (resolve with `.tr()`); for a domain rejection it
          // is the backend's already-localized, user-facing message, which
          // must be shown verbatim (running it through `.tr()` logs a spurious
          // "key not found" warning and is semantically wrong).
          final (AppErrorStateStyle style, String description) = switch (kind) {
            ExtractionFailureKind.network => (
              AppErrorStateStyle.network,
              'registration.extraction_failed_retry'.tr(),
            ),
            ExtractionFailureKind.domain
                when (extractionFailure?.messageKey.isNotEmpty ?? false) =>
              (AppErrorStateStyle.generic, extractionFailure!.messageKey),
            _ => (
              AppErrorStateStyle.generic,
              (extractionFailure?.messageKey ??
                      'registration.extraction_failed_retry')
                  .tr(),
            ),
          };

          return Scaffold(
            body: AppErrorState(
              style: style,
              title: 'registration.extraction_failed_title'.tr(),
              description: description,
              retryLabel: 'common.retry'.tr(),
              onRetry: () =>
                  context.read<DocumentFlowBloc>().add(const RetryRequested()),
            ),
          );
        }

        return const RegistrationExtractingView();
      },
    );
  }
}
