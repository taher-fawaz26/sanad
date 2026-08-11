import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/src/di/otp_di.dart';

/// Registers the `otp` package with [ModuleRegistry].
///
/// Contributes no routes — verification is always invoked imperatively via
/// `OtpFlow.start`, never via a named go_router path.
class OtpModule extends FeatureModule {
  @override
  String get name => 'otp';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => OtpDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
