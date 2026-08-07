import 'package:contact_verification/src/di/contact_verification_di.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

/// `contact_verification` owns no screens or routes — every feature builds
/// its own `ContactVerificationVerifier` and drives it through `otp`'s
/// `OtpFlow.start`. This module exists only for `ModuleRegistry` symmetry.
class ContactVerificationModule extends FeatureModule {
  @override
  String get name => 'contact_verification';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => ContactVerificationDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
