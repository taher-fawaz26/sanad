import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// The main home page for the client app.
///
/// Reference wiring for the app-wide loading architecture: content is wrapped
/// in [AppSkeletonizer] with `enabled` bound to the page's initial-load flag.
/// Real client features should bind `enabled` to their own load state (e.g.
/// `PaginationData.isLoadingFirstPage`) and never import `skeletonizer`
/// directly — the shared gateway owns the engine.
class ClientHomePage extends StatefulWidget {
  /// Creates a [ClientHomePage].
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  // Placeholder first-load flag — stands in for a real feature's load state.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulated bootstrap so the reference skeleton is visible on first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(AppDurations.pageTransition);
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppSkeletonizer(
          enabled: _isLoading,
          child: const Center(child: Text('Client Home')),
        ),
      ),
    );
  }
}
