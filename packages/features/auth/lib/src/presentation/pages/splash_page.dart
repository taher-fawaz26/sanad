import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shown during initial sign-in status check.
/// Routing decisions are delegated to the app's own router via callbacks.
class SplashPage extends StatefulWidget {
  const SplashPage({
    required this.onAuthenticated, required this.onUnauthenticated, super.key,
  });

  final VoidCallback onAuthenticated;
  final VoidCallback onUnauthenticated;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch after the first frame so the BlocProvider is guaranteed
    // reachable regardless of the widget tree mount order.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthCheckSignInStatusEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthCheckSignInStatusSuccessState) {
          widget.onAuthenticated();
        } else if (state is AuthCheckSignInStatusFailureState) {
          widget.onUnauthenticated();
        }
      },
      child: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
