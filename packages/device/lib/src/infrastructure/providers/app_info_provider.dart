import 'package:device/src/domain/entities/app_info_data.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Wraps `package_info_plus`. No plugin type escapes this class.
class AppInfoProvider {
  const AppInfoProvider();

  Future<AppInfoData> getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfoData(
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
      installerStore: info.installerStore,
    );
  }
}
