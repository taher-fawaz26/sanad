import 'package:asset_picker/src/di/asset_picker_config.dart';
import 'package:asset_picker/src/di/asset_picker_di.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

/// Feature-module wrapper for [AssetPickerDI].
///
/// Lets the asset picker register through the same `ModuleRegistry([...])`
/// load-order system every other package uses, instead of a bespoke imperative
/// `init` call in the app's bootstrap. It contributes no routes.
class AssetPickerModule extends FeatureModule {
  AssetPickerModule({this.config = const AssetPickerConfig()});

  final AssetPickerConfig config;

  @override
  String get name => 'asset_picker';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => AssetPickerDI.init(config: config);

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
