import 'package:device/src/domain/entities/app_info_data.dart';

/// Reads information about the running application bundle (app + package info).
///
/// Kept as an abstract contract (not a bare function) for architectural
/// consistency with the other capability services and future extensibility.
// ignore: one_member_abstracts
abstract class AppInfoService {
  /// Returns a snapshot of the running app bundle.
  Future<AppInfoData> getAppInfo();
}
