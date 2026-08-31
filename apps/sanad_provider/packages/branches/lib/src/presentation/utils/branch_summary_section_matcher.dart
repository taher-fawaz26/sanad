import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:core/core.dart';
import 'package:localization/localization.dart';

/// Best-effort match from a backend validation [Failure] to the
/// [BranchSummarySection] most likely responsible, by keyword-matching the
/// failure's own message text.
///
/// Never invents backend field names — only matches against text the backend
/// actually returned (`ValidationFailure.messages`, or the single resolved
/// message for other failure types). Returns `null` when nothing matches, so
/// callers fall back to the plain error snackbar with no section targeting.
BranchSummarySection? matchFailureToSection(Failure failure) {
  final messages = failure is ValidationFailure
      ? failure.localizedMessages()
      : [failure.localizedMessage()];

  for (final raw in messages) {
    final text = raw.toLowerCase();
    for (final entry in _sectionKeywords.entries) {
      if (entry.value.any(text.contains)) return entry.key;
    }
  }
  return null;
}

const _sectionKeywords = <BranchSummarySection, List<String>>{
  BranchSummarySection.workingHours: [
    'availability',
    'working hour',
    'working_hour',
    'schedule',
  ],
  BranchSummarySection.team: ['worker', 'team'],
  BranchSummarySection.services: ['service'],
  BranchSummarySection.coverage: [
    'coverage',
    'radius',
    'serving area',
    'serving_area',
  ],
  BranchSummarySection.contact: ['phone', 'manager', 'contact'],
  BranchSummarySection.branchInfo: [
    'branch name',
    'branchname',
    'branch type',
    'branchtype',
    'city',
    'locationplaceid',
    'location',
    'map pin',
  ],
};
