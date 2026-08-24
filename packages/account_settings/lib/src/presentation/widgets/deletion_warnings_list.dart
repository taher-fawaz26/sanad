import 'package:account_settings/src/domain/entities/deletion_warning.dart';
import 'package:account_settings/src/presentation/mappers/deletion_code_localizer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Renders every non-blocking warning the account should confirm before
/// deleting. Never truncated.
class DeletionWarningsList extends StatelessWidget {
  const DeletionWarningsList({required this.warnings, super.key});

  final List<DeletionWarning> warnings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < warnings.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          AppAlert(
            message: warnings[i].localizedMessage(),
            type: AppAlertType.warning,
          ),
        ],
      ],
    );
  }
}
