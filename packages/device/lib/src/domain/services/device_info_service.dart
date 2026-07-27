import 'package:device/src/domain/entities/device_info_data.dart';

/// Reads static information about the physical device.
///
/// Kept as an abstract contract (not a bare function) for architectural
/// consistency with the other capability services and future extensibility.
// ignore: one_member_abstracts
abstract class DeviceInfoService {
  /// Returns a snapshot of the current device.
  Future<DeviceInfoData> getDeviceInfo();
}
