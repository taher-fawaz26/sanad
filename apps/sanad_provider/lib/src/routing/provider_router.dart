import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sanad_provider/src/features/home/home_page.dart';

/// sanad_provider top-level router, independent from sanad_client.
GoRouter buildProviderRouter() {
  return GoRouter(
    initialLocation: AuthRoutes.splash,
    routes: [
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AuthRoutes.splash,
            builder: (context, state) => SplashPage(
              onAuthenticated: () => context.go(_providerHome),
              onUnauthenticated: () => context.go(AuthRoutes.login),
            ),
          ),
          GoRoute(
            path: AuthRoutes.login,
            builder: (context, state) => LoginPage(
              onAuthenticated: () => context.go(_providerHome),
            ),
          ),
        ],
      ),
      GoRoute(
        path: _providerHome,
        builder: (context, state) => const ProviderHomePage(),
      ),
    ],
  );
}

const _providerHome = '/home';
