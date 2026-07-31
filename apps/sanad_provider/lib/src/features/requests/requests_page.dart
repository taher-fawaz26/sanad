import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Requests screen — app-specific UI shell.
class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavBar(title: 'nav.requests'.tr()),
        Expanded(
          child: Center(child: Text('nav.requests'.tr())),
        ),
      ],
    );
  }
}
