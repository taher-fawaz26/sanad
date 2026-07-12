import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/src/di/otp_di.dart';

/// OTP feature module — DI registration.
///
/// The combined OTP route (verification + forgot-password flows) is composed
/// in the app router to avoid circular dependencies between otp and
/// forgot_password packages.
class OtpModule extends FeatureModule {
  @override
  String get name => 'otp';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => OtpDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
