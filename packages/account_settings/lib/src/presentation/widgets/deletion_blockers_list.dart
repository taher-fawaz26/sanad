import 'package:account_settings/src/domain/entities/deletion_blocker.dart';
import 'package:account_settings/src/presentation/mappers/deletion_code_localizer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Renders every blocker preventing deletion. Never truncated.
class DeletionBlockersList extends StatelessWidget {
  const DeletionBlockersList({required this.blockers, super.key});

  final List<DeletionBlocker> blockers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blockers.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          AppAlert(
            message: blockers[i].localizedMessage(),
            type: AppAlertType.error,
          ),
        ],
      ],
    );
  }
}
