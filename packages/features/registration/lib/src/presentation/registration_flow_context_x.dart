import 'package:document_flow/document_flow.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration/src/presentation/cubit/registration_details_cubit.dart';

/// Re-seeds the shared [DocumentFlowBloc]'s [DocumentFlowContext] from the
/// current [RegistrationDetailsCubit] state.
///
/// Call this after any registration-only field changes (onboarding token,
/// provider type, names) so a later upload/extract/submit call sees the
/// latest values — `document_flow` never reads `RegistrationDetailsCubit`
/// directly, so registration is responsible for keeping the two in sync.
extension RegistrationFlowContextX on BuildContext {
  void syncDocumentFlowContext() {
    final details = read<RegistrationDetailsCubit>().state;
    read<DocumentFlowBloc>().add(
      DocumentFlowStarted(context: details.toContext()),
    );
  }
}
