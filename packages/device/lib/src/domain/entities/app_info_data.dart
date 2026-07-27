import 'package:equatable/equatable.dart';

/// Platform-agnostic snapshot of the running application bundle.
///
/// Covers both the "AppInfo" and "PackageInfo" capabilities from a single
/// source (`package_info_plus`) to avoid duplication.
class AppInfoData extends Equatable {
  const AppInfoData({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    this.installerStore,
  });

  /// Human-readable application name.
  final String appName;

  /// Bundle / application id (e.g. "com.sanad.client").
  final String packageName;

  /// Semantic version string (e.g. "1.4.2").
  final String version;

  /// Build number (e.g. "421").
  final String buildNumber;

  /// The store/installer that installed the app, when known
  /// (e.g. "com.android.vending", "com.apple.AppStore"). May be `null`.
  final String? installerStore;

  @override
  List<Object?> get props => [
    appName,
    packageName,
    version,
    buildNumber,
    installerStore,
  ];
}
