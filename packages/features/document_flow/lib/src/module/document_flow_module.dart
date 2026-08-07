import 'package:core/core.dart';
import 'package:document_flow/src/di/document_flow_di.dart';
import 'package:go_router/go_router.dart';

/// `document_flow` owns no screens or routes — every feature builds its own
/// pages around `DocumentFlowBloc`/`DocumentFlowController` and registers
/// its own routes. This module exists only for `ModuleRegistry` symmetry.
class DocumentFlowModule extends FeatureModule {
  @override
  String get name => 'document_flow';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => DocumentFlowDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
