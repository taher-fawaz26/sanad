import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Thin wrapper kept for backwards-compatibility with the invitation flow.
/// All scaffold logic lives in [AuthScreenShell] (design_system).
class InvitationScreenShell extends StatelessWidget {
  const InvitationScreenShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AuthScreenShell(child: child);
}
