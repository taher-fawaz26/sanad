import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ProviderMessagesPage extends StatelessWidget {
  const ProviderMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(title: 'nav.messages'.tr()),
      body: const Center(child: Text('Messages')),
    );
  }
}
