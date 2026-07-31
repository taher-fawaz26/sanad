import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Dark-green → black diagonal gradient shared by the full-screen scan / capture
/// / extraction steps (matches [AuthScreenShell]'s header gradient and the Figma
/// scan frames). Centralised here so the colour lives in exactly one place.
const kRegistrationGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF10412F), Colors.black],
);

/// Full-screen gradient scaffold used by the scan-flow steps that have no white
/// content card (e.g. the AI extracting step).
class RegistrationGradientScaffold extends StatelessWidget {
  const RegistrationGradientScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: kRegistrationGradient),
          child: SafeArea(child: child),
        ),
      ),
    );
  }
}
