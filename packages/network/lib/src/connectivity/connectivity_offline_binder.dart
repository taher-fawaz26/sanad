import 'package:flutter/widgets.dart';
import 'package:network/src/connectivity/connectivity_controller.dart';

/// Listens to [ConnectivityController] and invokes callbacks when the
/// connection drops or returns — apps wire these to push/pop the offline route.
class ConnectivityOfflineBinder extends StatefulWidget {
  const ConnectivityOfflineBinder({
    required this.controller,
    required this.onWentOffline,
    required this.onWentOnline,
    required this.child,
    super.key,
  });

  final ConnectivityController controller;
  final VoidCallback onWentOffline;
  final VoidCallback onWentOnline;
  final Widget child;

  @override
  State<ConnectivityOfflineBinder> createState() =>
      _ConnectivityOfflineBinderState();
}

class _ConnectivityOfflineBinderState extends State<ConnectivityOfflineBinder> {
  late bool _wasConnected;

  @override
  void initState() {
    super.initState();
    _wasConnected = widget.controller.isConnected;
    widget.controller.addListener(_onConnectivityChanged);
    // If we start offline after init completes, surface the offline screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.isInitialized && !widget.controller.isConnected) {
        widget.onWentOffline();
      }
    });
  }

  @override
  void didUpdateWidget(ConnectivityOfflineBinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onConnectivityChanged);
      _wasConnected = widget.controller.isConnected;
      widget.controller.addListener(_onConnectivityChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    final isConnected = widget.controller.isConnected;
    if (!_wasConnected && isConnected) {
      widget.onWentOnline();
    } else if (_wasConnected && !isConnected) {
      widget.onWentOffline();
    }
    _wasConnected = isConnected;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
