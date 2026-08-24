import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';
import 'package:activity_logs/src/presentation/widgets/activity_log_row.dart';
import 'package:flutter/material.dart';

/// A vertical timeline of [ActivityLogRow]s. Used both for real data and
/// (wrapped in `AppSkeletonizer`) for the first-load skeleton, so the
/// skeleton is shaped exactly like the real content.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({required this.entries, super.key});

  final List<ActivityLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++)
          ActivityLogRow(
            entry: entries[i],
            showLine: i != entries.length - 1,
          ),
      ],
    );
  }
}
