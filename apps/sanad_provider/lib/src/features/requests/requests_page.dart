import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Provider requests tab — lists incoming service requests.
class ProviderRequestsPage extends StatelessWidget {
  const ProviderRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('nav.requests'.tr())),
      body: const Center(child: Text('Requests')),
    );
  }
}
